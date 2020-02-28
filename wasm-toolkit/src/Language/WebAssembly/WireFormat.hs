-----------------------------------------------------------------------------
-- |
-- Module      :  Language.WebAssembly.WireFormat
-- Copyright   :  (c) 2018 EURL Tweag
-- License     :  All rights reserved (see LICENCE file in the distribution).
--
-- Complete definition of the WebAssembly AST, including support for custom
-- sections, and binary serialization/deserialization. Most of the comments are
-- taken from the official specification of WebAssembly:
--
--   https://webassembly.github.io/spec/ or
--   https://github.com/WebAssembly/spec/
--
-----------------------------------------------------------------------------

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE StrictData #-}

module Language.WebAssembly.WireFormat
  ( -- * Types
    Name (..),
    ValueType (..),
    ResultType,
    FunctionType (..),
    Limits (..),
    MemoryType (..),
    ElementType (..),
    TableType (..),
    Mutability (..),
    GlobalType (..),
    MemoryArgument (..),
    Instruction (..),
    Expression (..),
    Custom (..),
    -- ** Indices
    FunctionTypeIndex (..),
    FunctionIndex (..),
    TableIndex (..),
    MemoryIndex (..),
    GlobalIndex (..),
    LocalIndex (..),
    LabelIndex (..),

    Table (..),
    Memory (..),
    Global (..),
    Element (..),
    Locals (..),
    Function (..),
    DataSegment (..),
    Section (..),
    Module (..),

    -- ** Exports
    ExportDescription (..),
    Export (..),
    -- ** Imports
    ImportDescription (..),
    Import (..),

    -- * Binary (de)serialization
    -- ** 32-bit, unsigned
    getVU32,
    putVU32,
    -- ** 32-bit, signed
    getVS32,
    putVS32,
    -- ** 64-bit, signed
    getVS64,
    putVS64,
    -- ** Float, single precision
    getF32,
    putF32,
    -- ** Float, double precision
    getF64,
    putF64,
    -- ** Modules
    getModule,
    putModule,
    -- * Custom Sections
    LinkingSymbolFlags (..),
    LinkingSymbolInfo (..),
    LinkingSubSection (..),
    RelocationType (..),
    RelocationEntry (..),
    getLinkingSymbolInfo,
    putLinkingSymbolInfo,
  )
where

import Control.Applicative hiding (Const)
import Control.Monad hiding (fail)
import Control.Monad.Fail
import Data.Binary.Get
import Data.Binary.Put
import Data.Bits
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import qualified Data.ByteString.Short as SBS
import Data.Coerce
import Data.Foldable
import Data.Int
import Data.Word
import GHC.Generics (Generic)
import Prelude hiding (fail)

-- | WebAssembly names.
newtype Name
  = Name SBS.ShortByteString
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'Name'.
getName :: Get Name
getName = coerce getVecSBS

-- | Serialize a 'Name'.
putName :: Name -> Put
putName = coerce putVecSBS

-- | 'ValueType's classify the individual values that WebAssembly
-- code can compute with and the values that a variable accepts.
data ValueType
  = I32  -- ^ 32-bit integer
  | I64  -- ^ 64-bit integer
  | F32  -- ^ 32-bit floating-point / single precision (IEEE 754-2019)
  | F64  -- ^ 64-bit floating-point / double precision (IEEE 754-2019)
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'ValueType'.
getValueType :: Get ValueType
getValueType = do
  b <- getWord8
  case b of
    0x7F -> pure I32
    0x7E -> pure I64
    0x7D -> pure F32
    0x7C -> pure F64
    _ -> fail "Language.WebAssembly.WireFormat.getValueType"

-- | Serialize a 'ValueType'.
putValueType :: ValueType -> Put
putValueType vt = putWord8 $ case vt of
  I32 -> 0x7F
  I64 -> 0x7E
  F32 -> 0x7D
  F64 -> 0x7C

-- | Result types classify the result of executing instructions or blocks,
-- which is a sequence of values written with brackets. __NOTE__: In the
-- current version of WebAssembly, at most one value is allowed as a result.
-- However, this may be generalized to sequences of values in future versions.
type ResultType = [ValueType]

-- | Deserialize a 'ResultType'.
getResultType :: Get ResultType
getResultType =
  ( do
      b <- getWord8
      case b of
        0x40 -> pure []
        _ -> fail "Language.WebAssembly.WireFormat.getResultType"
  )
    <|> ( do
            vt <- getValueType
            pure [vt]
        )

-- | Serialize a 'ResultType'.
putResultType :: ResultType -> Put
putResultType resultValueTypes = case resultValueTypes of
  [] -> putWord8 0x40
  [t] -> putValueType t
  _ -> error "Language.WebAssembly.WireFormat.putResultType"

