{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE StrictData #-}
{-# OPTIONS_GHC -Wno-overflowed-literals #-}

module Asterius.Builtins
  ( BuiltinsOptions(..)
  , defaultBuiltinsOptions
  , rtsAsteriusModuleSymbol
  , rtsAsteriusModule
  , rtsFunctionImports
  , rtsFunctionExports
  , emitErrorMessage
  , wasmPageSize
  , generateWrapperFunction
  ) where

import Asterius.EDSL
import Asterius.Internals
import Asterius.Internals.MagicNumber
import Asterius.Types
import qualified Data.ByteString.Short as SBS
import Data.Foldable
import Data.Functor
import Data.List
import qualified Data.Map.Strict as Map
import Data.Maybe
import qualified GhcPlugins as GHC
import Language.Haskell.GHC.Toolkit.Constants
import Prelude hiding (IO)
import Debug.Trace

wasmPageSize :: Int
wasmPageSize = 65536

data BuiltinsOptions = BuiltinsOptions
  { threadStateSize :: Int
  , debug, hasMain :: Bool
  }

defaultBuiltinsOptions :: BuiltinsOptions
defaultBuiltinsOptions =
  BuiltinsOptions {threadStateSize = 65536, debug = False, hasMain = True}

rtsAsteriusModuleSymbol :: AsteriusModuleSymbol
rtsAsteriusModuleSymbol =
  AsteriusModuleSymbol
    { unitId = SBS.toShort $ GHC.fs_bs $ GHC.unitIdFS GHC.rtsUnitId
    , moduleName = ["Asterius"]
    }

rtsAsteriusModule :: BuiltinsOptions -> AsteriusModule
rtsAsteriusModule opts =
  mempty
    { staticsMap =
        Map.fromList
          [ ( "MainCapability"
            , AsteriusStatics
                { staticsType = Bytes
                , asteriusStatics =
                    [ Serialized $
                      SBS.pack $
                      replicate (8 * roundup_bytes_to_words sizeof_Capability) 0
                    ]
                })
          , ( "__asterius_pc"
            , AsteriusStatics
                { staticsType = Bytes
                , asteriusStatics = [Serialized $ encodeStorable invalidAddress]
                })
          , ("__asterius_i32_slot"
            , AsteriusStatics
              { staticsType=Bytes
              , asteriusStatics = [Serialized $ SBS.pack $ replicate (roundup_bytes_to_words 4) 0]
              })

          , ("__asterius_i64_slot"
            , AsteriusStatics
              { staticsType=Bytes
              , asteriusStatics = [Serialized $ SBS.pack $ replicate (roundup_bytes_to_words 8) 0]
              })
          ]
    , functionMap =
        Map.fromList $
        (if debug opts
           then [ ("__asterius_Load_Sp", getF64GlobalRegFunction opts Sp)
                , ("__asterius_Load_SpLim", getF64GlobalRegFunction opts SpLim)
                , ("__asterius_Load_Hp", getF64GlobalRegFunction opts Hp)
                , ("__asterius_Load_HpLim", getF64GlobalRegFunction opts HpLim)
                , ("__asterius_trap_load_i8", trapLoadI8Function opts)
                , ("__asterius_trap_store_i8", trapStoreI8Function opts)
                , ("__asterius_trap_load_i16", trapLoadI16Function opts)
                , ("__asterius_trap_store_i16", trapStoreI16Function opts)
                , ("__asterius_trap_load_i32", trapLoadI32Function opts)
                , ("__asterius_trap_store_i32", trapStoreI32Function opts)
                , ("__asterius_trap_load_i64", trapLoadI64Function opts)
                , ("__asterius_trap_store_i64", trapStoreI64Function opts)
                , ("__asterius_trap_load_f32", trapLoadF32Function opts)
                , ("__asterius_trap_store_f32", trapStoreF32Function opts)
                , ("__asterius_trap_load_f64", trapLoadF64Function opts)
                , ("__asterius_trap_store_f64", trapStoreF64Function opts)
                ]
           else []) <>
        [ ("main", mainFunction opts)
        , ("hs_init", hsInitFunction opts)
        , ("rts_apply", rtsApplyFunction opts)
        , ( "rts_apply_wrapper"
          , generateWrapperFunction "rts_apply" $ rtsApplyFunction opts)
        , ("rts_eval", rtsEvalFunction opts)
        , ( "rts_eval_wrapper"
          , generateWrapperFunction "rts_eval" $ rtsEvalFunction opts)
        , ("rts_evalIO", rtsEvalIOFunction opts)
        , ( "rts_evalIO_wrapper"
          , generateWrapperFunction "rts_evalIO" $ rtsEvalIOFunction opts)
        , ("rts_evalLazyIO", rtsEvalLazyIOFunction opts)
        , ( "rts_evalLazyIO_wrapper"
          , generateWrapperFunction "rts_evalLazyIO" $
            rtsEvalLazyIOFunction opts)
        , ("rts_getSchedStatus", rtsGetSchedStatusFunction opts)
        , ( "rts_getSchedStatus_wrapper"
          , generateWrapperFunction "rts_getSchedStatus" $
            rtsGetSchedStatusFunction opts)
        , ("rts_checkSchedStatus", rtsCheckSchedStatusFunction opts)
        , ( "rts_checkSchedStatus_wrapper"
          , generateWrapperFunction "rts_checkSchedStatus" $
            rtsCheckSchedStatusFunction opts)
        , ("scheduleWaitThread", scheduleWaitThreadFunction opts)
        , ("createThread", createThreadFunction opts)
        , ("createGenThread", createGenThreadFunction opts)
        , ("createIOThread", createIOThreadFunction opts)
        , ("createStrictIOThread", createStrictIOThreadFunction opts)
        , ("allocate", allocateFunction opts)
        , ("allocateMightFail", allocateFunction opts)
        , ("allocatePinned", allocatePinnedFunction opts)
        , ("newCAF", newCAFFunction opts)
        , ("StgReturn", stgReturnFunction opts)
        , ("getStablePtr", getStablePtrWrapperFunction opts)
        , ( "getStablePtr_wrapper"
          , generateWrapperFunction "getStablePtr" $
            getStablePtrWrapperFunction opts)
        , ("deRefStablePtr", deRefStablePtrWrapperFunction opts)
        , ( "deRefStablePtr_wrapper"
          , generateWrapperFunction "deRefStablePtr" $
            deRefStablePtrWrapperFunction opts)
        , ("hs_free_stable_ptr", freeStablePtrWrapperFunction opts)
        , ( "hs_free_stable_ptr_wrapper"
          , generateWrapperFunction "hs_free_stable_ptr" $
            freeStablePtrWrapperFunction opts)
        , ("rts_mkBool", rtsMkBoolFunction opts)
        , ( "rts_mkBool_wrapper"
          , generateWrapperFunction "rts_mkBool" $ rtsMkBoolFunction opts)
        , ("rts_mkDouble", rtsMkDoubleFunction opts)
        , ( "rts_mkDouble_wrapper"
          , generateWrapperFunction "rts_mkDouble" $ rtsMkDoubleFunction opts)
        , ("rts_mkChar", rtsMkCharFunction opts)
        , ( "rts_mkChar_wrapper"
          , generateWrapperFunction "rts_mkChar" $ rtsMkCharFunction opts)
        , ("rts_mkInt", rtsMkIntFunction opts)
        , ( "rts_mkInt_wrapper"
          , generateWrapperFunction "rts_mkInt" $ rtsMkIntFunction opts)
        , ("rts_mkWord", rtsMkWordFunction opts)
        , ( "rts_mkWord_wrapper"
          , generateWrapperFunction "rts_mkWord" $ rtsMkWordFunction opts)
        , ("rts_mkPtr", rtsMkPtrFunction opts)
        , ( "rts_mkPtr_wrapper"
          , generateWrapperFunction "rts_mkPtr" $ rtsMkPtrFunction opts)
        , ("rts_mkStablePtr", rtsMkStablePtrFunction opts)
        , ( "rts_mkStablePtr_wrapper"
          , generateWrapperFunction "rts_mkStablePtr" $
            rtsMkStablePtrFunction opts)
        , ("rts_getBool", rtsGetBoolFunction opts)
        , ( "rts_getBool_wrapper"
          , generateWrapperFunction "rts_getBool" $ rtsGetBoolFunction opts)
        , ("rts_getDouble", rtsGetDoubleFunction opts)
        , ( "rts_getDouble_wrapper"
          , generateWrapperFunction "rts_getDouble" $ rtsGetDoubleFunction opts)
        , ("rts_getChar", rtsGetCharFunction opts)
        , ( "rts_getChar_wrapper"
          , generateWrapperFunction "rts_getChar" $ rtsGetCharFunction opts)
        , ("rts_getInt", rtsGetIntFunction opts)
        , ( "rts_getInt_wrapper"
          , generateWrapperFunction "rts_getInt" $ rtsGetIntFunction opts)
        , ("rts_getWord", rtsGetIntFunction opts)
        , ( "rts_getWord_wrapper"
          , generateWrapperFunction "rts_getWord" $ rtsGetIntFunction opts)
        , ("rts_getPtr", rtsGetIntFunction opts)
        , ( "rts_getPtr_wrapper"
          , generateWrapperFunction "rts_getPtr" $ rtsGetIntFunction opts)
        , ("rts_getStablePtr", rtsGetIntFunction opts)
        , ( "rts_getStablePtr_wrapper"
          , generateWrapperFunction "rts_getStablePtr" $ rtsGetIntFunction opts)
        , ("loadI64", loadI64Function opts)
        , ( "loadI64_wrapper"
          , generateWrapperFunction "loadI64" $ loadI64Function opts)
        , ("print_i64", printI64Function opts)
        , ("print_f32", printF32Function opts)
        , ("print_f64", printF64Function opts)
        , ("assert_eq_i64", assertEqI64Function opts)
        , ("wrapI64ToI8", wrapI64ToI8 opts)
        , ("wrapI32ToI8", wrapI32ToI8 opts)
        , ("wrapI64ToI16", wrapI64ToI16 opts)
        , ("wrapI32ToI16", wrapI32ToI16 opts)
        -- sext
        , ("extendI8ToI64Sext", extendI8ToI64Sext opts)
        , ("extendI16ToI64Sext", extendI16ToI64Sext opts)
        , ("extendI8ToI32Sext", extendI8ToI32Sext opts)
        , ("extendI16ToI32Sext", extendI16ToI32Sext opts)
        -- no SEXT
        , ("extendI8ToI64", extendI8ToI64 opts)
        , ("extendI16ToI64", extendI16ToI64 opts)
        , ("extendI8ToI32", extendI8ToI32 opts)
        , ("extendI16ToI32", extendI16ToI32 opts)
        , ("strlen", strlenFunction opts)
        , ("memchr", memchrFunction opts)
        , ("memcpy", memcpyFunction opts)
        , ("memset", memsetFunction opts)
        , ("memcmp", memcmpFunction opts)
        , ("__asterius_fromJSArrayBuffer", fromJSArrayBufferFunction opts)
        , ("__asterius_toJSArrayBuffer", toJSArrayBufferFunction opts)
        , ("__asterius_fromJSString", fromJSStringFunction opts)
        , ("__asterius_fromJSArray", fromJSArrayFunction opts)
        , ("threadPaused", threadPausedFunction opts)
        , ("dirty_MUT_VAR", dirtyMutVarFunction opts)
        ] <>
        map (\(func_sym, (_, func)) -> (func_sym, func)) byteStringCBits
    }

rtsFunctionImports :: Bool -> [FunctionImport]
rtsFunctionImports debug =
  [ FunctionImport
    { internalName = "__asterius_" <> op <> "_" <> showSBS ft
    , externalModuleName = "Math"
    , externalBaseName = op
    , functionType = FunctionType {paramTypes = [ft], returnTypes = [ft]}
    }
  | ft <- [F32, F64]
  , op <-
      [ "sin"
      , "cos"
      , "tan"
      , "sinh"
      , "cosh"
      , "tanh"
      , "asin"
      , "acos"
      , "atan"
      , "log"
      , "exp"
      ]
  ] <>
  [ FunctionImport
    { internalName = "__asterius_" <> op <> "_" <> showSBS ft
    , externalModuleName = "Math"
    , externalBaseName = op
    , functionType = FunctionType {paramTypes = [ft, ft], returnTypes = [ft]}
    }
  | ft <- [F32, F64]
  , op <- ["pow"]
  ] <>
  [ FunctionImport
      { internalName = "__asterius_newStablePtr"
      , externalModuleName = "StablePtr"
      , externalBaseName = "newStablePtr"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = [F64]}
      }
  , FunctionImport
      { internalName = "__asterius_deRefStablePtr"
      , externalModuleName = "StablePtr"
      , externalBaseName = "deRefStablePtr"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = [F64]}
      }
  , FunctionImport
      { internalName = "__asterius_freeStablePtr"
      , externalModuleName = "StablePtr"
      , externalBaseName = "freeStablePtr"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = []}
      }
  , FunctionImport
      { internalName = "printI64"
      , externalModuleName = "rts"
      , externalBaseName = "printI64"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = []}
      }
  , FunctionImport
      { internalName = "assertEqI64"
      , externalModuleName = "rts"
      , externalBaseName = "assertEqI64"
      , functionType = FunctionType {paramTypes = [F64, F64], returnTypes = []}
      }
  , FunctionImport
      { internalName = "printF32"
      , externalModuleName = "rts"
      , externalBaseName = "print"
      , functionType = FunctionType {paramTypes = [F32], returnTypes = []}
      }
  , FunctionImport
      { internalName = "printF64"
      , externalModuleName = "rts"
      , externalBaseName = "print"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = []}
      }
  , FunctionImport
      { internalName = "__asterius_eventI32"
      , externalModuleName = "rts"
      , externalBaseName = "emitEvent"
      , functionType = FunctionType {paramTypes = [I32], returnTypes = []}
      }
  , FunctionImport
      { internalName = "__asterius_newTSO"
      , externalModuleName = "TSO"
      , externalBaseName = "newTSO"
      , functionType = FunctionType {paramTypes = [], returnTypes = [I32]}
      }
  , FunctionImport
      { internalName = "__asterius_setTSOret"
      , externalModuleName = "TSO"
      , externalBaseName = "setTSOret"
      , functionType = FunctionType {paramTypes = [I32, F64], returnTypes = []}
      }
  , FunctionImport
      { internalName = "__asterius_setTSOrstat"
      , externalModuleName = "TSO"
      , externalBaseName = "setTSOrstat"
      , functionType = FunctionType {paramTypes = [I32, I32], returnTypes = []}
      }
  , FunctionImport
      { internalName = "__asterius_getTSOret"
      , externalModuleName = "TSO"
      , externalBaseName = "getTSOret"
      , functionType = FunctionType {paramTypes = [I32], returnTypes = [F64]}
      }
  , FunctionImport
      { internalName = "__asterius_getTSOrstat"
      , externalModuleName = "TSO"
      , externalBaseName = "getTSOrstat"
      , functionType = FunctionType {paramTypes = [I32], returnTypes = [I32]}
      }
  , FunctionImport
      { internalName = "__asterius_hpAlloc"
      , externalModuleName = "HeapAlloc"
      , externalBaseName = "hpAlloc"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = [F64]}
      }
  , FunctionImport
      { internalName = "__asterius_allocate"
      , externalModuleName = "HeapAlloc"
      , externalBaseName = "allocate"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = [F64]}
      }
  , FunctionImport
      { internalName = "__asterius_allocatePinned"
      , externalModuleName = "HeapAlloc"
      , externalBaseName = "allocatePinned"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = [F64]}
      }
  , FunctionImport
      { internalName = "__asterius_strlen"
      , externalModuleName = "Memory"
      , externalBaseName = "strlen"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = [F64]}
      }
  , FunctionImport
      { internalName = "__asterius_memchr"
      , externalModuleName = "Memory"
      , externalBaseName = "memchr"
      , functionType =
          FunctionType {paramTypes = [F64, F64, F64], returnTypes = [F64]}
      }
  , FunctionImport
      { internalName = "__asterius_memcpy"
      , externalModuleName = "Memory"
      , externalBaseName = "memcpy"
      , functionType =
          FunctionType {paramTypes = [F64, F64, F64], returnTypes = []}
      }
  , FunctionImport
      { internalName = "__asterius_memmove"
      , externalModuleName = "Memory"
      , externalBaseName = "memmove"
      , functionType =
          FunctionType {paramTypes = [F64, F64, F64], returnTypes = []}
      }
  , FunctionImport
      { internalName = "__asterius_memset"
      , externalModuleName = "Memory"
      , externalBaseName = "memset"
      , functionType =
          FunctionType {paramTypes = [F64, F64, F64], returnTypes = []}
      }
  , FunctionImport
      { internalName = "__asterius_memcmp"
      , externalModuleName = "Memory"
      , externalBaseName = "memcmp"
      , functionType =
          FunctionType {paramTypes = [F64, F64, F64], returnTypes = [I32]}
      }
  , FunctionImport
      { internalName = "__asterius_fromJSArrayBuffer_imp"
      , externalModuleName = "HeapBuilder"
      , externalBaseName = "fromJSArrayBuffer"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = [F64]}
      }
  , FunctionImport
      { internalName = "__asterius_toJSArrayBuffer_imp"
      , externalModuleName = "HeapBuilder"
      , externalBaseName = "toJSArrayBuffer"
      , functionType =
          FunctionType {paramTypes = [F64, F64], returnTypes = [F64]}
      }
  , FunctionImport
      { internalName = "__asterius_fromJSString_imp"
      , externalModuleName = "HeapBuilder"
      , externalBaseName = "fromJSString"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = [F64]}
      }
  , FunctionImport
      { internalName = "__asterius_fromJSArray_imp"
      , externalModuleName = "HeapBuilder"
      , externalBaseName = "fromJSArray"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = [F64]}
      }
  , FunctionImport
      { internalName = "__asterius_gcRootTSO"
      , externalModuleName = "GC"
      , externalBaseName = "gcRootTSO"
      , functionType = FunctionType {paramTypes = [F64], returnTypes = []}
      }
  ] <>
  (if debug
     then [ FunctionImport
              { internalName = "__asterius_traceCmm"
              , externalModuleName = "Tracing"
              , externalBaseName = "traceCmm"
              , functionType =
                  FunctionType {paramTypes = [F64], returnTypes = []}
              }
          , FunctionImport
              { internalName = "__asterius_traceCmmBlock"
              , externalModuleName = "Tracing"
              , externalBaseName = "traceCmmBlock"
              , functionType =
                  FunctionType {paramTypes = [F64, I32], returnTypes = []}
              }
          , FunctionImport
              { internalName = "__asterius_traceCmmSetLocal"
              , externalModuleName = "Tracing"
              , externalBaseName = "traceCmmSetLocal"
              , functionType =
                  FunctionType {paramTypes = [F64, I32, F64], returnTypes = []}
              }
          , FunctionImport
              { internalName = "__asterius_load_I64"
              , externalModuleName = "MemoryTrap"
              , externalBaseName = "loadI64"
              , functionType =
                  FunctionType
                    {paramTypes = [F64, I32, I32, I32], returnTypes = []}
              }
          , FunctionImport
              { internalName = "__asterius_store_I64"
              , externalModuleName = "MemoryTrap"
              , externalBaseName = "storeI64"
              , functionType =
                  FunctionType
                    {paramTypes = [F64, I32, I32, I32], returnTypes = []}
              }
          ] <>
          concat
            [ [ FunctionImport
                  { internalName = "__asterius_load_" <> k
                  , externalModuleName = "MemoryTrap"
                  , externalBaseName = "load" <> k
                  , functionType =
                      FunctionType
                        {paramTypes = [F64, I32, t], returnTypes = []}
                  }
              , FunctionImport
                  { internalName = "__asterius_store_" <> k
                  , externalModuleName = "MemoryTrap"
                  , externalBaseName = "store" <> k
                  , functionType =
                      FunctionType
                        {paramTypes = [F64, I32, t], returnTypes = []}
                  }
            ]
            | (k, t) <-
                [ ("I8", I32)
                , ("I16", I32)
                , ("I32", I32)
                , ("F32", F32)
                , ("F64", F64)
                ]
            ]
     else []) <>
  map (fst . snd) byteStringCBits

