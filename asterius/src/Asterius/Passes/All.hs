{-# LANGUAGE RankNTypes #-}

module Asterius.Passes.All
  ( allPasses
  ) where

import Asterius.Internals.SYB
import Asterius.Passes.Common
import Asterius.Passes.GlobalRegs
import Asterius.Passes.LocalRegs
import Asterius.Passes.Relooper
import Asterius.Passes.ResolveSymbols
import Asterius.Types
import Control.Monad.State.Strict
import Data.Data (Data)
import Data.Int
import Data.Map.Strict (Map)

allPasses ::
     Data a
  => Bool
  -> Map AsteriusEntitySymbol Int64
  -> FunctionType
  -> a
  -> (a, [ValueType])
allPasses debug sym_map ft t = (result, localRegTable ps)
  where
    (result, ps) = runState (pipeline t) defaultPassesState
    pipeline =
      everywhereM $
      relooperShallow <=<
      resolveLocalRegs ft <=< resolveSymbols sym_map <=< resolveGlobalRegs
