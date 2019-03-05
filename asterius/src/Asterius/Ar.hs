{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Asterius.Ar
  ( loadAr
  ) where

import qualified Ar as GHC
import Asterius.Internals
import Asterius.Types
import Data.Binary
import qualified Data.ByteString.Lazy as LBS
import Data.List
import Prelude hiding (IO)

loadAr :: FilePath -> IO AsteriusModule
loadAr p = do
  GHC.Archive entries <- GHC.loadAr p
  let Just mod_entry = find (("MODULE" `isPrefixOf`) . GHC.filename) entries
  pure $ decode $ LBS.fromStrict $ GHC.filedata mod_entry