rtsFunctionExports :: Bool -> Bool -> [FunctionExport]
rtsFunctionExports debug has_main =
  [ FunctionExport {internalName = f <> "_wrapper", externalName = f}
  | f <-
      [ "loadI64"
      , "rts_mkBool"
      , "rts_mkDouble"
      , "rts_mkChar"
      , "rts_mkInt"
      , "rts_mkWord"
      , "rts_mkPtr"
      , "rts_mkStablePtr"
      , "rts_getBool"
      , "rts_getDouble"
      , "rts_getChar"
      , "rts_getInt"
      , "rts_getWord"
      , "rts_getPtr"
      , "rts_getStablePtr"
      , "rts_apply"
      , "rts_eval"
      , "rts_evalIO"
      , "rts_evalLazyIO"
      , "rts_getSchedStatus"
      , "rts_checkSchedStatus"
      , "getStablePtr"
      , "deRefStablePtr"
      , "hs_free_stable_ptr"
      ]
  ] <>
  [ FunctionExport {internalName = "__asterius_" <> f, externalName = f}
  | f <- ["getTSOret", "getTSOrstat"]
  ] <>
  [ FunctionExport {internalName = f, externalName = f}
  | f <-
      (if debug
         then [ "__asterius_Load_Sp"
              , "__asterius_Load_SpLim"
              , "__asterius_Load_Hp"
              , "__asterius_Load_HpLim"
              ]
         else []) <>
      ["hs_init"] <>
      ["main" | has_main]
  ]

