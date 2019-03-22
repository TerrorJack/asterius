{-# LANGUAGE StrictData #-}

module Asterius.Passes.Common
  ( PassesState(..)
  , defaultPassesState
  ) where

import Asterius.Types
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map

data PassesState = PassesState
  { localRegMap :: Map UnresolvedLocalReg Int
  , localRegStack :: [ValueType]
  , eventMap :: Map Event Int
  , eventStack :: [Event]
  }

defaultPassesState :: PassesState
defaultPassesState =
  PassesState
    { localRegMap = Map.empty
    , localRegStack = []
    , eventMap = Map.empty
    , eventStack = []
    }
