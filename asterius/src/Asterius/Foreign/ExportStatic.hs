{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Asterius.Foreign.ExportStatic
  ( genExportStaticObj,
    encodeTys,
  )
where

import Asterius.Foreign.SupportedTypes
import Asterius.Internals ((!))
import Asterius.Types
import Data.Bits
import Data.ByteString.Builder
import Data.Foldable
import Data.Int
import Data.List
import qualified Data.Map.Strict as M

genExportStaticObj ::
  FFIMarshalState -> M.Map EntitySymbol Int64 -> Builder
genExportStaticObj FFIMarshalState {..} sym_map =
  "["
    <> mconcat
      ( intersperse
          ","
          [ genExportStaticFunc k export_decl sym_map
            | (k, export_decl) <- M.toList ffiExportDecls
          ]
      )
    <> "]"

genExportStaticFunc ::
  EntitySymbol ->
  FFIExportDecl ->
  M.Map EntitySymbol Int64 ->
  Builder
genExportStaticFunc k FFIExportDecl {ffiFunctionType = FFIFunctionType {..}, ..} sym_map =
  "[\""
    <> byteString (entityName k)
    <> "\",0x"
    <> int64HexFixed (sym_map ! ffiExportClosure)
    <> ",0x"
    <> int64HexFixed (encodeTys ffiParamTypes)
    <> ",0x"
    <> int64HexFixed (encodeTys ffiResultTypes)
    <> ","
    <> if ffiInIO then "true]" else "false]"

encodeTys :: [FFIValueType] -> Int64
encodeTys = foldr' (\vt acc -> (acc `shiftL` 5) .|. encodeTy vt) 0

encodeTy :: FFIValueType -> Int64
encodeTy vt =
  case findIndex (\vt' -> hsTyCon vt == hsTyCon vt') ffiBoxedValueTypeList of
    Just i -> fromIntegral i + 1
    _ -> error $ "Asterius.Foreign.ExportStatic: cannot encode " <> show vt