emitErrorMessage :: [ValueType] -> Event -> Expression
emitErrorMessage vts ev =
  Block
    { name = ""
    , bodys =
        [ CallImport
            { target' = "__asterius_eventI32"
            , operands = [ConstI32 $ fromIntegral $ fromEnum ev]
            , callImportReturnTypes = []
            }
        , Unreachable
        ]
    , blockReturnTypes = vts
    }

byteStringCBits :: [(AsteriusEntitySymbol, (FunctionImport, Function))]
byteStringCBits =
  map
    (\(func_sym, param_vts, ret_vts) ->
       ( AsteriusEntitySymbol func_sym
       , generateRTSWrapper "bytestring" func_sym param_vts ret_vts))
    [ ("fps_reverse", [I64, I64, I64], [])
    , ("fps_intersperse", [I64, I64, I64, I64], [])
    , ("fps_maximum", [I64, I64], [I64])
    , ("fps_minimum", [I64, I64], [I64])
    , ("fps_count", [I64, I64, I64], [I64])
    , ("fps_memcpy_offsets", [I64, I64, I64, I64, I64], [I64])
    , ("_hs_bytestring_int_dec", [I64, I64], [I64])
    , ("_hs_bytestring_long_long_int_dec", [I64, I64], [I64])
    , ("_hs_bytestring_uint_dec", [I64, I64], [I64])
    , ("_hs_bytestring_long_long_uint_dec", [I64, I64], [I64])
    , ("_hs_bytestring_int_dec_padded9", [I64, I64], [])
    , ("_hs_bytestring_long_long_int_dec_padded18", [I64, I64], [])
    , ("_hs_bytestring_uint_hex", [I64, I64], [I64])
    , ("_hs_bytestring_long_long_uint_hex", [I64, I64], [I64])
    ]

