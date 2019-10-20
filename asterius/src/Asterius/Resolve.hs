{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE StrictData #-}

module Asterius.Resolve
  ( unresolvedGlobalRegType,
    LinkReport (..),
    linkStart,
  )
where

import Asterius.Builtins
import Asterius.Internals.MagicNumber
import Asterius.JSFFI
import Asterius.MemoryTrap
import Asterius.Passes.DataSymbolTable
import Asterius.Passes.FunctionSymbolTable
import Asterius.Types
import Data.Binary
import qualified Data.ByteString as BS
import qualified Data.ByteString.Short as SBS
import Data.Data
  ( Data,
    gmapQl,
  )
import qualified Data.Map.Lazy as LM
import qualified Data.Set as S
import Data.String
import Foreign
import GHC.Generics
import Language.Haskell.GHC.Toolkit.Constants
import Type.Reflection
  ( (:~~:) (..),
    TypeRep,
    eqTypeRep,
    typeOf,
    typeRep,
  )
import Unsafe.Coerce
import Prelude hiding (IO)

unresolvedGlobalRegType :: UnresolvedGlobalReg -> ValueType
unresolvedGlobalRegType gr = case gr of
  FloatReg _ -> F32
  DoubleReg _ -> F64
  _ -> I64

collectAsteriusEntitySymbols ::
  Data a => a -> S.Set AsteriusEntitySymbol -> S.Set AsteriusEntitySymbol
collectAsteriusEntitySymbols t acc =
  case eqTypeRep (typeOf t) (typeRep :: TypeRep AsteriusEntitySymbol) of
    Just HRefl -> S.insert t acc
    _ -> gmapQl (.) id collectAsteriusEntitySymbols t acc

data LinkReport
  = LinkReport
      { staticsSymbolMap, functionSymbolMap :: LM.Map AsteriusEntitySymbol Int64,
        infoTableSet :: [Int64],
        tableSlots, staticMBlocks :: Int,
        bundledFFIMarshalState :: FFIMarshalState
      }
  deriving (Generic, Show)

instance Binary LinkReport

instance Semigroup LinkReport where
  r0 <> r1 = LinkReport
    { staticsSymbolMap = staticsSymbolMap r0 <> staticsSymbolMap r1,
      functionSymbolMap = functionSymbolMap r0 <> functionSymbolMap r1,
      infoTableSet = infoTableSet r0 <> infoTableSet r1,
      tableSlots = 0,
      staticMBlocks = 0,
      bundledFFIMarshalState =
        bundledFFIMarshalState r0
          <> bundledFFIMarshalState r1
    }

instance Monoid LinkReport where
  mempty = LinkReport
    { staticsSymbolMap = mempty,
      functionSymbolMap = mempty,
      infoTableSet = mempty,
      tableSlots = 0,
      staticMBlocks = 0,
      bundledFFIMarshalState = mempty
    }

mergeSymbols ::
  Bool ->
  Bool ->
  Bool ->
  AsteriusModule ->
  S.Set AsteriusEntitySymbol ->
  [AsteriusEntitySymbol] ->
  (AsteriusModule, LinkReport)
mergeSymbols _ gc_sections verbose_err store_mod root_syms export_funcs
  | not gc_sections = (store_mod, mempty {bundledFFIMarshalState = ffi_all})
  | otherwise = (final_m, mempty {bundledFFIMarshalState = ffi_this})
  where
    ffi_all = ffiMarshalState store_mod
    ffi_this =
      ffi_all
        { ffiImportDecls = flip LM.filterWithKey (ffiImportDecls ffi_all) $ \k _ ->
            (k <> "_wrapper") `LM.member` functionMap final_m,
          ffiExportDecls = ffi_exports
        }
    ffi_exports
      | not gc_sections = ffiExportDecls (ffiMarshalState store_mod)
      | otherwise =
        ffiExportDecls (ffiMarshalState store_mod)
          `LM.restrictKeys` S.fromList export_funcs
    root_syms' =
      S.fromList [ffiExportClosure | FFIExportDecl {..} <- LM.elems ffi_exports]
        <> root_syms
    (_, _, final_m) = go (root_syms', S.empty, mempty)
    go i@(i_staging_syms, _, _)
      | S.null i_staging_syms = i
      | otherwise = go $ iter i
    iter (i_staging_syms, i_acc_syms, i_m) = (o_staging_syms, o_acc_syms, o_m)
      where
        o_acc_syms = i_staging_syms <> i_acc_syms
        (i_child_syms, o_m) =
          S.foldr'
            ( \i_staging_sym (i_child_syms_acc, o_m_acc) ->
                case LM.lookup i_staging_sym (staticsMap store_mod) of
                  Just ss ->
                    ( collectAsteriusEntitySymbols ss i_child_syms_acc,
                      o_m_acc
                        { staticsMap = LM.insert i_staging_sym ss (staticsMap o_m_acc)
                        }
                    )
                  _ -> case LM.lookup i_staging_sym (functionMap store_mod) of
                    Just func ->
                      ( collectAsteriusEntitySymbols func i_child_syms_acc,
                        o_m_acc
                          { functionMap =
                              LM.insert
                                i_staging_sym
                                func
                                (functionMap o_m_acc)
                          }
                      )
                    _
                      | verbose_err ->
                        ( i_child_syms_acc,
                          o_m_acc
                            { staticsMap =
                                LM.insert
                                  ("__asterius_barf_" <> i_staging_sym)
                                  AsteriusStatics
                                    { staticsType = ConstBytes,
                                      asteriusStatics =
                                        [ Serialized $
                                            entityName i_staging_sym
                                              <> ( case LM.lookup
                                                     i_staging_sym
                                                     (staticsErrorMap store_mod) of
                                                     Just err -> fromString (": " <> show err)
                                                     _ -> mempty
                                                 )
                                              <> "\0"
                                        ]
                                    }
                                  (staticsMap o_m_acc)
                            }
                        )
                      | otherwise ->
                        (i_child_syms_acc, o_m_acc)
            )
            (S.empty, i_m)
            i_staging_syms
        o_staging_syms = i_child_syms `S.difference` o_acc_syms

makeInfoTableSet ::
  AsteriusModule -> LM.Map AsteriusEntitySymbol Int64 -> [Int64]
makeInfoTableSet AsteriusModule {..} sym_map =
  LM.elems $ LM.restrictKeys sym_map $ LM.keysSet $
    LM.filter
      ((== InfoTable) . staticsType)
      staticsMap

resolveAsteriusModule ::
  Bool ->
  Bool ->
  FFIMarshalState ->
  AsteriusModule ->
  Int64 ->
  Int64 ->
  ( Module,
    LM.Map AsteriusEntitySymbol Int64,
    LM.Map AsteriusEntitySymbol Int64,
    Int,
    Int
  )
resolveAsteriusModule debug _ bundled_ffi_state m_globals_resolved func_start_addr data_start_addr =
  (new_mod, ss_sym_map, func_sym_map, table_slots, initial_mblocks)
  where
    (func_sym_map, last_func_addr) =
      makeFunctionSymbolTable m_globals_resolved func_start_addr
    table_slots = fromIntegral $ last_func_addr .&. 0xFFFFFFFF
    func_table = makeFunctionTable func_sym_map func_start_addr
    (ss_sym_map, last_data_addr) =
      makeDataSymbolTable m_globals_resolved data_start_addr
    all_sym_map = func_sym_map <> ss_sym_map
    func_imports =
      rtsFunctionImports debug <> generateFFIFunctionImports bundled_ffi_state
    new_function_map = unsafeCoerce $ functionMap m_globals_resolved
    (initial_pages, segs) =
      makeMemory m_globals_resolved all_sym_map last_data_addr
    initial_mblocks =
      fromIntegral initial_pages `quot` (mblock_size `quot` wasmPageSize)
    new_mod = Module
      { functionMap' = new_function_map,
        functionImports = func_imports,
        functionExports =
          filter
            ( \FunctionExport {internalName = e} ->
                e
                  `LM.member` new_function_map
                  || any
                    ( \FunctionImport {internalName = i} ->
                        i == e
                    )
                    func_imports
            )
            $ rtsFunctionExports debug,
        functionTable = func_table,
        tableImport = TableImport
          { externalModuleName = "WasmTable",
            externalBaseName = "table"
          },
        tableExport = TableExport {externalName = "table"},
        tableSlots = table_slots,
        memorySegments = segs,
        memoryImport = MemoryImport
          { externalModuleName = "WasmMemory",
            externalBaseName = "memory"
          },
        memoryExport = MemoryExport {externalName = "memory"},
        memoryMBlocks = initial_mblocks
      }

linkStart ::
  Bool ->
  Bool ->
  Bool ->
  Bool ->
  AsteriusModule ->
  S.Set AsteriusEntitySymbol ->
  [AsteriusEntitySymbol] ->
  (AsteriusModule, Module, LinkReport)
linkStart debug gc_sections binaryen verbose_err store root_syms export_funcs =
  ( merged_m,
    result_m,
    report
      { staticsSymbolMap = ss_sym_map,
        functionSymbolMap = func_sym_map,
        infoTableSet = makeInfoTableSet merged_m ss_sym_map,
        Asterius.Resolve.tableSlots = tbl_slots,
        staticMBlocks = static_mbs
      }
  )
  where
    (merged_m0, !report) =
      mergeSymbols debug gc_sections verbose_err store root_syms export_funcs
    merged_m1
      | debug = addMemoryTrap merged_m0
      | otherwise = merged_m0
    !merged_m
      | verbose_err = merged_m1
      | otherwise =
        merged_m1
          { staticsMap =
              LM.filterWithKey
                ( \sym _ ->
                    not
                      ( "__asterius_barf_"
                          `BS.isPrefixOf` SBS.fromShort (entityName sym)
                      )
                )
                $ staticsMap merged_m1
          }
    (!result_m, !ss_sym_map, !func_sym_map, !tbl_slots, !static_mbs) =
      resolveAsteriusModule
        debug
        binaryen
        (bundledFFIMarshalState report)
        merged_m
        (1 .|. functionTag `shiftL` 32)
        (dataTag `shiftL` 32)
