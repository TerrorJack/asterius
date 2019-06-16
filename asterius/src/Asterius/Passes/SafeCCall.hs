{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE StrictData #-}

module Asterius.Passes.SafeCCall
  ( SafeCCall(..)
  , BlockChunk(..)
  , splitBlockBody
  , genContext
  ) where

import Asterius.Internals
import Asterius.Passes.GlobalRegs
import Asterius.Types
import qualified Data.ByteString as BS
import qualified Data.ByteString.Short as SBS
import Data.Foldable
import Data.List
import Language.Haskell.GHC.Toolkit.Constants

data SafeCCall =
  SafeCCall AsteriusEntitySymbol
            FFIImportDecl
            Expression

data BlockChunk =
  BlockChunk [Expression]
             (Maybe SafeCCall)

splitBlockBody :: FFIMarshalState -> Expression -> [BlockChunk]
splitBlockBody FFIMarshalState {..} instrs = foldr' w [] es
  where
    get_safe t =
      case AsteriusEntitySymbol . SBS.toShort <$>
           BS.stripSuffix "_wrapper" (SBS.fromShort (entityName t)) of
        Just k
          | ffiSafety imp_decl /= FFIUnsafe -> Just (k, imp_decl)
          where imp_decl = ffiImportDecls ! k
        _ -> Nothing
    add_regular instr (BlockChunk es' mcc:cs) =
      BlockChunk (instr : es') mcc : cs
    add_regular instr [] = [BlockChunk [instr] Nothing]
    add_ccall k imp_decl instr cs =
      BlockChunk [] (Just (SafeCCall k imp_decl instr)) : cs
    w instr@Call {..} cs =
      case get_safe target of
        Just (k, imp_decl) -> add_ccall k imp_decl instr cs
        _ -> add_regular instr cs
    w instr@SetLocal {value = Call {..}} cs =
      case get_safe target of
        Just (k, imp_decl) -> add_ccall k imp_decl instr cs
        _ -> add_regular instr cs
    w instr cs = add_regular instr cs
    es =
      case instrs of
        Block {..} -> bodys
        Nop -> []
        _ -> [instrs]

genContext :: [ValueType] -> Expression -> ([Expression], [Expression])
genContext vts e =
  case e of
    Call {} -> (save_instrs <> [e], load_instrs)
      where I32:I32:I32:ctx_regs = vts
            (save_instrs, load_instrs) =
              gen_save_load $ zip [2 ..] (I32 : ctx_regs)
    SetLocal {value = e'@Call {}, ..} -> (save_instrs <> [e'], load_instrs)
      where (I32:I32:I32:ctx_regs_x, _:ctx_regs_y) = genericSplitAt index vts
            ctx_regs =
              zip [2 ..] (I32 : ctx_regs_x) <> zip [succ index ..] ctx_regs_y
            (save_instrs, load_instrs) = gen_save_load ctx_regs
    _ -> error "Asterius.Passes.SafeCCall.genContext"
  where
    gen_save_load ctx_regs =
      ( [ Store
          { bytes = bs vt
          , offset = 0
          , ptr = pos p
          , value = GetLocal {index = i, valueType = vt}
          , valueType = vt
          }
        | (p, (i, vt)) <- p_ctx_regs
        ] <>
        [ CallImport
            { target' = "__asterius_setTSOregs"
            , operands = [tid]
            , callImportReturnTypes = []
            }
        ]
      , CallImport
          { target' = "__asterius_getTSOregs"
          , operands = [tid]
          , callImportReturnTypes = []
          } :
        [ SetLocal
          { index = i
          , value =
              Load
                { signed = False
                , bytes = bs vt
                , offset = 0
                , valueType = vt
                , ptr = pos p
                }
          }
        | (p, (i, vt)) <- p_ctx_regs
        ])
      where
        tid =
          Load
            { signed = False
            , bytes = 4
            , offset = 0
            , valueType = I32
            , ptr =
                Unary
                  { unaryOp = WrapInt64
                  , operand0 =
                      Binary
                        { binaryOp = AddInt64
                        , operand0 = unresolvedGetGlobal CurrentTSO
                        , operand1 = ConstI64 $ fromIntegral offset_StgTSO_id
                        }
                  }
            }
        p_ctx_regs = zip [0,8 ..] ctx_regs
        pos p = Symbol {unresolvedSymbol = "__asterius_regs", symbolOffset = p}
        bs vt =
          case vt of
            I32 -> 4
            F32 -> 4
            _ -> 8