generateRTSWrapper ::
     SBS.ShortByteString
  -> SBS.ShortByteString
  -> [ValueType]
  -> [ValueType]
  -> (FunctionImport, Function)
generateRTSWrapper mod_sym func_sym param_vts ret_vts =
  ( FunctionImport
      { internalName = "__asterius_" <> func_sym
      , externalModuleName = mod_sym
      , externalBaseName = func_sym
      , functionType =
          FunctionType {paramTypes = map fst xs, returnTypes = fst ret}
      }
  , Function
      { functionType =
          FunctionType {paramTypes = param_vts, returnTypes = ret_vts}
      , varTypes = []
      , body =
          snd
            ret
            CallImport
              { target' = "__asterius_" <> func_sym
              , operands = map snd xs
              , callImportReturnTypes = fst ret
              }
      })
  where
    xs =
      zipWith
        (\i vt ->
           case vt of
             I64 ->
               ( F64
               , convertSInt64ToFloat64 GetLocal {index = i, valueType = I64})
             _ -> (vt, GetLocal {index = i, valueType = vt}))
        [0 ..]
        param_vts
    ret =
      case ret_vts of
        [I64] -> ([F64], truncUFloat64ToInt64)
        _ -> (ret_vts, id)

generateWrapperFunction :: AsteriusEntitySymbol -> Function -> Function
generateWrapperFunction func_sym Function {functionType = FunctionType {..}} =
  Function
    { functionType =
        FunctionType
          { paramTypes =
              [ wrapper_param_type
              | (_, wrapper_param_type, _) <- wrapper_param_types
              ]
          , returnTypes = wrapper_return_types
          }
    , varTypes = []
    , body =
        to_wrapper_return_types $
        Call
          { target = func_sym
          , operands =
              [ from_wrapper_param_type
                GetLocal {index = i, valueType = wrapper_param_type}
              | (i, wrapper_param_type, from_wrapper_param_type) <-
                  wrapper_param_types
              ]
          , callReturnTypes = returnTypes
          }
    }
  where
    wrapper_param_types =
      [ case param_type of
        I64 -> (i, F64, truncSFloat64ToInt64)
        _ -> (i, param_type, id)
      | (i, param_type) <- zip [0 ..] paramTypes
      ]
    (wrapper_return_types, to_wrapper_return_types) =
      case returnTypes of
        [I64] -> ([F64], convertSInt64ToFloat64)
        _ -> (returnTypes, id)

mainFunction, hsInitFunction, rtsApplyFunction, rtsEvalFunction, rtsEvalIOFunction, rtsEvalLazyIOFunction, rtsGetSchedStatusFunction, rtsCheckSchedStatusFunction, scheduleWaitThreadFunction, createThreadFunction, createGenThreadFunction, createIOThreadFunction, createStrictIOThreadFunction, allocateFunction, allocatePinnedFunction, newCAFFunction, stgReturnFunction, getStablePtrWrapperFunction, deRefStablePtrWrapperFunction, freeStablePtrWrapperFunction, rtsMkBoolFunction, rtsMkDoubleFunction, rtsMkCharFunction, rtsMkIntFunction, rtsMkWordFunction, rtsMkPtrFunction, rtsMkStablePtrFunction, rtsGetBoolFunction, rtsGetDoubleFunction, rtsGetCharFunction, rtsGetIntFunction, loadI64Function, printI64Function, assertEqI64Function, printF32Function, printF64Function, strlenFunction, memchrFunction, memcpyFunction, memsetFunction, memcmpFunction, fromJSArrayBufferFunction, toJSArrayBufferFunction, fromJSStringFunction, fromJSArrayFunction, threadPausedFunction, dirtyMutVarFunction, trapLoadI8Function, trapStoreI8Function, trapLoadI16Function, trapStoreI16Function, trapLoadI32Function, trapStoreI32Function, trapLoadI64Function, trapStoreI64Function, trapLoadF32Function, trapStoreF32Function, trapLoadF64Function, trapStoreF64Function, wrapI64ToI8, wrapI32ToI8, wrapI64ToI16, wrapI32ToI16, extendI8ToI64 ::
     BuiltinsOptions -> Function
mainFunction BuiltinsOptions {} =
  runEDSL [] $ do
    tid <- call' "rts_evalLazyIO" [symbol "Main_main_closure"] I32
    call "rts_checkSchedStatus" [tid]

initCapability :: EDSL ()
initCapability = do
  storeI32 mainCapability offset_Capability_no $ constI32 0
  storeI32 mainCapability offset_Capability_node $ constI32 0
  storeI8 mainCapability offset_Capability_in_haskell $ constI32 0
  storeI32 mainCapability offset_Capability_idle $ constI32 0
  storeI8 mainCapability offset_Capability_disabled $ constI32 0
  storeI64 mainCapability offset_Capability_total_allocated $ constI64 0
  storeI64
    mainCapability
    (offset_Capability_f + offset_StgFunTable_stgEagerBlackholeInfo) $
    symbol "__stg_EAGER_BLACKHOLE_info"
  storeI64 mainCapability (offset_Capability_f + offset_StgFunTable_stgGCEnter1) $
    symbol "__stg_gc_enter_1"
  storeI64 mainCapability (offset_Capability_f + offset_StgFunTable_stgGCFun) $
    symbol "__stg_gc_fun"
  storeI64 mainCapability offset_Capability_weak_ptr_list_hd $ constI64 0
  storeI64 mainCapability offset_Capability_weak_ptr_list_tl $ constI64 0
  storeI32 mainCapability offset_Capability_context_switch $ constI32 0
  storeI64 mainCapability (offset_Capability_r + offset_StgRegTable_rCCCS) $
    constI64 0
  storeI64 mainCapability (offset_Capability_r + offset_StgRegTable_rCurrentTSO) $
    constI64 0

hsInitFunction _ =
  runEDSL [] $ do
    initCapability
    bd_nursery <-
      truncUFloat64ToInt64 <$> callImport' "__asterius_hpAlloc" [constF64 8] F64
    putLVal currentNursery bd_nursery

rtsEvalHelper :: BuiltinsOptions -> AsteriusEntitySymbol -> EDSL ()
rtsEvalHelper BuiltinsOptions {..} create_thread_func_sym = do
  setReturnTypes [I32]
  p <- param I64
  tso <-
    call'
      create_thread_func_sym
      [mainCapability, constI64 $ roundup_bytes_to_words threadStateSize, p]
      I64
  call "scheduleWaitThread" [tso]
  emit $ loadI32 tso offset_StgTSO_id

rtsApplyFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [f, arg] <- params [I64, I64]
    ap <-
      call'
        "allocate"
        [mainCapability, constI64 $ roundup_bytes_to_words sizeof_StgThunk + 2]
        I64
    storeI64 ap 0 $ symbol "stg_ap_2_upd_info"
    storeI64 ap offset_StgThunk_payload f
    storeI64 ap (offset_StgThunk_payload + 8) arg
    emit ap

rtsEvalFunction opts = runEDSL [I32] $ rtsEvalHelper opts "createGenThread"

rtsEvalIOFunction opts =
  runEDSL [I32] $ rtsEvalHelper opts "createStrictIOThread"

rtsEvalLazyIOFunction opts = runEDSL [I32] $ rtsEvalHelper opts "createIOThread"

rtsGetSchedStatusFunction _ =
  runEDSL [I32] $ do
    setReturnTypes [I32]
    tid <- param I32
    callImport' "__asterius_getTSOrstat" [tid] I32 >>= emit

rtsCheckSchedStatusFunction _ =
  runEDSL [] $ do
    tid <- param I32
    stat <- call' "rts_getSchedStatus" [tid] I32
    if' [] (stat `eqInt32` constI32 scheduler_Success) mempty $
      emit $ emitErrorMessage [] IllegalSchedulerStatusCode

