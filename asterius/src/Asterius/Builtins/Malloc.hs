{-# LANGUAGE OverloadedStrings #-}

-- |
-- Module      :  Asterius.Builtins.Malloc
-- Copyright   :  (c) 2018 EURL Tweag
-- License     :  All rights reserved (see LICENCE file in the distribution).
--
-- Wasm implementations of @malloc@, @calloc@, and @free@. This implementation of
-- @malloc@/@free@ allocates one pinned @ByteArray#@ for each @malloc@ call,
-- sets up a @StablePtr#@ for the @ByteArray#@ closure, and stores the
-- @StablePtr#@ in the payload's first word. Hence, the available space as the
-- result of @malloc@ starts from the second word of the payload. Conversely,
-- @free@ fetches the @StablePtr#@, subtracts the size of a word (to account
-- for the additional first word), and and frees it, so that the garbage
-- collector can later recycle the space taken by the @ByteArray#@.
module Asterius.Builtins.Malloc
  ( mallocCBits,
  )
where

import Asterius.EDSL
import Asterius.Types
import Language.Haskell.GHC.Toolkit.Constants

mallocCBits :: AsteriusModule
mallocCBits = malloc <> calloc <> free

malloc :: AsteriusModule
malloc = runEDSL "malloc" $ do
  setReturnTypes [I64]
  n <- param I64
  c <-
    call'
      "allocatePinned"
      [ mainCapability,
        roundupBytesToWords $
          constI64 (sizeof_StgArrBytes + 8)
            `addInt64` n
      ]
      I64
  storeI64 c 0 $ symbol "stg_ARR_WORDS_info"
  storeI64 c offset_StgArrBytes_bytes $ constI64 8 `addInt64` n
  sp <- call' "getStablePtr" [c] I64
  storeI64 c offset_StgArrBytes_payload sp
  emit $ c `addInt64` constI64 (offset_StgArrBytes_payload + 8)

calloc :: AsteriusModule
calloc = runEDSL "calloc" $ do
  setReturnTypes [I64]
  [n, size] <- params [I64, I64]
  c <- call' "malloc" [n `mulInt64` size] I64
  call' "memset" [c, constI64 0, n `mulInt64` size] I64 >>= emit

free :: AsteriusModule
free = runEDSL "free" $ do
  p <- param I64
  call "freeStablePtr" [loadI64 (p `subInt64` constI64 8) 0]

roundupBytesToWords :: Expression -> Expression
roundupBytesToWords n =
  (n `addInt64` constI64 7) `divUInt64` constI64 8