-- | 'FunctionType's classify the signature of functions, mapping a vector of
-- parameters to a vector of results. __NOTE__: In the current version of
-- WebAssembly the result type of a valid function type can be /at most/ 1.
-- This restriction may be removed in a future version.
data FunctionType
  = FunctionType
      { parameterTypes, resultTypes :: [ValueType]
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'FunctionType'.
getFunctionType :: Get FunctionType
getFunctionType = do
  b <- getWord8
  case b of
    0x60 -> FunctionType <$> getVec getValueType <*> getVec getValueType
    _ -> fail "Language.WebAssembly.WireFormat.getFunctionType"

-- | Serialize a 'FunctionType'.
putFunctionType :: FunctionType -> Put
putFunctionType FunctionType {..} = do
  putWord8 0x60
  putVec putValueType parameterTypes
  putVec putValueType resultTypes

-- | 'Limits' classify the size range of resizeable storage associated with
--   memory types and table types.
data Limits
  = Limits
      { minLimit :: Word32,
        maxLimit :: Maybe Word32
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize 'Limits'.
getLimits :: Get Limits
getLimits = do
  b <- getWord8
  case b of
    0x01 -> Limits <$> getVU32 <*> fmap Just getVU32
    0x00 -> Limits <$> getVU32 <*> pure Nothing
    _ -> fail "Language.WebAssembly.WireFormat.getLimits"

-- | Serialize 'Limits'.
putLimits :: Limits -> Put
putLimits Limits {..} = case maxLimit of
  Just _max_limit -> do
    putWord8 0x01
    putVU32 minLimit
    putVU32 _max_limit
  _ -> do
    putWord8 0x00
    putVU32 minLimit

-- | 'MemoryType's classify linear memories and their size range. The limits
-- constrain the minimum (starting), and optionally the maximum size of a
-- memory. The limits are given in units of page size.
newtype MemoryType
  = MemoryType
      { memoryLimits :: Limits
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'MemoryType'.
getMemoryType :: Get MemoryType
getMemoryType = coerce getLimits

-- | Serialize a 'MemoryType'.
putMemoryType :: MemoryType -> Put
putMemoryType = coerce putLimits

-- | The 'ElementType' captures the infinite union of all function types
-- (somewhat like Top). This means that e.g. tables containing elements of type
-- 'ElementType' essentially contain references to functions of heterogeneous
-- types.
data ElementType
  = AnyFunc
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize the 'ElementType'.
getElementType :: Get ElementType
getElementType = do
  b <- getWord8
  case b of
    0x70 -> pure AnyFunc
    _ -> fail "Language.WebAssembly.WireFormat.getElementType"

-- | Serialize the 'ElementType'.
putElementType :: ElementType -> Put
putElementType et = putWord8 $ case et of
  AnyFunc -> 0x70

-- | 'TableType's classify 'Table's over elements of element types within a
-- size range. Like memories, tables are constrained by limits for their
-- minimum and optionally maximum size.
data TableType
  = TableType
      { elementType :: ElementType,  -- ^ Type of elements (see 'ElementType').
        tableLimits :: Limits        -- ^ The limits are given in numbers of entries.
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'TableType'.
getTableType :: Get TableType
getTableType = TableType <$> getElementType <*> getLimits

-- | Serialize a 'TableType'.
putTableType :: TableType -> Put
putTableType TableType {..} = do
  putElementType elementType
  putLimits tableLimits

-- | 'Mutability' of variables.
data Mutability
  = Const  -- ^ Immutable.
  | Var    -- ^ Mutable.
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize 'Mutability'.
getMutability :: Get Mutability
getMutability = do
  b <- getWord8
  case b of
    0x00 -> pure Const
    0x01 -> pure Var
    _ -> fail "Language.WebAssembly.WireFormat.getMutability"

-- | Serialize 'Mutability'.
putMutability :: Mutability -> Put
putMutability m = putWord8 $ case m of
  Const -> 0x00
  Var -> 0x01

-- | 'GlobalType's classify global variables which hold a value and can either
-- be mutable or immutable.
data GlobalType
  = GlobalType
      { globalValueType :: ValueType,
        globalMutability :: Mutability
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'GlobalType'.
getGlobalType :: Get GlobalType
getGlobalType = GlobalType <$> getValueType <*> getMutability

-- | Serialize a 'GlobalType'.
putGlobalType :: GlobalType -> Put
putGlobalType GlobalType {..} = do
  putValueType globalValueType
  putMutability globalMutability

-- | An /immediate memory argument/ 'MemoryArgument' contains an address offset
-- and the expected alignment.
data MemoryArgument
  = MemoryArgument
      { memoryArgumentAlignment :: Word32,  -- ^ Alignment (expressed as the exponend of a power of 2).
        memoryArgumentOffset :: Word32      -- ^ Address offset.
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'MemoryArgument'.
getMemoryArgument :: Get MemoryArgument
getMemoryArgument = MemoryArgument <$> getVU32 <*> getVU32

-- | Serialize a 'MemoryArgument'.
putMemoryArgument :: MemoryArgument -> Put
putMemoryArgument MemoryArgument {..} = do
  putVU32 memoryArgumentAlignment
  putVU32 memoryArgumentOffset

-- | An 'Instruction' is the building block for WebAssembly programs.
data Instruction
  = -- | Produce an unconditional trap (abort execution).
    Unreachable
    -- | Do nothing.
  | Nop
    -- | A block of instructions.
  | Block
      { blockResultType :: [ValueType],
        blockInstructions :: [Instruction]
      }
    -- | A block of instruction to iterate over.
  | Loop
      { loopResultType :: [ValueType],
        loopInstructions :: [Instruction]
      }
    -- | If-then-(possibly)else statement.
  | If
      { ifResultType :: [ValueType],
        thenInstructions :: [Instruction],
        elseInstructions :: Maybe [Instruction]
      }
    -- | Unconditional branching.
  | Branch
      { branchLabel :: LabelIndex
      }
    -- | Conditional branching.
  | BranchIf
      { branchIfLabel :: LabelIndex
      }
    -- | Indirect branching, through an operand indexing into the a vector
    -- ('branchTableLabels'), or to a default target
    -- ('branchTableFallbackLabel') if the operand is out of bounds.
  | BranchTable
      { branchTableLabels :: [LabelIndex],
        branchTableFallbackLabel :: LabelIndex
      }
    -- | Unconditionally branch to the outermost block (essentially the body of
    -- the current function).
  | Return
    -- | Invoke a function.
  | Call
      { callFunctionIndex :: FunctionIndex
      }
    -- | Invoke a function indirectly, through its index.
  | CallIndirect
      { callIndirectFuctionTypeIndex :: FunctionTypeIndex
      }
    -- | TODO.
  | ReturnCall
      { returnCallFunctionIndex :: FunctionIndex
      }
    -- | TODO.
  | ReturnCallIndirect
      { returnCallIndirectFunctionTypeIndex :: FunctionTypeIndex
      }
    -- | Throw away an operand.
    -- Can operate on any 'ValueType'.
  | Drop
    -- | Select one of the first two operands based on whether the third
    -- operand is zero or not.
    -- Can operate on any 'ValueType'.
  | Select
    -- | Get the value of a local variable.
  | GetLocal
      { getLocalIndex :: LocalIndex
      }
    -- | Set the value of a local variable.
  | SetLocal
      { setLocalIndex :: LocalIndex
      }
    -- | Set the value of a local variable and return it (GEORGE: IT???).
  | TeeLocal
      { teeLocalIndex :: LocalIndex
      }
    -- | Get the value of a global variable.
  | GetGlobal
      { getGlobalIndex :: GlobalIndex
      }
    -- | Set the value of a global variable.
  | SetGlobal
      { setGlobalIndex :: GlobalIndex
      }
  | I32Load
      { i32LoadMemoryArgument :: MemoryArgument
      }
  | I64Load
      { i64LoadMemoryArgument :: MemoryArgument
      }
  | F32Load
      { f32LoadMemoryArgument :: MemoryArgument
      }
  | F64Load
      { f64LoadMemoryArgument :: MemoryArgument
      }
  | I32Load8Signed
      { i32Load8SignedMemoryArgument :: MemoryArgument
      }
  | I32Load8Unsigned
      { i32Load8UnsignedMemoryArgument :: MemoryArgument
      }
  | I32Load16Signed
      { i32Load16SignedMemoryArument :: MemoryArgument
      }
  | I32Load16Unsigned
      { i32Load16UnsignedMemoryArgument :: MemoryArgument
      }
  | I64Load8Signed
      { i64Load8SignedMemoryArgument :: MemoryArgument
      }
  | I64Load8Unsigned
      { i64Load8UnsignedMemoryArgument :: MemoryArgument
      }
  | I64Load16Signed
      { i64Load16SignedMemoryArgument :: MemoryArgument
      }
  | I64Load16Unsigned
      { i64Load16UnsignedMemoryArgument :: MemoryArgument
      }
  | I64Load32Signed
      { i64Load32SignedMemoryArgument :: MemoryArgument
      }
  | I64Load32Unsigned
      { i64Load32UnsignedMemoryArgument :: MemoryArgument
      }
  | I32Store
      { i32StoreMemoryArgument :: MemoryArgument
      }
  | I64Store
      { i64StoreMemoryArgument :: MemoryArgument
      }
  | F32Store
      { f32StoreMemoryArgument :: MemoryArgument
      }
  | F64Store
      { f64StoreMemoryArgument :: MemoryArgument
      }
  | I32Store8
      { i32Store8MemoryArgument :: MemoryArgument
      }
  | I32Store16
      { i32Store16MemoryArgument :: MemoryArgument
      }
  | I64Store8
      { i64Store8MemoryArgument :: MemoryArgument
      }
  | I64Store16
      { i64Store16MemoryArgument :: MemoryArgument
      }
  | I64Store32
      { i64Store32MemoryArgument :: MemoryArgument
      }
    -- | Return the current size of a memory.
    -- Operates on units of page size.
  | MemorySize
    -- | Grow memory by a given delta and return the previous size, or -1 if
    -- enough memory cannot be allocated.
    -- Operates on units of page size.
  | MemoryGrow
  | I32Const
      { i32ConstValue :: Int32
      }
  | I64Const
      { i64ConstValue :: Int64
      }
  | F32Const
      { f32ConstValue :: Float
      }
  | F64Const
      { f64ConstValue :: Double
      }
  | I32Eqz
  | I64Eqz
  | I32Clz
  | I32Ctz
  | I32Popcnt
  | I64Clz
  | I64Ctz
  | I64Popcnt
  | F32Abs
  | F32Neg
  | F32Ceil
  | F32Floor
  | F32Trunc
  | F32Nearest
  | F32Sqrt
  | F64Abs
  | F64Neg
  | F64Ceil
  | F64Floor
  | F64Trunc
  | F64Nearest
  | F64Sqrt
  | I32WrapFromI64
  | I32TruncSFromF32
  | I32TruncUFromF32
  | I32TruncSFromF64
  | I32TruncUFromF64
  | I64ExtendSFromI32
  | I64ExtendUFromI32
  | I64TruncSFromF32
  | I64TruncUFromF32
  | I64TruncSFromF64
  | I64TruncUFromF64
  | F32ConvertSFromI32
  | F32ConvertUFromI32
  | F32ConvertSFromI64
  | F32ConvertUFromI64
  | F32DemoteFromF64
  | F64ConvertSFromI32
  | F64ConvertUFromI32
  | F64ConvertSFromI64
  | F64ConvertUFromI64
  | F64PromoteFromF32
  | I32ReinterpretFromF32
  | I64ReinterpretFromF64
  | F32ReinterpretFromI32
  | F64ReinterpretFromI64
  | I32Eq
  | I32Ne
  | I32LtS
  | I32LtU
  | I32GtS
  | I32GtU
  | I32LeS
  | I32LeU
  | I32GeS
  | I32GeU
  | I64Eq
  | I64Ne
  | I64LtS
  | I64LtU
  | I64GtS
  | I64GtU
  | I64LeS
  | I64LeU
  | I64GeS
  | I64GeU
  | F32Eq
  | F32Ne
  | F32Lt
  | F32Gt
  | F32Le
  | F32Ge
  | F64Eq
  | F64Ne
  | F64Lt
  | F64Gt
  | F64Le
  | F64Ge
  | I32Add
  | I32Sub
  | I32Mul
  | I32DivS
  | I32DivU
  | I32RemS
  | I32RemU
  | I32And
  | I32Or
  | I32Xor
  | I32Shl
  | I32ShrS
  | I32ShrU
  | I32RotL
  | I32RotR
  | I64Add
  | I64Sub
  | I64Mul
  | I64DivS
  | I64DivU
  | I64RemS
  | I64RemU
  | I64And
  | I64Or
  | I64Xor
  | I64Shl
  | I64ShrS
  | I64ShrU
  | I64RotL
  | I64RotR
  | F32Add
  | F32Sub
  | F32Mul
  | F32Div
  | F32Min
  | F32Max
  | F32Copysign
  | F64Add
  | F64Sub
  | F64Mul
  | F64Div
  | F64Min
  | F64Max
  | F64Copysign
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize an 'Instruction'.
getInstruction :: Get Instruction
getInstruction = do
  b <- getWord8
  case b of
    0x00 -> pure Unreachable
    0x01 -> pure Nop
    0x02 ->
      Block <$> getResultType <*> getMany getInstruction <* expectWord8 0x0B
    0x03 ->
      Loop <$> getResultType <*> getMany getInstruction <* expectWord8 0x0B
    0x04 ->
      If
        <$> getResultType
        <*> getMany getInstruction
        <*> ( (expectWord8 0x05 *> (Just <$> getMany getInstruction))
                <|> pure Nothing
            )
        <* expectWord8 0x0B
    0x0C -> Branch <$> getLabelIndex
    0x0D -> BranchIf <$> getLabelIndex
    0x0E -> BranchTable <$> getVec getLabelIndex <*> getLabelIndex
    0x0F -> pure Return
    0x10 -> Call <$> getFunctionIndex
    0x11 -> CallIndirect <$> getFunctionTypeIndex <* expectWord8 0x00
    0x12 -> ReturnCall <$> getFunctionIndex
    0x13 -> ReturnCallIndirect <$> getFunctionTypeIndex <* expectWord8 0x00
    0x1A -> pure Drop
    0x1B -> pure Select
    0x20 -> GetLocal <$> getLocalIndex'
    0x21 -> SetLocal <$> getLocalIndex'
    0x22 -> TeeLocal <$> getLocalIndex'
    0x23 -> GetGlobal <$> getGlobalIndex'
    0x24 -> SetGlobal <$> getGlobalIndex'
    0x28 -> I32Load <$> getMemoryArgument
    0x29 -> I64Load <$> getMemoryArgument
    0x2A -> F32Load <$> getMemoryArgument
    0x2B -> F64Load <$> getMemoryArgument
    0x2C -> I32Load8Signed <$> getMemoryArgument
    0x2D -> I32Load8Unsigned <$> getMemoryArgument
    0x2E -> I32Load16Signed <$> getMemoryArgument
    0x2F -> I32Load16Unsigned <$> getMemoryArgument
    0x30 -> I64Load8Signed <$> getMemoryArgument
    0x31 -> I64Load8Unsigned <$> getMemoryArgument
    0x32 -> I64Load16Signed <$> getMemoryArgument
    0x33 -> I64Load16Unsigned <$> getMemoryArgument
    0x34 -> I64Load32Signed <$> getMemoryArgument
    0x35 -> I64Load32Unsigned <$> getMemoryArgument
    0x36 -> I32Store <$> getMemoryArgument
    0x37 -> I64Store <$> getMemoryArgument
    0x38 -> F32Store <$> getMemoryArgument
    0x39 -> F64Store <$> getMemoryArgument
    0x3A -> I32Store8 <$> getMemoryArgument
    0x3B -> I32Store16 <$> getMemoryArgument
    0x3C -> I64Store8 <$> getMemoryArgument
    0x3D -> I64Store16 <$> getMemoryArgument
    0x3E -> I64Store32 <$> getMemoryArgument
    0x3F -> MemorySize <$ expectWord8 0x00
    0x40 -> MemoryGrow <$ expectWord8 0x00
    0x41 -> I32Const <$> getVS32
    0x42 -> I64Const <$> getVS64
    0x43 -> F32Const <$> getF32
    0x44 -> F64Const <$> getF64
    0x45 -> pure I32Eqz
    0x46 -> pure I32Eq
    0x47 -> pure I32Ne
    0x48 -> pure I32LtS
    0x49 -> pure I32LtU
    0x4A -> pure I32GtS
    0x4B -> pure I32GtU
    0x4C -> pure I32LeS
    0x4D -> pure I32LeU
    0x4E -> pure I32GeS
    0x4F -> pure I32GeU
    0x50 -> pure I64Eqz
    0x51 -> pure I64Eq
    0x52 -> pure I64Ne
    0x53 -> pure I64LtS
    0x54 -> pure I64LtU
    0x55 -> pure I64GtS
    0x56 -> pure I64GtU
    0x57 -> pure I64LeS
    0x58 -> pure I64LeU
    0x59 -> pure I64GeS
    0x5A -> pure I64GeU
    0x5B -> pure F32Eq
    0x5C -> pure F32Ne
    0x5D -> pure F32Lt
    0x5E -> pure F32Gt
    0x5F -> pure F32Le
    0x60 -> pure F32Ge
    0x61 -> pure F64Eq
    0x62 -> pure F64Ne
    0x63 -> pure F64Lt
    0x64 -> pure F64Gt
    0x65 -> pure F64Le
    0x66 -> pure F64Ge
    0x67 -> pure I32Clz
    0x68 -> pure I32Ctz
    0x69 -> pure I32Popcnt
    0x6A -> pure I32Add
    0x6B -> pure I32Sub
    0x6C -> pure I32Mul
    0x6D -> pure I32DivS
    0x6E -> pure I32DivU
    0x6F -> pure I32RemS
    0x70 -> pure I32RemU
    0x71 -> pure I32And
    0x72 -> pure I32Or
    0x73 -> pure I32Xor
    0x74 -> pure I32Shl
    0x75 -> pure I32ShrS
    0x76 -> pure I32ShrU
    0x77 -> pure I32RotL
    0x78 -> pure I32RotR
    0x79 -> pure I64Clz
    0x7A -> pure I64Ctz
    0x7B -> pure I64Popcnt
    0x7C -> pure I64Add
    0x7D -> pure I64Sub
    0x7E -> pure I64Mul
    0x7F -> pure I64DivS
    0x80 -> pure I64DivU
    0x81 -> pure I64RemS
    0x82 -> pure I64RemU
    0x83 -> pure I64And
    0x84 -> pure I64Or
    0x85 -> pure I64Xor
    0x86 -> pure I64Shl
    0x87 -> pure I64ShrS
    0x88 -> pure I64ShrU
    0x89 -> pure I64RotL
    0x8A -> pure I64RotR
    0x8B -> pure F32Abs
    0x8C -> pure F32Neg
    0x8D -> pure F32Ceil
    0x8E -> pure F32Floor
    0x8F -> pure F32Trunc
    0x90 -> pure F32Nearest
    0x91 -> pure F32Sqrt
    0x92 -> pure F32Add
    0x93 -> pure F32Sub
    0x94 -> pure F32Mul
    0x95 -> pure F32Div
    0x96 -> pure F32Min
    0x97 -> pure F32Max
    0x98 -> pure F32Copysign
    0x99 -> pure F64Abs
    0x9A -> pure F64Neg
    0x9B -> pure F64Ceil
    0x9C -> pure F64Floor
    0x9D -> pure F64Trunc
    0x9E -> pure F64Nearest
    0x9F -> pure F64Sqrt
    0xA0 -> pure F64Add
    0xA1 -> pure F64Sub
    0xA2 -> pure F64Mul
    0xA3 -> pure F64Div
    0xA4 -> pure F64Min
    0xA5 -> pure F64Max
    0xA6 -> pure F64Copysign
    0xA7 -> pure I32WrapFromI64
    0xA8 -> pure I32TruncSFromF32
    0xA9 -> pure I32TruncUFromF32
    0xAA -> pure I32TruncSFromF64
    0xAB -> pure I32TruncUFromF64
    0xAC -> pure I64ExtendSFromI32
    0xAD -> pure I64ExtendUFromI32
    0xAE -> pure I64TruncSFromF32
    0xAF -> pure I64TruncUFromF32
    0xB0 -> pure I64TruncSFromF64
    0xB1 -> pure I64TruncUFromF64
    0xB2 -> pure F32ConvertSFromI32
    0xB3 -> pure F32ConvertUFromI32
    0xB4 -> pure F32ConvertSFromI64
    0xB5 -> pure F32ConvertUFromI64
    0xB6 -> pure F32DemoteFromF64
    0xB7 -> pure F64ConvertSFromI32
    0xB8 -> pure F64ConvertUFromI32
    0xB9 -> pure F64ConvertSFromI64
    0xBA -> pure F64ConvertUFromI64
    0xBB -> pure F64PromoteFromF32
    0xBC -> pure I32ReinterpretFromF32
    0xBD -> pure I64ReinterpretFromF64
    0xBE -> pure F32ReinterpretFromI32
    0xBF -> pure F64ReinterpretFromI64
    _ -> fail "Language.WebAssembly.WireFormat.getInstruction"

-- | Serialize an 'Instruction'.
putInstruction :: Instruction -> Put
putInstruction instr = case instr of
  I32Eqz -> putWord8 0x45
  I64Eqz -> putWord8 0x50
  I32Clz -> putWord8 0x67
  I32Ctz -> putWord8 0x68
  I32Popcnt -> putWord8 0x69
  I64Clz -> putWord8 0x79
  I64Ctz -> putWord8 0x7A
  I64Popcnt -> putWord8 0x7B
  F32Abs -> putWord8 0x8B
  F32Neg -> putWord8 0x8C
  F32Ceil -> putWord8 0x8D
  F32Floor -> putWord8 0x8E
  F32Trunc -> putWord8 0x8F
  F32Nearest -> putWord8 0x90
  F32Sqrt -> putWord8 0x91
  F64Abs -> putWord8 0x99
  F64Neg -> putWord8 0x9A
  F64Ceil -> putWord8 0x9B
  F64Floor -> putWord8 0x9C
  F64Trunc -> putWord8 0x9D
  F64Nearest -> putWord8 0x9E
  F64Sqrt -> putWord8 0x9F
  I32WrapFromI64 -> putWord8 0xA7
  I32TruncSFromF32 -> putWord8 0xA8
  I32TruncUFromF32 -> putWord8 0xA9
  I32TruncSFromF64 -> putWord8 0xAA
  I32TruncUFromF64 -> putWord8 0xAB
  I64ExtendSFromI32 -> putWord8 0xAC
  I64ExtendUFromI32 -> putWord8 0xAD
  I64TruncSFromF32 -> putWord8 0xAE
  I64TruncUFromF32 -> putWord8 0xAF
  I64TruncSFromF64 -> putWord8 0xB0
  I64TruncUFromF64 -> putWord8 0xB1
  F32ConvertSFromI32 -> putWord8 0xB2
  F32ConvertUFromI32 -> putWord8 0xB3
  F32ConvertSFromI64 -> putWord8 0xB4
  F32ConvertUFromI64 -> putWord8 0xB5
  F32DemoteFromF64 -> putWord8 0xB6
  F64ConvertSFromI32 -> putWord8 0xB7
  F64ConvertUFromI32 -> putWord8 0xB8
  F64ConvertSFromI64 -> putWord8 0xB9
  F64ConvertUFromI64 -> putWord8 0xBA
  F64PromoteFromF32 -> putWord8 0xBB
  I32ReinterpretFromF32 -> putWord8 0xBC
  I64ReinterpretFromF64 -> putWord8 0xBD
  F32ReinterpretFromI32 -> putWord8 0xBE
  F64ReinterpretFromI64 -> putWord8 0xBF
  I32Eq -> putWord8 0x46
  I32Ne -> putWord8 0x47
  I32LtS -> putWord8 0x48
  I32LtU -> putWord8 0x49
  I32GtS -> putWord8 0x4A
  I32GtU -> putWord8 0x4B
  I32LeS -> putWord8 0x4C
  I32LeU -> putWord8 0x4D
  I32GeS -> putWord8 0x4E
  I32GeU -> putWord8 0x4F
  I64Eq -> putWord8 0x51
  I64Ne -> putWord8 0x52
  I64LtS -> putWord8 0x53
  I64LtU -> putWord8 0x54
  I64GtS -> putWord8 0x55
  I64GtU -> putWord8 0x56
  I64LeS -> putWord8 0x57
  I64LeU -> putWord8 0x58
  I64GeS -> putWord8 0x59
  I64GeU -> putWord8 0x5A
  F32Eq -> putWord8 0x5B
  F32Ne -> putWord8 0x5C
  F32Lt -> putWord8 0x5D
  F32Gt -> putWord8 0x5E
  F32Le -> putWord8 0x5F
  F32Ge -> putWord8 0x60
  F64Eq -> putWord8 0x61
  F64Ne -> putWord8 0x62
  F64Lt -> putWord8 0x63
  F64Gt -> putWord8 0x64
  F64Le -> putWord8 0x65
  F64Ge -> putWord8 0x66
  I32Add -> putWord8 0x6A
  I32Sub -> putWord8 0x6B
  I32Mul -> putWord8 0x6C
  I32DivS -> putWord8 0x6D
  I32DivU -> putWord8 0x6E
  I32RemS -> putWord8 0x6F
  I32RemU -> putWord8 0x70
  I32And -> putWord8 0x71
  I32Or -> putWord8 0x72
  I32Xor -> putWord8 0x73
  I32Shl -> putWord8 0x74
  I32ShrS -> putWord8 0x75
  I32ShrU -> putWord8 0x76
  I32RotL -> putWord8 0x77
  I32RotR -> putWord8 0x78
  I64Add -> putWord8 0x7C
  I64Sub -> putWord8 0x7D
  I64Mul -> putWord8 0x7E
  I64DivS -> putWord8 0x7F
  I64DivU -> putWord8 0x80
  I64RemS -> putWord8 0x81
  I64RemU -> putWord8 0x82
  I64And -> putWord8 0x83
  I64Or -> putWord8 0x84
  I64Xor -> putWord8 0x85
  I64Shl -> putWord8 0x86
  I64ShrS -> putWord8 0x87
  I64ShrU -> putWord8 0x88
  I64RotL -> putWord8 0x89
  I64RotR -> putWord8 0x8A
  F32Add -> putWord8 0x92
  F32Sub -> putWord8 0x93
  F32Mul -> putWord8 0x94
  F32Div -> putWord8 0x95
  F32Min -> putWord8 0x96
  F32Max -> putWord8 0x97
  F32Copysign -> putWord8 0x98
  F64Add -> putWord8 0xA0
  F64Sub -> putWord8 0xA1
  F64Mul -> putWord8 0xA2
  F64Div -> putWord8 0xA3
  F64Min -> putWord8 0xA4
  F64Max -> putWord8 0xA5
  F64Copysign -> putWord8 0xA6
  Unreachable -> putWord8 0x00
  Nop -> putWord8 0x01
  Block {..} -> do
    putWord8 0x02
    putResultType blockResultType
    putMany putInstruction blockInstructions
    putWord8 0x0B
  Loop {..} -> do
    putWord8 0x03
    putResultType loopResultType
    putMany putInstruction loopInstructions
    putWord8 0x0B
  If {..} -> do
    putWord8 0x04
    putResultType ifResultType
    putMany putInstruction thenInstructions
    case elseInstructions of
      Just _else_instrs -> do
        putWord8 0x05
        putMany putInstruction _else_instrs
      _ -> pure ()
    putWord8 0x0B
  Branch {..} -> do
    putWord8 0x0C
    putLabelIndex branchLabel
  BranchIf {..} -> do
    putWord8 0x0D
    putLabelIndex branchIfLabel
  BranchTable {..} -> do
    putWord8 0x0E
    putVec putLabelIndex branchTableLabels
    putLabelIndex branchTableFallbackLabel
  Return -> putWord8 0x0F
  Call {..} -> do
    putWord8 0x10
    putFunctionIndex callFunctionIndex
  CallIndirect {..} -> do
    putWord8 0x11
    putFunctionTypeIndex callIndirectFuctionTypeIndex
    putWord8 0x00
  ReturnCall {..} -> do
    putWord8 0x12
    putFunctionIndex returnCallFunctionIndex
  ReturnCallIndirect {..} -> do
    putWord8 0x13
    putFunctionTypeIndex returnCallIndirectFunctionTypeIndex
    putWord8 0x00
  Drop -> putWord8 0x1A
  Select -> putWord8 0x1B
  GetLocal {..} -> do
    putWord8 0x20
    putLocalIndex getLocalIndex
  SetLocal {..} -> do
    putWord8 0x21
    putLocalIndex setLocalIndex
  TeeLocal {..} -> do
    putWord8 0x22
    putLocalIndex teeLocalIndex
  GetGlobal {..} -> do
    putWord8 0x23
    putGlobalIndex getGlobalIndex
  SetGlobal {..} -> do
    putWord8 0x24
    putGlobalIndex setGlobalIndex
  I32Load {..} -> do
    putWord8 0x28
    putMemoryArgument i32LoadMemoryArgument
  I64Load {..} -> do
    putWord8 0x29
    putMemoryArgument i64LoadMemoryArgument
  F32Load {..} -> do
    putWord8 0x2A
    putMemoryArgument f32LoadMemoryArgument
  F64Load {..} -> do
    putWord8 0x2B
    putMemoryArgument f64LoadMemoryArgument
  I32Load8Signed {..} -> do
    putWord8 0x2C
    putMemoryArgument i32Load8SignedMemoryArgument
  I32Load8Unsigned {..} -> do
    putWord8 0x2D
    putMemoryArgument i32Load8UnsignedMemoryArgument
  I32Load16Signed {..} -> do
    putWord8 0x2E
    putMemoryArgument i32Load16SignedMemoryArument
  I32Load16Unsigned {..} -> do
    putWord8 0x2F
    putMemoryArgument i32Load16UnsignedMemoryArgument
  I64Load8Signed {..} -> do
    putWord8 0x30
    putMemoryArgument i64Load8SignedMemoryArgument
  I64Load8Unsigned {..} -> do
    putWord8 0x31
    putMemoryArgument i64Load8UnsignedMemoryArgument
  I64Load16Signed {..} -> do
    putWord8 0x32
    putMemoryArgument i64Load16SignedMemoryArgument
  I64Load16Unsigned {..} -> do
    putWord8 0x33
    putMemoryArgument i64Load16UnsignedMemoryArgument
  I64Load32Signed {..} -> do
    putWord8 0x34
    putMemoryArgument i64Load32SignedMemoryArgument
  I64Load32Unsigned {..} -> do
    putWord8 0x35
    putMemoryArgument i64Load32UnsignedMemoryArgument
  I32Store {..} -> do
    putWord8 0x36
    putMemoryArgument i32StoreMemoryArgument
  I64Store {..} -> do
    putWord8 0x37
    putMemoryArgument i64StoreMemoryArgument
  F32Store {..} -> do
    putWord8 0x38
    putMemoryArgument f32StoreMemoryArgument
  F64Store {..} -> do
    putWord8 0x39
    putMemoryArgument f64StoreMemoryArgument
  I32Store8 {..} -> do
    putWord8 0x3A
    putMemoryArgument i32Store8MemoryArgument
  I32Store16 {..} -> do
    putWord8 0x3B
    putMemoryArgument i32Store16MemoryArgument
  I64Store8 {..} -> do
    putWord8 0x3C
    putMemoryArgument i64Store8MemoryArgument
  I64Store16 {..} -> do
    putWord8 0x3D
    putMemoryArgument i64Store16MemoryArgument
  I64Store32 {..} -> do
    putWord8 0x3E
    putMemoryArgument i64Store32MemoryArgument
  MemorySize -> do
    putWord8 0x3F
    putWord8 0x00
  MemoryGrow -> do
    putWord8 0x40
    putWord8 0x00
  I32Const {..} -> do
    putWord8 0x41
    putVS32 i32ConstValue
  I64Const {..} -> do
    putWord8 0x42
    putVS64 i64ConstValue
  F32Const {..} -> do
    putWord8 0x43
    putF32 f32ConstValue
  F64Const {..} -> do
    putWord8 0x44
    putF64 f64ConstValue

-- | An 'Expression' is a sequence of 'Instruction's.
newtype Expression
  = Expression
      { instructions :: [Instruction]
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize an 'Expression'.
getExpression :: Get Expression
getExpression = coerce (getMany getInstruction) <* expectWord8 0x0B

-- | Serialize an 'Expression'.
putExpression :: Expression -> Put
putExpression expr = do
  putMany putInstruction $ coerce expr
  putWord8 0x0B

-- | 'Custom' captures the contents of a /custom section/. Custom sections are
-- intended to be used for debugging information or third-party extensions, and
-- are ignored by the WebAssembly semantics. Their contents consist of a name
-- further identifying the custom section, followed by an uninterpreted
-- sequence of bytes for custom use.
data Custom
  = Custom
      { customName :: Name,
        customContent :: SBS.ShortByteString
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'Name', and compute its length in serialized form.
getCustomName :: Get (Name, Word32)
getCustomName = do
  o0 <- bytesRead
  n <- getName
  o1 <- bytesRead
  pure (n, fromIntegral $ o1 - o0)

-- | (Function) type indices.
newtype FunctionTypeIndex
  = FunctionTypeIndex Word32
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'FunctionTypeIndex'.
getFunctionTypeIndex :: Get FunctionTypeIndex
getFunctionTypeIndex = coerce getVU32

-- | Serialize a 'FunctionTypeIndex'.
putFunctionTypeIndex :: FunctionTypeIndex -> Put
putFunctionTypeIndex = coerce putVU32

-- | Function indices.
newtype FunctionIndex
  = FunctionIndex Word32
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'FunctionIndex'.
getFunctionIndex :: Get FunctionIndex
getFunctionIndex = coerce getVU32

-- | Serialize a 'FunctionIndex'.
putFunctionIndex :: FunctionIndex -> Put
putFunctionIndex = coerce putVU32

-- | Table indices.
newtype TableIndex
  = TableIndex Word32
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'TableIndex'.
getTableIndex :: Get TableIndex
getTableIndex = coerce getVU32

-- | Serialize a 'TableIndex'.
putTableIndex :: TableIndex -> Put
putTableIndex = coerce putVU32

-- | Memory indices.
newtype MemoryIndex
  = MemoryIndex Word32
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'MemoryIndex'.
getMemoryIndex :: Get MemoryIndex
getMemoryIndex = coerce getVU32

-- | Serialize a 'MemoryIndex'.
putMemoryIndex :: MemoryIndex -> Put
putMemoryIndex = coerce putVU32

-- | Global indices.
newtype GlobalIndex
  = GlobalIndex Word32
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'GlobalIndex'.
getGlobalIndex' :: Get GlobalIndex
getGlobalIndex' = coerce getVU32

-- | Serialize a 'GlobalIndex'.
putGlobalIndex :: GlobalIndex -> Put
putGlobalIndex = coerce putVU32

-- | Local indices.
newtype LocalIndex
  = LocalIndex Word32
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'LocalIndex'.
getLocalIndex' :: Get LocalIndex
getLocalIndex' = coerce getVU32

-- | Serialize a 'LocalIndex'.
putLocalIndex :: LocalIndex -> Put
putLocalIndex = coerce putVU32

-- | Label indices.
newtype LabelIndex
  = LabelIndex Word32
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'LabelIndex'.
getLabelIndex :: Get LabelIndex
getLabelIndex = coerce getVU32

-- | Serialize a 'LabelIndex'.
putLabelIndex :: LabelIndex -> Put
putLabelIndex = coerce putVU32

-- | An 'ImportDescription' specifies what is imported. Importable definitions
-- include functions, tables, memories, and globals.
data ImportDescription
  = ImportFunction FunctionTypeIndex
  | ImportTable TableType
  | ImportMemory MemoryType
  | ImportGlobal GlobalType
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize an 'ImportDescription'.
getImportDescription :: Get ImportDescription
getImportDescription = do
  b <- getWord8
  case b of
    0x00 -> ImportFunction <$> getFunctionTypeIndex
    0x01 -> ImportTable <$> getTableType
    0x02 -> ImportMemory <$> getMemoryType
    0x03 -> ImportGlobal <$> getGlobalType
    _ -> fail "Language.WebAssembly.WireFormat.getImportDescription"

-- | Serialize an 'ImportDescription'.
putImportDescription :: ImportDescription -> Put
putImportDescription desc = case desc of
  ImportFunction x -> do
    putWord8 0x00
    putFunctionTypeIndex x
  ImportTable tt -> do
    putWord8 0x01
    putTableType tt
  ImportMemory mt -> do
    putWord8 0x02
    putMemoryType mt
  ImportGlobal gt -> do
    putWord8 0x03
    putGlobalType gt

-- | The imports component of a module defines a set of imports that are
-- required for instantiation. It is labeled by a two-level namespace,
-- consisting of a module-name and a name for an entity within that module.
data Import
  = Import
      { moduleName, importName :: Name,
        importDescription :: ImportDescription
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize an 'Import'.
getImport :: Get Import
getImport = Import <$> getName <*> getName <*> getImportDescription

-- | Serialize an 'Import'.
putImport :: Import -> Put
putImport Import {..} = do
  putName moduleName
  putName importName
  putImportDescription importDescription

-- | A 'Table' is a vector of opaque values of a particular 'TableType'. The
-- min size in the limits of the table type specifies the initial size of that
-- table, while its max, if present, restricts the size to which it can grow
-- later.
newtype Table
  = Table
      { tableType :: TableType
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'Table'.
getTable :: Get Table
getTable = coerce getTableType

-- | Serialize a 'Table'.
putTable :: Table -> Put
putTable = coerce putTableType

-- | A 'Memory' is a vector of raw uninterpreted bytes. The min size in the
-- limits of the memory type specifies the initial size of that memory, while
-- its max, if present, restricts the size to which it can grow later.
newtype Memory
  = Memory
      { memoryType :: MemoryType
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'Memory'.
getMemory :: Get Memory
getMemory = coerce getMemoryType

-- | Serialize a 'Memory'.
putMemory :: Memory -> Put
putMemory = coerce putMemoryType

-- | A 'Global' captures a single global variable. Each 'Global' stores a
-- single value of the given global type.  Moreover, each 'Global' is
-- initialized with an initial value, given by a constant initializer
-- expression.
data Global
  = Global
      { globalType :: GlobalType,
        globalInitialValue :: Expression
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'Global'.
getGlobal :: Get Global
getGlobal = Global <$> getGlobalType <*> getExpression

-- | Serialize a 'Global'.
putGlobal :: Global -> Put
putGlobal Global {..} = do
  putGlobalType globalType
  putExpression globalInitialValue

-- | An 'ExportDescription' specifies what is being exported. Exportable
-- definitions include functions, tables, memories, and globals.
data ExportDescription
  = ExportFunction FunctionIndex
  | ExportTable TableIndex
  | ExportMemory MemoryIndex
  | ExportGlobal GlobalIndex
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize an 'ExportDescription'.
getExportDescription :: Get ExportDescription
getExportDescription = do
  b <- getWord8
  case b of
    0x00 -> ExportFunction <$> getFunctionIndex
    0x01 -> ExportTable <$> getTableIndex
    0x02 -> ExportMemory <$> getMemoryIndex
    0x03 -> ExportGlobal <$> getGlobalIndex'
    _ -> fail "Language.WebAssembly.WireFormat.getExportDescription"

-- | Serialize an 'ExportDescription'.
putExportDescription :: ExportDescription -> Put
putExportDescription d = case d of
  ExportFunction x -> do
    putWord8 0x00
    putFunctionIndex x
  ExportTable x -> do
    putWord8 0x01
    putTableIndex x
  ExportMemory x -> do
    putWord8 0x02
    putMemoryIndex x
  ExportGlobal x -> do
    putWord8 0x03
    putGlobalIndex x

-- | The exports component of a module defines a set of exports that become
-- accessible to the host environment once the module has been instantiated.
data Export
  = Export
      { exportName :: Name,
        exportDescription :: ExportDescription
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize an 'Export'.
getExport :: Get Export
getExport = Export <$> getName <*> getExportDescription

-- | Serialize an 'Export'.
putExport :: Export -> Put
putExport Export {..} = do
  putName exportName
  putExportDescription exportDescription

-- | Element segments. The initial contents of a table is uninitialized.
-- 'Element' captures the elem component of a module, defines a vector of
-- element segments that initialize a subrange of a table, at a given offset,
-- from a static vector of elements. The offset is given by a constant
-- expression.
data Element
  = Element
      { tableIndex :: TableIndex,
        tableOffset :: Expression,
        tableInitialValues :: [FunctionIndex]
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize an 'Element'.
getElement :: Get Element
getElement =
  Element <$> getTableIndex <*> getExpression <*> getVec getFunctionIndex

-- | Serialize an 'Element'.
putElement :: Element -> Put
putElement Element {..} = do
  putTableIndex tableIndex
  putExpression tableOffset
  putVec putFunctionIndex tableInitialValues

-- | 'Locals' captures (mutable) function parameters and their types. They are
-- meant to be referenced by functions' bodies through 0-based local indices.
data Locals
  = Locals
      { localsCount :: Word32,
        localsType :: ValueType
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'Locals' value.
getLocals :: Get Locals
getLocals = Locals <$> getVU32 <*> getValueType

-- | Serialize a 'Locals' value.
putLocals :: Locals -> Put
putLocals Locals {..} = do
  putVU32 localsCount
  putValueType localsType

-- | 'Function's.
data Function
  = Function
      { functionLocals :: [Locals],  -- ^ (Mutable) function parameters.
        functionBody :: Expression   -- ^ Function body.
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'Function'.
getFunction :: Get Function
getFunction = Function <$> getVec getLocals <*> getExpression

-- | Serialize a 'Function'.
putFunction :: Function -> Put
putFunction Function {..} = do
  putVec putLocals functionLocals
  putExpression functionBody

-- | A data segment. The initial contents of a memory are zero-valued bytes.
-- 'DataSegment' captures the data component of a module, which defines a
-- vector of data segments that initialize a range of memory, at a given
-- offset, with a static vector of bytes. The offset is given by a constant
-- expression.
data DataSegment
  = DataSegment
      { memoryIndex :: MemoryIndex,
        memoryOffset :: Expression,
        memoryInitialBytes :: SBS.ShortByteString
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'DataSegment'.
getDataSegment :: Get DataSegment
getDataSegment = DataSegment <$> getMemoryIndex <*> getExpression <*> getVecSBS

-- | Serialize a 'DataSegment'.
putDataSegment :: DataSegment -> Put
putDataSegment DataSegment {..} = do
  putMemoryIndex memoryIndex
  putExpression memoryOffset
  putVecSBS memoryInitialBytes

-- | Currently unused. ToDo: Remove.
data LinkingSymbolFlags
  = LinkingSymbolFlags
      { linkingWasmSymBindingWeak, linkingWasmSymBindingLocal, linkingWasmSymVisibilityHidden, linkingWasmSymUndefined :: Bool
      }
  deriving (Eq, Generic, Ord, Show)

-- | Currently unused. ToDo: Remove.
getLinkingSymbolFlags :: Get LinkingSymbolFlags
getLinkingSymbolFlags = do
  f <- getVU32
  pure LinkingSymbolFlags
    { linkingWasmSymBindingWeak = testBit f 0,
      linkingWasmSymBindingLocal = testBit f 1,
      linkingWasmSymVisibilityHidden = testBit f 2,
      linkingWasmSymUndefined = testBit f 4
    }

-- | Currently unused. ToDo: Remove.
putLinkingSymbolFlags :: LinkingSymbolFlags -> Put
putLinkingSymbolFlags LinkingSymbolFlags {..} =
  putVU32
    $ (if linkingWasmSymUndefined then flip setBit 4 else id)
    $ (if linkingWasmSymVisibilityHidden then flip setBit 2 else id)
    $ (if linkingWasmSymBindingLocal then flip setBit 1 else id)
    $ (if linkingWasmSymBindingWeak then flip setBit 0 else id) 0

-- | Currently unused. ToDo: Remove.
data LinkingSymbolInfo
  = LinkingFunctionSymbolInfo
      { linkingFunctionSymbolFlags :: LinkingSymbolFlags,
        linkingFunctionSymbolIndex :: Word32,
        linkingFunctionSymbolName :: Maybe Name
      }
  | LinkingDataSymbolInfo
      { linkingDataSymbolFlags :: LinkingSymbolFlags,
        linkingDataSymbolName :: Name,
        linkingDataSymbolIndex, linkingDataSymbolOffset, linkingDataSymbolSize :: Maybe Word32
      }
  | LinkingGlobalSymbolInfo
      { linkingGlobalSymbolFlags :: LinkingSymbolFlags,
        linkingGlobalSymbolIndex :: Word32,
        linkingGlobalSymbolName :: Maybe Name
      }
  | LinkingSectionSymbolInfo
      { linkingSectionSymbolFlags :: LinkingSymbolFlags,
        linkingSectionSymbolIndex :: Word32
      }
  deriving (Eq, Generic, Ord, Show)

-- | Currently unused. ToDo: Remove.
getLinkingSymbolInfo :: Get LinkingSymbolInfo
getLinkingSymbolInfo = do
  _sym_kind <- getWord8
  _sym_flags@LinkingSymbolFlags {..} <- getLinkingSymbolFlags
  case _sym_kind of
    0 ->
      if linkingWasmSymUndefined
        then LinkingFunctionSymbolInfo _sym_flags <$> getVU32 <*> pure Nothing
        else LinkingFunctionSymbolInfo _sym_flags <$> getVU32 <*> fmap Just getName
    1 ->
      if linkingWasmSymUndefined
        then
          LinkingDataSymbolInfo _sym_flags
            <$> getName
            <*> pure Nothing
            <*> pure Nothing
            <*> pure Nothing
        else
          LinkingDataSymbolInfo _sym_flags
            <$> getName
            <*> fmap Just getVU32
            <*> fmap Just getVU32
            <*> fmap Just getVU32
    2 ->
      if linkingWasmSymUndefined
        then LinkingGlobalSymbolInfo _sym_flags <$> getVU32 <*> pure Nothing
        else LinkingGlobalSymbolInfo _sym_flags <$> getVU32 <*> fmap Just getName
    3 -> LinkingSectionSymbolInfo _sym_flags <$> getVU32
    _ -> fail "Language.WebAssembly.WireFormat.getLinkingSymbolInfo"

-- | Currently unused. ToDo: Remove.
putLinkingSymbolInfo :: LinkingSymbolInfo -> Put
putLinkingSymbolInfo sym_info = case sym_info of
  LinkingFunctionSymbolInfo {..} -> do
    putWord8 0
    putLinkingSymbolFlags linkingFunctionSymbolFlags
    putVU32 linkingFunctionSymbolIndex
    putMaybe putName linkingFunctionSymbolName
  LinkingDataSymbolInfo {..} -> do
    putWord8 1
    putLinkingSymbolFlags linkingDataSymbolFlags
    putName linkingDataSymbolName
    putMaybe putVU32 linkingDataSymbolIndex
    putMaybe putVU32 linkingDataSymbolOffset
    putMaybe putVU32 linkingDataSymbolSize
  LinkingGlobalSymbolInfo {..} -> do
    putWord8 2
    putLinkingSymbolFlags linkingGlobalSymbolFlags
    putVU32 linkingGlobalSymbolIndex
    putMaybe putName linkingGlobalSymbolName
  LinkingSectionSymbolInfo {..} -> do
    putWord8 3
    putLinkingSymbolFlags linkingSectionSymbolFlags
    putVU32 linkingSectionSymbolIndex

-- | Currently unused. ToDo: Remove.
data LinkingSubSection
  = LinkingWasmSegmentInfo
      { linkingWasmSegmentInfoPayload :: SBS.ShortByteString
      }
  | LinkingWasmInitFuncs
      { linkingWasmInitFuncsPayload :: SBS.ShortByteString
      }
  | LinkingWasmComdatInfo
      { linkingWasmComdatInfoPayload :: SBS.ShortByteString
      }
  | LinkingWasmSymbolTable
      { linkingWasmSymbolTable :: SBS.ShortByteString
      }
  deriving (Eq, Generic, Ord, Show)

-- | Currently unused. ToDo: Remove.
getLinkingSubSection :: Get LinkingSubSection
getLinkingSubSection = do
  b <- getWord8
  case b of
    5 -> LinkingWasmSegmentInfo <$> getVecSBS
    6 -> LinkingWasmInitFuncs <$> getVecSBS
    7 -> LinkingWasmComdatInfo <$> getVecSBS
    8 -> LinkingWasmSymbolTable <$> getVecSBS
    _ -> fail "Language.WebAssembly.WireFormat.getLinkingSubSection"

-- | Currently unused. ToDo: Remove.
putLinkingSubSection :: LinkingSubSection -> Put
putLinkingSubSection sec = case sec of
  LinkingWasmSegmentInfo {..} -> do
    putWord8 5
    putVecSBS linkingWasmSegmentInfoPayload
  LinkingWasmInitFuncs {..} -> do
    putWord8 6
    putVecSBS linkingWasmInitFuncsPayload
  LinkingWasmComdatInfo {..} -> do
    putWord8 7
    putVecSBS linkingWasmComdatInfoPayload
  LinkingWasmSymbolTable {..} -> do
    putWord8 8
    putVecSBS linkingWasmSymbolTable

-- | Currently unused. ToDo: Remove.
data RelocationType
  = RWebAssemblyFunctionIndexLEB
  | RWebAssemblyTableIndexSLEB
  | RWebAssemblyTableIndexI32
  | RWebAssemblyMemoryAddrLEB
  | RWebAssemblyMemoryAddrSLEB
  | RWebAssemblyMemoryAddrI32
  | RWebAssemblyTypeIndexLEB
  | RWebAssemblyGlobalIndexLEB
  | RWebAssemblyFunctionOffsetI32
  | RWebAssemblySectionOffsetI32
  deriving (Eq, Generic, Ord, Show)

-- | Currently unused. ToDo: Remove.
data RelocationEntry
  = RelocationEntry
      { relocationType :: RelocationType,
        relocationOffset, relocationIndex :: Word32,
        relocationAddEnd :: Maybe Word32
      }
  deriving (Eq, Generic, Ord, Show)

-- | All sorts of 'Section's that can be found in a module.
data Section
  = -- | Custom section (currently unused). ToDo: Remove.
    LinkingSection
      { linkingSectionVersion :: Word32,
        linkingSubSections :: [LinkingSubSection]
      }
    -- | Custom section (currently unused). ToDo: Remove.
  | RelocationSection
      { relocationSectionName :: Name,
        relocationSectionIndex :: Word32,
        relocationEntries :: [RelocationEntry]
      }
    -- | A custom section (see 'Custom').
  | CustomSection
      { custom :: Custom
      }
    -- | All the function types used in a module.
    -- They are referenced by type indices.
  | TypeSection
      { types :: [FunctionType]
      }
    -- | All the 'Import's of a module.
  | ImportSection
      { imports :: [Import]
      }
    -- | A vector of type indices, capturing the type fields of the functions
    -- of a module. The actual function definitions are captured separately in
    -- the code section (see 'CodeSection' below).
  | FunctionSection
      { functionTypeIndices :: [FunctionTypeIndex]
      }
    -- | All the 'Table's of a module.
  | TableSection
      { tables :: [Table]
      }
    -- | All the memories of a module.
  | MemorySection
      { memories :: [Memory]
      }
    -- | All the global variables of a module.
  | GlobalSection
      { globals :: [Global]
      }
    -- | All the 'Export's of a module.
  | ExportSection
      { exports :: [Export]
      }
    -- | The function index of the start function (i.e., the function that is
    -- automatically invoked when the module is instantiated, after tables and
    -- memories have been initialized).
  | StartSection
      { startFunctionIndex :: FunctionIndex
      }
    -- | All the 'Element's of a module.
  | ElementSection
      { elements :: [Element]
      }
    -- | All the 'Function's of a module.
  | CodeSection
      { functions' :: [Function]
      }
    -- | All the data segments of a module.
  | DataSection
      { dataSegments :: [DataSegment]
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'Section'.
getSection :: Get Section
getSection = do
  b <- getWord8
  case b of
    0 -> do
      _sec_len <- getVU32
      (_sec_name, _name_len) <- getCustomName
      let _payload_len = _sec_len - _name_len
      isolate (fromIntegral _payload_len) $
        if _sec_name == Name "linking"
          then LinkingSection <$> getVU32 <*> getMany getLinkingSubSection
          else
            if "reloc." `BS.isPrefixOf` SBS.fromShort (coerce _sec_name)
              then
                RelocationSection
                  ( Name $ SBS.toShort $ BS.drop 6 $ SBS.fromShort $ coerce _sec_name
                  )
                  <$> getVU32
                  <*> getVec
                    ( do
                        _reloc_type_tag <- getWord8
                        _reloc_type <- case _reloc_type_tag of
                          0 -> pure RWebAssemblyFunctionIndexLEB
                          1 -> pure RWebAssemblyTableIndexSLEB
                          2 -> pure RWebAssemblyTableIndexI32
                          3 -> pure RWebAssemblyMemoryAddrLEB
                          4 -> pure RWebAssemblyMemoryAddrSLEB
                          5 -> pure RWebAssemblyMemoryAddrI32
                          6 -> pure RWebAssemblyTypeIndexLEB
                          7 -> pure RWebAssemblyGlobalIndexLEB
                          8 -> pure RWebAssemblyFunctionOffsetI32
                          9 -> pure RWebAssemblySectionOffsetI32
                          _ ->
                            fail "Language.WebAssembly.WireFormat.getRelocationType"
                        _reloc_offset <- getVU32
                        _reloc_index <- getVU32
                        _reloc_addend <-
                          if _reloc_type
                            `elem` [ RWebAssemblyMemoryAddrLEB,
                                     RWebAssemblyMemoryAddrSLEB,
                                     RWebAssemblyMemoryAddrI32,
                                     RWebAssemblyFunctionOffsetI32,
                                     RWebAssemblySectionOffsetI32
                                   ]
                            then Just <$> getVU32
                            else pure Nothing
                        pure $
                          RelocationEntry
                            _reloc_type
                            _reloc_offset
                            _reloc_index
                            _reloc_addend
                    )
              else
                CustomSection . Custom _sec_name . SBS.toShort
                  <$> getByteString
                    (fromIntegral _payload_len)
    1 -> getCheckedRegion (TypeSection <$> getVec getFunctionType)
    2 -> getCheckedRegion (ImportSection <$> getVec getImport)
    3 -> getCheckedRegion (FunctionSection <$> getVec getFunctionTypeIndex)
    4 -> getCheckedRegion (TableSection <$> getVec getTable)
    5 -> getCheckedRegion (MemorySection <$> getVec getMemory)
    6 -> getCheckedRegion (GlobalSection <$> getVec getGlobal)
    7 -> getCheckedRegion (ExportSection <$> getVec getExport)
    8 -> getCheckedRegion (StartSection <$> getFunctionIndex)
    9 -> getCheckedRegion (ElementSection <$> getVec getElement)
    10 ->
      getCheckedRegion (CodeSection <$> getVec (getCheckedRegion getFunction))
    11 -> getCheckedRegion (DataSection <$> getVec getDataSegment)
    _ -> fail "Language.WebAssembly.WireFormat.getSection"

-- | Serialize a 'Section'.
putSection :: Section -> Put
putSection sec = case sec of
  LinkingSection {..} -> do
    putWord8 0
    putWithLength $ do
      putName $ Name "linking"
      putVU32 linkingSectionVersion
      putMany putLinkingSubSection linkingSubSections
  RelocationSection {..} -> do
    putWord8 0
    putWithLength $ do
      putName $ Name $ "reloc." <> coerce relocationSectionName
      putVU32 relocationSectionIndex
      flip putVec relocationEntries $ \RelocationEntry {..} -> do
        putWord8 $ case relocationType of
          RWebAssemblyFunctionIndexLEB -> 0
          RWebAssemblyTableIndexSLEB -> 1
          RWebAssemblyTableIndexI32 -> 2
          RWebAssemblyMemoryAddrLEB -> 3
          RWebAssemblyMemoryAddrSLEB -> 4
          RWebAssemblyMemoryAddrI32 -> 5
          RWebAssemblyTypeIndexLEB -> 6
          RWebAssemblyGlobalIndexLEB -> 7
          RWebAssemblyFunctionOffsetI32 -> 8
          RWebAssemblySectionOffsetI32 -> 9
        putVU32 relocationOffset
        putVU32 relocationIndex
        putMaybe putVU32 relocationAddEnd
  CustomSection {custom = Custom {..}} -> do
    putWord8 0
    putWithLength $ do
      putName customName
      putSBS customContent
  TypeSection {..} -> do
    putWord8 1
    putWithLength $ putVec putFunctionType types
  ImportSection {..} -> do
    putWord8 2
    putWithLength $ putVec putImport imports
  FunctionSection {..} -> do
    putWord8 3
    putWithLength $ putVec putFunctionTypeIndex functionTypeIndices
  TableSection {..} -> do
    putWord8 4
    putWithLength $ putVec putTable tables
  MemorySection {..} -> do
    putWord8 5
    putWithLength $ putVec putMemory memories
  GlobalSection {..} -> do
    putWord8 6
    putWithLength $ putVec putGlobal globals
  ExportSection {..} -> do
    putWord8 7
    putWithLength $ putVec putExport exports
  StartSection {..} -> do
    putWord8 8
    putWithLength $ putFunctionIndex startFunctionIndex
  ElementSection {..} -> do
    putWord8 9
    putWithLength $ putVec putElement elements
  CodeSection {..} -> do
    putWord8 10
    putWithLength $ putVec (putWithLength . putFunction) functions'
  DataSection {..} -> do
    putWord8 11
    putWithLength $ putVec putDataSegment dataSegments

-- | A 'Module' is a list of 'Section's.
newtype Module
  = Module
      { sections :: [Section]
      }
  deriving (Eq, Generic, Ord, Show)

-- | Deserialize a 'Module'.
getModule :: Get Module
getModule = do
  for_ [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00] expectWord8
  Module <$> getMany getSection

-- | Serialize a 'Module'.
putModule :: Module -> Put
putModule Module {..} = do
  putSBS $ SBS.pack [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00]
  putMany putSection sections

-- | Deserialize a given 'Word8' or fail.
expectWord8 :: Word8 -> Get ()
expectWord8 x = do
  b <- getWord8
  unless (b == x)
    $ fail
    $ "Language.WebAssembly.WireFormat.expectWord8: expected "
      <> show x
      <> ", but got "
      <> show b

-- | Deserialize a variable-length unsigned integer of a given length (given in
-- bits). @getVUN n@ fails if @n@ is non-positive.
getVUN :: Int -> Get Word64
getVUN n
  | n <= 0 = fail "Language.WebAssembly.WireFormat.getVUN"
  | otherwise = do
    b <- getWord8
    let x = fromIntegral $ b .&. 0x7F
    if b .&. 0x80 == 0
      then pure x
      else do
        r <- getVUN (n - 7)
        pure $ x .|. (r `shiftL` 7)

-- | Deserialize a variable-length signed integer of a given length (given in
-- bits). @getVSN n@ fails if @n@ is non-positive.
getVSN :: Int -> Get Int64
getVSN n
  | n <= 0 = fail "Language.WebAssembly.WireFormat.getVSN"
  | otherwise = do
    b <- getWord8
    let x = fromIntegral $ b .&. 0x7F
    if b .&. 0x80 == 0
      then pure $ if b .&. 0x40 == 0 then x else x .|. ((-1) `xor` 0x7F)
      else do
        r <- getVSN (n - 7)
        pure $ x .|. r `shiftL` 7

-- | Serialize an unsigned 64-bit integer using the variable-length LEB128
-- encoding.
putVU64 :: Word64 -> Put
putVU64 i = do
  let b = fromIntegral $ i .&. 0x7F
  if 0 <= i && i < 128
    then putWord8 b
    else do
      putWord8 $ b .|. 0x80
      putVU64 $ i `shiftR` 7

-- | Serialize a signed 64-bit integer using the variable-length LEB128
-- encoding.
putVS64 :: Int64 -> Put
putVS64 i = do
  let b = fromIntegral $ i .&. 0x7F
  if -64 <= i && i < 64
    then putWord8 b
    else do
      putWord8 $ b .|. 0x80
      putVS64 $ i `shiftR` 7

-- | Deserialize an unsigned 32-bit integer using the variable-length LEB128
-- encoding.
getVU32 :: Get Word32
getVU32 = fromIntegral <$> getVUN 32

-- | Serialize an unsigned 32-bit integer using the variable-length LEB128
-- encoding.
putVU32 :: Word32 -> Put
putVU32 = putVU64 . fromIntegral

-- | Deserialize a signed 32-bit integer using the variable-length LEB128
-- encoding.
getVS32 :: Get Int32
getVS32 = fromIntegral <$> getVSN 64

-- | Serialize a signed 32-bit integer using the variable-length LEB128
-- encoding.
putVS32 :: Int32 -> Put
putVS32 = putVS64 . fromIntegral

-- | Deserialize a signed 64-bit integer using the variable-length LEB128
-- encoding.
getVS64 :: Get Int64
getVS64 = getVSN 64

-- | Deserialize a 'Float' in native in IEEE-754 format and host endian.
getF32 :: Get Float
getF32 = getFloathost

-- | Serialize a 'Float' in native in IEEE-754 format and host endian.
putF32 :: Float -> Put
putF32 = putFloathost

-- | Deserialize a 'Double' in IEEE-754 format and host endian.
getF64 :: Get Double
getF64 = getDoublehost

-- | Serialize a 'Double' in IEEE-754 format and host endian.
putF64 :: Double -> Put
putF64 = putDoublehost

-- | Deserialize a vector (unsigned 32-bit encoding of length followed by the
-- serialization of all elements).
getVec :: Get a -> Get [a]
getVec g = do
  n <- getVU32
  replicateM (fromIntegral n) g

-- | Serialize a vector (unsigned 32-bit encoding of length followed by the
-- serialization of all elements).
putVec :: (a -> Put) -> [a] -> Put
putVec p v = do
  putVU32 (fromIntegral (length v))
  for_ v p

-- | Deserialize zero or more elements.
getMany :: Get a -> Get [a]
getMany = many

-- | Serialize zero or more elements.
putMany :: (a -> Put) -> [a] -> Put
putMany = traverse_

-- | Serialize a value of type @'Maybe' a@,
-- given a serialization function for @a@.
putMaybe :: (a -> Put) -> Maybe a -> Put
putMaybe = traverse_

-- | Serialize a 'SBS.ShortByteString'.
putSBS :: SBS.ShortByteString -> Put
putSBS = putShortByteString

-- | Deserialize a 'SBS.ShortByteString' using the byte-vector format (unsigned
-- 32-bit encoding of length followed by the serialization of all elements).
getVecSBS :: Get SBS.ShortByteString
getVecSBS = do
  l <- getVU32
  SBS.toShort <$> getByteString (fromIntegral l)

-- | Serialize a 'SBS.ShortByteString' using the byte-vector format (unsigned
-- 32-bit encoding of length followed by the serialization of all elements).
putVecSBS :: SBS.ShortByteString -> Put
putVecSBS s = do
  putVU32 $ fromIntegral $ SBS.length s
  putSBS s

-- | Prefix serialization with length (unsigned 32-bit encoding).
putWithLength :: Put -> Put
putWithLength p = do
  let buf = runPut p
  putVU32 $ fromIntegral $ LBS.length buf
  putLazyByteString buf

-- | Deserialize a length-prefixed (unsigned 32-bit encoding) entity. Used for
-- deserializing sections (see "Section 5.5.2 Sections" in the WebAssembly
-- Specification, Release 1.0).
getCheckedRegion :: Get a -> Get a
getCheckedRegion g = do
  l <- fromIntegral <$> getVU32
  isolate l g