dirtyTSO :: Expression -> Expression -> EDSL ()
dirtyTSO _ tso =
  if'
    []
    (eqZInt32 $ loadI32 tso offset_StgTSO_dirty)
    (storeI32 tso offset_StgTSO_dirty $ constI32 1)
    mempty

dirtySTACK :: Expression -> Expression -> EDSL ()
dirtySTACK _ stack =
  if'
    []
    (eqZInt32 $ loadI32 stack offset_StgStack_dirty)
    (storeI32 stack offset_StgStack_dirty $ constI32 1)
    mempty

scheduleWaitThreadFunction BuiltinsOptions {} =
  runEDSL [] $ do
    t <- param I64
    block' [] $ \sched_block_lbl ->
      loop' [] $ \sched_loop_lbl -> do
        if'
          []
          (loadI8 mainCapability offset_Capability_in_haskell)
          (emit (emitErrorMessage [] SchedulerReenteredFromHaskell))
          mempty
        storeI64
          mainCapability
          (offset_Capability_r + offset_StgRegTable_rCurrentTSO)
          t
        storeI32 mainCapability offset_Capability_interrupt $ constI32 0
        storeI8 mainCapability offset_Capability_in_haskell $ constI32 1
        storeI32 mainCapability offset_Capability_idle $ constI32 0
        dirtyTSO mainCapability t
        dirtySTACK mainCapability (loadI64 t offset_StgTSO_stackobj)
        r <- stgRun $ symbol "stg_returnToStackTop"
        ret <- i64Local $ loadI64 r offset_StgRegTable_rRet
        storeI8 mainCapability offset_Capability_in_haskell $ constI32 0
        switchI64 ret $
          const
            ( [ ( ret_HeapOverflow
                , do callImport
                       "__asterius_gcRootTSO"
                       [convertUInt64ToFloat64 t]
                     bytes <- i64Local $ getLVal hpAlloc
                     putLVal hpAlloc $ constI64 0
                     if'
                       []
                       (eqZInt64 bytes)
                       (emit $ emitErrorMessage [] HeapOverflowWithZeroHpAlloc)
                       mempty
                     truncUFloat64ToInt64 <$>
                       callImport'
                         "__asterius_hpAlloc"
                         [convertUInt64ToFloat64 bytes]
                         F64 >>=
                       putLVal currentNursery
                     break' sched_loop_lbl Nothing)
              , (ret_StackOverflow, emit $ emitErrorMessage [] StackOverflow)
              , (ret_ThreadYielding, break' sched_loop_lbl Nothing)
              , (ret_ThreadBlocked, emit $ emitErrorMessage [] ThreadBlocked)
              , ( ret_ThreadFinished
                , if'
                    []
                    (loadI16 t offset_StgTSO_what_next `eqInt32`
                     constI32 next_ThreadComplete)
                    (do callImport
                          "__asterius_setTSOret"
                          [ loadI32 t offset_StgTSO_id
                          , convertUInt64ToFloat64 $
                            loadI64
                              (loadI64
                                 (loadI64 t offset_StgTSO_stackobj)
                                 offset_StgStack_sp)
                              8
                          ]
                        callImport
                          "__asterius_setTSOrstat"
                          [ loadI32 t offset_StgTSO_id
                          , constI32 scheduler_Success
                          ]
                        break' sched_block_lbl Nothing)
                    (do callImport
                          "__asterius_setTSOret"
                          [loadI32 t offset_StgTSO_id, ConstF64 0]
                        callImport
                          "__asterius_setTSOrstat"
                          [ loadI32 t offset_StgTSO_id
                          , constI32 scheduler_Killed
                          ]
                        break' sched_block_lbl Nothing))
              ]
            , emit $ emitErrorMessage [] IllegalThreadReturnCode)
    callImport "__asterius_gcRootTSO" [convertUInt64ToFloat64 t]

createThreadFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [cap, alloc_words] <- params [I64, I64]
    tso_p <- call' "allocatePinned" [cap, alloc_words] I64
    stack_p <- i64Local $ tso_p `addInt64` constI64 offset_StgTSO_StgStack
    storeI64 stack_p 0 $ symbol "stg_STACK_info"
    stack_size_w <-
      i64Local $
      alloc_words `subInt64`
      constI64 ((offset_StgTSO_StgStack + offset_StgStack_stack) `div` 8)
    storeI32 stack_p offset_StgStack_stack_size $ wrapInt64 stack_size_w
    storeI64 stack_p offset_StgStack_sp $
      (stack_p `addInt64` constI64 offset_StgStack_stack) `addInt64`
      (stack_size_w `mulInt64` constI64 8)
    storeI32 stack_p offset_StgStack_dirty $ constI32 1
    storeI64 tso_p 0 $ symbol "stg_TSO_info"
    storeI16 tso_p offset_StgTSO_what_next $ constI32 next_ThreadRunGHC
    storeI16 tso_p offset_StgTSO_why_blocked $ constI32 blocked_NotBlocked
    storeI32 tso_p offset_StgTSO_flags $ constI32 0
    storeI32 tso_p offset_StgTSO_dirty $ constI32 1
    storeI32 tso_p offset_StgTSO_saved_errno $ constI32 0
    storeI64 tso_p offset_StgTSO_cap cap
    storeI64 tso_p offset_StgTSO_stackobj stack_p
    storeI32 tso_p offset_StgTSO_tot_stack_size $ wrapInt64 stack_size_w
    storeI64 tso_p offset_StgTSO_alloc_limit (constI64 0)
    storeI64 stack_p offset_StgStack_sp $
      loadI64 stack_p offset_StgStack_sp `subInt64`
      constI64 (8 * roundup_bytes_to_words sizeof_StgStopFrame)
    storeI64 (loadI64 stack_p offset_StgStack_sp) 0 $
      symbol "stg_stop_thread_info"
    callImport' "__asterius_newTSO" [] I32 >>= storeI32 tso_p offset_StgTSO_id
    emit tso_p

pushClosure :: Expression -> Expression -> EDSL ()
pushClosure tso c = do
  stack_p <- i64Local $ loadI64 tso offset_StgTSO_stackobj
  storeI64 stack_p offset_StgStack_sp $
    loadI64 stack_p offset_StgStack_sp `subInt64` constI64 8
  storeI64 (loadI64 stack_p offset_StgStack_sp) 0 c

createThreadHelper :: (Expression -> [Expression]) -> EDSL ()
createThreadHelper mk_closures = do
  setReturnTypes [I64]
  [cap, stack_size, closure] <- params [I64, I64, I64]
  t <- call' "createThread" [cap, stack_size] I64
  for_ (mk_closures closure) $ pushClosure t
  emit t

createGenThreadFunction _ =
  runEDSL [I64] $
  createThreadHelper $ \closure -> [closure, symbol "stg_enter_info"]

createIOThreadFunction _ =
  runEDSL [I64] $
  createThreadHelper $ \closure ->
    [symbol "stg_ap_v_info", closure, symbol "stg_enter_info"]

createStrictIOThreadFunction _ =
  runEDSL [I64] $
  createThreadHelper $ \closure ->
    [ symbol "stg_forceIO_info"
    , symbol "stg_ap_v_info"
    , closure
    , symbol "stg_enter_info"
    ]

allocateFunction BuiltinsOptions {} =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [_, n] <- params [I64, I64]
    (truncUFloat64ToInt64 <$>
     callImport' "__asterius_allocate" [convertUInt64ToFloat64 n] F64) >>=
      emit

allocatePinnedFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [_, n] <- params [I64, I64]
    (truncUFloat64ToInt64 <$>
     callImport' "__asterius_allocatePinned" [convertUInt64ToFloat64 n] F64) >>=
      emit

newCAFFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [reg, caf] <- params [I64, I64]
    orig_info <- i64Local $ loadI64 caf 0
    storeI64 caf offset_StgIndStatic_saved_info orig_info
    bh <-
      call'
        "allocate"
        [mainCapability, constI64 $ roundup_bytes_to_words sizeof_StgInd]
        I64
    storeI64 bh 0 $ symbol "stg_CAF_BLACKHOLE_info"
    storeI64 bh offset_StgInd_indirectee $
      loadI64 reg offset_StgRegTable_rCurrentTSO
    storeI64 caf offset_StgIndStatic_indirectee bh
    storeI64 caf 0 $ symbol "stg_IND_STATIC_info"
    emit bh

stgRun :: Expression -> EDSL Expression
stgRun init_f = do
  let pc = pointerI64 (symbol "__asterius_pc") 0
  pc_reg <- i64MutLocal
  putLVal pc init_f
  loop' [] $ \loop_lbl -> do
    putLVal pc_reg $ getLVal pc
    if' [] (eqZInt64 (getLVal pc_reg)) mempty $ do
      callIndirect (getLVal pc_reg)
      break' loop_lbl Nothing
  pure $ getLVal r1

stgReturnFunction _ =
  runEDSL [] $ storeI64 (symbol "__asterius_pc") 0 $ constI64 0

getStablePtrWrapperFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    obj64 <- param I64
    sp_f64 <-
      callImport' "__asterius_newStablePtr" [convertUInt64ToFloat64 obj64] F64
    emit $ truncUFloat64ToInt64 sp_f64

deRefStablePtrWrapperFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    sp64 <- param I64
    obj_f64 <-
      callImport' "__asterius_deRefStablePtr" [convertUInt64ToFloat64 sp64] F64
    emit $ truncUFloat64ToInt64 obj_f64

freeStablePtrWrapperFunction _ =
  runEDSL [] $ do
    sp64 <- param I64
    callImport "__asterius_freeStablePtr" [convertUInt64ToFloat64 sp64]

rtsMkHelper :: BuiltinsOptions -> AsteriusEntitySymbol -> Function
rtsMkHelper _ con_sym =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [i] <- params [I64]
    p <- call' "allocate" [mainCapability, constI64 2] I64
    storeI64 p 0 $ symbol con_sym
    storeI64 p 8 i
    emit p

rtsMkBoolFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [i] <- params [I64]
    if'
      [I64]
      (eqZInt64 i)
      (emit $ symbol' "ghczmprim_GHCziTypes_False_closure" 1)
      (emit $ symbol' "ghczmprim_GHCziTypes_True_closure" 2)

rtsMkDoubleFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [i] <- params [F64]
    p <- call' "allocate" [mainCapability, constI64 2] I64
    storeI64 p 0 $ symbol "ghczmprim_GHCziTypes_Dzh_con_info"
    storeF64 p 8 i
    emit p

rtsMkCharFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [i] <- params [I64]
    p <- call' "allocate" [mainCapability, constI64 2] I64
    storeI64 p 0 $ symbol "ghczmprim_GHCziTypes_Czh_con_info"
    storeI64 p 8 i
    emit p

rtsMkIntFunction opts = rtsMkHelper opts "ghczmprim_GHCziTypes_Izh_con_info"

rtsMkWordFunction opts = rtsMkHelper opts "ghczmprim_GHCziTypes_Wzh_con_info"

rtsMkPtrFunction opts = rtsMkHelper opts "base_GHCziPtr_Ptr_con_info"

rtsMkStablePtrFunction opts =
  rtsMkHelper opts "base_GHCziStable_StablePtr_con_info"

unTagClosure :: Expression -> Expression
unTagClosure p = p `andInt64` constI64 0xFFFFFFFFFFFFFFF8

rtsGetBoolFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    p <- param I64
    emit $
      extendUInt32 $
      neInt32
        (constI32 0)
        (loadI32 (loadI64 (unTagClosure p) 0) offset_StgInfoTable_srt)

rtsGetDoubleFunction _ =
  runEDSL [F64] $ do
    setReturnTypes [F64]
    p <- param I64
    emit $ loadF64 (unTagClosure p) offset_StgClosure_payload

rtsGetCharFunction = rtsGetIntFunction

rtsGetIntFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    p <- param I64
    emit $ loadI64 (unTagClosure p) offset_StgClosure_payload

loadI64Function _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    p <- param I64
    emit $ loadI64 p 0

printI64Function _ =
  runEDSL [] $ do
    x <- param I64
    callImport "printI64" [convertSInt64ToFloat64 x]

assertEqI64Function _ =
  runEDSL [] $ do
    x <- param I64
    y <- param I64
    callImport "assertEqI64" [convertSInt64ToFloat64 x, convertSInt64ToFloat64 y]

printF32Function _ =
  runEDSL [] $ do
    x <- param F32
    callImport "printF32" [x]

printF64Function _ =
  runEDSL [] $ do
    x <- param F64
    callImport "printF64" [x]

strlenFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [str] <- params [I64]
    len <- callImport' "__asterius_strlen" [convertUInt64ToFloat64 str] F64
    emit $ truncUFloat64ToInt64 len

memchrFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [ptr, val, num] <- params [I64, I64, I64]
    p <-
      callImport'
        "__asterius_memchr"
        (map (convertUInt64ToFloat64) [ptr, val, num])
        F64
    emit $ truncUFloat64ToInt64 p

memcpyFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [dst, src, n] <- params [I64, I64, I64]
    callImport "__asterius_memcpy" $ map (convertUInt64ToFloat64) [dst, src, n]
    emit dst

memsetFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [dst, c, n] <- params [I64, I64, I64]
    callImport "__asterius_memset" $ map (convertUInt64ToFloat64) [dst, c, n]
    emit dst

memcmpFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [ptr1, ptr2, n] <- params [I64, I64, I64]
    cres <-
      callImport'
        "__asterius_memcmp"
        (map (convertUInt64ToFloat64) [ptr1, ptr2, n])
        I32
    emit $ Unary ExtendSInt32 cres

fromJSArrayBufferFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [buf] <- params [I64]
    addr <-
      truncUFloat64ToInt64 <$>
      callImport'
        "__asterius_fromJSArrayBuffer_imp"
        [convertUInt64ToFloat64 buf]
        F64
    emit addr

toJSArrayBufferFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [addr, len] <- params [I64, I64]
    r <-
      truncUFloat64ToInt64 <$>
      callImport'
        "__asterius_toJSArrayBuffer_imp"
        (map (convertUInt64ToFloat64) [addr, len])
        F64
    emit r

fromJSStringFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [s] <- params [I64]
    addr <-
      truncUFloat64ToInt64 <$>
      callImport' "__asterius_fromJSString_imp" [convertUInt64ToFloat64 s] F64
    emit addr

fromJSArrayFunction _ =
  runEDSL [I64] $ do
    setReturnTypes [I64]
    [arr] <- params [I64]
    addr <-
      truncUFloat64ToInt64 <$>
      callImport' "__asterius_fromJSArray_imp" [convertUInt64ToFloat64 arr] F64
    emit addr

threadPausedFunction _ = runEDSL [] $ void $ params [I64, I64]

dirtyMutVarFunction _ =
  runEDSL [] $ do
    [_, p] <- params [I64, I64]
    if'
      []
      (loadI64 p 0 `eqInt64` symbol "stg_MUT_VAR_CLEAN_info")
      (storeI64 p 0 $ symbol "stg_MUT_VAR_DIRTY_info")
      mempty

getF64GlobalRegFunction :: BuiltinsOptions -> UnresolvedGlobalReg -> Function
getF64GlobalRegFunction _ gr =
  runEDSL [F64] $ do
    setReturnTypes [F64]
    emit $ convertSInt64ToFloat64 $ getLVal $ global gr

trapLoadI8Function _ =
  Function
    { functionType = FunctionType {paramTypes = [I64, I32], returnTypes = [I32]}
    , varTypes = []
    , body =
        Block
          { name = ""
          , bodys =
              [ CallImport
                  { target' = "__asterius_load_I8"
                  , operands = [fp, o, v]
                  , callImportReturnTypes = []
                  }
              , v
              ]
          , blockReturnTypes = [I32]
          }
    }
  where
    bp = GetLocal {index = 0, valueType = I64}
    o = GetLocal {index = 1, valueType = I32}
    p =
      Binary
        { binaryOp = AddInt32
        , operand0 = Unary {unaryOp = WrapInt64, operand0 = bp}
        , operand1 = o
        }
    fp = Unary {unaryOp = ConvertUInt64ToFloat64, operand0 = bp}
    v = Load {signed = False, bytes = 1, offset = 0, valueType = I32, ptr = p}

trapStoreI8Function _ =
  Function
    { functionType =
        FunctionType {paramTypes = [I64, I32, I32], returnTypes = []}
    , varTypes = []
    , body =
        Block
          { name = ""
          , bodys =
              [ CallImport
                  { target' = "__asterius_store_I8"
                  , operands = [fp, o, v]
                  , callImportReturnTypes = []
                  }
              , Store
                  {bytes = 1, offset = 0, ptr = p, value = v, valueType = I32}
              ]
          , blockReturnTypes = []
          }
    }
  where
    bp = GetLocal {index = 0, valueType = I64}
    o = GetLocal {index = 1, valueType = I32}
    p =
      Binary
        { binaryOp = AddInt32
        , operand0 = Unary {unaryOp = WrapInt64, operand0 = bp}
        , operand1 = o
        }
    fp = Unary {unaryOp = ConvertUInt64ToFloat64, operand0 = bp}
    v = GetLocal {index = 2, valueType = I32}

trapLoadI16Function _ =
  Function
    { functionType = FunctionType {paramTypes = [I64, I32], returnTypes = [I32]}
    , varTypes = []
    , body =
        Block
          { name = ""
          , bodys =
              [ CallImport
                  { target' = "__asterius_load_I16"
                  , operands = [fp, o, v]
                  , callImportReturnTypes = []
                  }
              , v
              ]
          , blockReturnTypes = [I32]
          }
    }
  where
    bp = GetLocal {index = 0, valueType = I64}
    o = GetLocal {index = 1, valueType = I32}
    p =
      Binary
        { binaryOp = AddInt32
        , operand0 = Unary {unaryOp = WrapInt64, operand0 = bp}
        , operand1 = o
        }
    fp = Unary {unaryOp = ConvertUInt64ToFloat64, operand0 = bp}
    v = Load {signed = False, bytes = 2, offset = 0, valueType = I32, ptr = p}

trapStoreI16Function _ =
  Function
    { functionType =
        FunctionType {paramTypes = [I64, I32, I32], returnTypes = []}
    , varTypes = []
    , body =
        Block
          { name = ""
          , bodys =
              [ CallImport
                  { target' = "__asterius_store_I16"
                  , operands = [fp, o, v]
                  , callImportReturnTypes = []
                  }
              , Store
                  {bytes = 2, offset = 0, ptr = p, value = v, valueType = I32}
              ]
          , blockReturnTypes = []
          }
    }
  where
    bp = GetLocal {index = 0, valueType = I64}
    o = GetLocal {index = 1, valueType = I32}
    p =
      Binary
        { binaryOp = AddInt32
        , operand0 = Unary {unaryOp = WrapInt64, operand0 = bp}
        , operand1 = o
        }
    fp = Unary {unaryOp = ConvertUInt64ToFloat64, operand0 = bp}
    v = GetLocal {index = 2, valueType = I32}

trapLoadI32Function _ =
  Function
    { functionType = FunctionType {paramTypes = [I64, I32], returnTypes = [I32]}
    , varTypes = []
    , body =
        Block
          { name = ""
          , bodys =
              [ CallImport
                  { target' = "__asterius_load_I32"
                  , operands = [fp, o, v]
                  , callImportReturnTypes = []
                  }
              , v
              ]
          , blockReturnTypes = [I32]
          }
    }
  where
    bp = GetLocal {index = 0, valueType = I64}
    o = GetLocal {index = 1, valueType = I32}
    p =
      Binary
        { binaryOp = AddInt32
        , operand0 = Unary {unaryOp = WrapInt64, operand0 = bp}
        , operand1 = o
        }
    fp = Unary {unaryOp = ConvertUInt64ToFloat64, operand0 = bp}
    v = Load {signed = False, bytes = 4, offset = 0, valueType = I32, ptr = p}

trapStoreI32Function _ =
  Function
    { functionType =
        FunctionType {paramTypes = [I64, I32, I32], returnTypes = []}
    , varTypes = []
    , body =
        Block
          { name = ""
          , bodys =
              [ CallImport
                  { target' = "__asterius_store_I32"
                  , operands = [fp, o, v]
                  , callImportReturnTypes = []
                  }
              , Store
                  {bytes = 4, offset = 0, ptr = p, value = v, valueType = I32}
              ]
          , blockReturnTypes = []
          }
    }
  where
    bp = GetLocal {index = 0, valueType = I64}
    o = GetLocal {index = 1, valueType = I32}
    p =
      Binary
        { binaryOp = AddInt32
        , operand0 = Unary {unaryOp = WrapInt64, operand0 = bp}
        , operand1 = o
        }
    fp = Unary {unaryOp = ConvertUInt64ToFloat64, operand0 = bp}
    v = GetLocal {index = 2, valueType = I32}

trapLoadI64Function _ =
  Function
    { functionType = FunctionType {paramTypes = [I64, I32], returnTypes = [I64]}
    , varTypes = []
    , body =
        Block
          { name = ""
          , bodys =
              [ CallImport
                  { target' = "__asterius_load_I64"
                  , operands = [fp, o, v_lo, v_hi]
                  , callImportReturnTypes = []
                  }
              , v
              ]
          , blockReturnTypes = [I64]
          }
    }
  where
    bp = GetLocal {index = 0, valueType = I64}
    o = GetLocal {index = 1, valueType = I32}
    p =
      Binary
        { binaryOp = AddInt32
        , operand0 = Unary {unaryOp = WrapInt64, operand0 = bp}
        , operand1 = o
        }
    fp = Unary {unaryOp = ConvertUInt64ToFloat64, operand0 = bp}
    v = Load {signed = False, bytes = 8, offset = 0, valueType = I64, ptr = p}
    v_lo = Unary {unaryOp = WrapInt64, operand0 = v}
    v_hi =
      Unary
        { unaryOp = WrapInt64
        , operand0 =
            Binary {binaryOp = ShrUInt64, operand0 = v, operand1 = ConstI64 32}
        }

trapStoreI64Function _ =
  Function
    { functionType =
        FunctionType {paramTypes = [I64, I32, I64], returnTypes = []}
    , varTypes = []
    , body =
        Block
          { name = ""
          , bodys =
              [ CallImport
                  { target' = "__asterius_store_I64"
                  , operands = [fp, o, v_lo, v_hi]
                  , callImportReturnTypes = []
                  }
              , Store
                  {bytes = 8, offset = 0, ptr = p, value = v, valueType = I64}
              ]
          , blockReturnTypes = []
          }
    }
  where
    bp = GetLocal {index = 0, valueType = I64}
    o = GetLocal {index = 1, valueType = I32}
    p =
      Binary
        { binaryOp = AddInt32
        , operand0 = Unary {unaryOp = WrapInt64, operand0 = bp}
        , operand1 = o
        }
    fp = Unary {unaryOp = ConvertUInt64ToFloat64, operand0 = bp}
    v = GetLocal {index = 2, valueType = I64}
    v_lo = Unary {unaryOp = WrapInt64, operand0 = v}
    v_hi =
      Unary
        { unaryOp = WrapInt64
        , operand0 =
            Binary {binaryOp = ShrUInt64, operand0 = v, operand1 = ConstI64 32}
        }

trapLoadF32Function _ =
  Function
    { functionType = FunctionType {paramTypes = [I64, I32], returnTypes = [F32]}
    , varTypes = []
    , body =
        Block
          { name = ""
          , bodys =
              [ CallImport
                  { target' = "__asterius_load_F32"
                  , operands = [fp, o, v]
                  , callImportReturnTypes = []
                  }
              , v
              ]
          , blockReturnTypes = [F32]
          }
    }
  where
    bp = GetLocal {index = 0, valueType = I64}
    o = GetLocal {index = 1, valueType = I32}
    p =
      Binary
        { binaryOp = AddInt32
        , operand0 = Unary {unaryOp = WrapInt64, operand0 = bp}
        , operand1 = o
        }
    fp = Unary {unaryOp = ConvertUInt64ToFloat64, operand0 = bp}
    v = Load {signed = True, bytes = 4, offset = 0, valueType = F32, ptr = p}

trapStoreF32Function _ =
  Function
    { functionType =
        FunctionType {paramTypes = [I64, I32, F32], returnTypes = []}
    , varTypes = []
    , body =
        Block
          { name = ""
          , bodys =
              [ CallImport
                  { target' = "__asterius_store_F32"
                  , operands = [fp, o, v]
                  , callImportReturnTypes = []
                  }
              , Store
                  {bytes = 4, offset = 0, ptr = p, value = v, valueType = F32}
              ]
          , blockReturnTypes = []
          }
    }
  where
    bp = GetLocal {index = 0, valueType = I64}
    o = GetLocal {index = 1, valueType = I32}
    p =
      Binary
        { binaryOp = AddInt32
        , operand0 = Unary {unaryOp = WrapInt64, operand0 = bp}
        , operand1 = o
        }
    fp = Unary {unaryOp = ConvertUInt64ToFloat64, operand0 = bp}
    v = GetLocal {index = 2, valueType = F32}

trapLoadF64Function _ =
  Function
    { functionType = FunctionType {paramTypes = [I64, I32], returnTypes = [F64]}
    , varTypes = []
    , body =
        Block
          { name = ""
          , bodys =
              [ CallImport
                  { target' = "__asterius_load_F64"
                  , operands = [fp, o, v]
                  , callImportReturnTypes = []
                  }
              , v
              ]
          , blockReturnTypes = [F64]
          }
    }
  where
    bp = GetLocal {index = 0, valueType = I64}
    o = GetLocal {index = 1, valueType = I32}
    p =
      Binary
        { binaryOp = AddInt32
        , operand0 = Unary {unaryOp = WrapInt64, operand0 = bp}
        , operand1 = o
        }
    fp = Unary {unaryOp = ConvertUInt64ToFloat64, operand0 = bp}
    v = Load {signed = True, bytes = 8, offset = 0, valueType = F64, ptr = p}

trapStoreF64Function _ =
  Function
    { functionType =
        FunctionType {paramTypes = [I64, I32, F64], returnTypes = []}
    , varTypes = []
    , body =
        Block
          { name = ""
          , bodys =
              [ CallImport
                  { target' = "__asterius_store_F64"
                  , operands = [fp, o, v]
                  , callImportReturnTypes = []
                  }
              , Store
                  {bytes = 8, offset = 0, ptr = p, value = v, valueType = F64}
              ]
          , blockReturnTypes = []
          }
    }
  where
    bp = GetLocal {index = 0, valueType = I64}
    o = GetLocal {index = 1, valueType = I32}
    p =
      Binary
        { binaryOp = AddInt32
        , operand0 = Unary {unaryOp = WrapInt64, operand0 = bp}
        , operand1 = o
        }
    fp = Unary {unaryOp = ConvertUInt64ToFloat64, operand0 = bp}
    v = GetLocal {index = 2, valueType = F64}

offset_StgTSO_StgStack :: Int
offset_StgTSO_StgStack = 8 * roundup_bytes_to_words sizeof_StgTSO


wrapI64ToI8 _ =
  let v = runEDSL [I32] $ do
        setReturnTypes [I32]
        x <- param I64
        storeI64 (symbol "__asterius_i64_slot") 0 x
        emit $ loadI8 (symbol "__asterius_i64_slot") 0
  in trace (show v) v

wrapI32ToI8 _ =
    runEDSL [I32] $ do
    setReturnTypes [I32]
    x <- param I32
    storeI32  (symbol "__asterius_i32_slot") 0 x
    emit $ loadI8 (symbol "__asterius_i32_slot") 0

wrapI64ToI16 _ =
  let v = runEDSL [I32] $ do
        setReturnTypes [I32]
        x <- param I64
        storeI64 (symbol "__asterius_i64_slot") 0 x
        emit $ loadI16 (symbol "__asterius_i64_slot") 0
  in trace (show v) v

wrapI32ToI16 _ =
    runEDSL [I32] $ do
    setReturnTypes [I32]
    x <- param I32
    storeI32 (symbol "__asterius_i32_slot") 0 x
    emit $ loadI16 (symbol "__asterius_i32_slot") 0

-- SEXT

extendI8ToI64Sext _ =
    runEDSL [I64] $ do
    setReturnTypes [I64]
    x <- param I32
    storeI32 (symbol "__asterius_i64_slot") 0 x
    emit $ Load{ signed=True, bytes=1, offset=0, valueType=I64, ptr = wrapInt64(symbol "__asterius_i64_slot")  }

extendI16ToI64Sext _ =
    runEDSL [I64] $ do
    setReturnTypes [I64]
    x <- param I32
    storeI32 (symbol "__asterius_i64_slot") 0 x
    emit $ Load{ signed=True, bytes=2, offset=0, valueType=I64, ptr = wrapInt64 (symbol "__asterius_i64_slot")  }

extendI8ToI32Sext _ =
    runEDSL [I32] $ do
    setReturnTypes [I32]
    x <- param I32
    storeI32 (symbol "__asterius_i32_slot") 0 x
    emit $ Load{ signed=True, bytes=1, offset=0, valueType=I32, ptr = wrapInt64(symbol "__asterius_i32_slot")  }

extendI16ToI32Sext _ =
    runEDSL [I32] $ do
    setReturnTypes [I32]
    x <- param I32
    storeI32 (symbol "__asterius_i32_slot") 0 x
    emit $ Load{ signed=True, bytes=2, offset=0, valueType=I32, ptr = wrapInt64 (symbol "__asterius_i32_slot")  }


-- NOSEXT

extendI8ToI64 _ =
    runEDSL [I64] $ do
    setReturnTypes [I64]
    x <- param I32
    storeI32 (symbol "__asterius_i64_slot") 0 x
    emit $ Load{ signed=False, bytes=1, offset=0, valueType=I64, ptr = wrapInt64(symbol "__asterius_i64_slot")  }

extendI16ToI64 _ =
    runEDSL [I64] $ do
    setReturnTypes [I64]
    x <- param I32
    storeI32 (symbol "__asterius_i64_slot") 0 x
    emit $ Load{ signed=False, bytes=2, offset=0, valueType=I64, ptr = wrapInt64 (symbol "__asterius_i64_slot")  }

extendI8ToI32 _ =
    runEDSL [I32] $ do
    setReturnTypes [I32]
    x <- param I32
    storeI32 (symbol "__asterius_i32_slot") 0 x
    emit $ Load{ signed=False, bytes=1, offset=0, valueType=I32, ptr = wrapInt64(symbol "__asterius_i32_slot")  }

extendI16ToI32 _ =
    runEDSL [I32] $ do
    setReturnTypes [I32]
    x <- param I32
    storeI32 (symbol "__asterius_i32_slot") 0 x
    emit $ Load{ signed=False, bytes=2, offset=0, valueType=I32, ptr = wrapInt64 (symbol "__asterius_i32_slot")  }
