-----------------------------------------------------------------------------
-- |
-- Module      :  Asterius.BuildInfo
-- Copyright   :  (c) 2018 EURL Tweag
-- License     :  All rights reserved (see LICENCE file in the distribution).
--
-- Paths for data and binary files.
--
-----------------------------------------------------------------------------

module Asterius.BuildInfo
  ( ahc,
    ahcPkg,
    ahcLd,
    ahcDist,
    setupGhcPrim,
    unlit,
    dataDir,
    ahcLibDir,
  )
where

import qualified Paths_asterius
import System.Environment
import System.Directory
import System.FilePath
import System.IO.Unsafe

getDataDirFromEnv = do
  e <- getEnvironment
  let l = [(k, v) | (k, v) <- e, k == "ASTERIUS_DATA_DIR"]
  case l of
   [] -> do
     datadir <- Paths_asterius.getDataDir
     pure datadir
   [(_, datadir)] ->
     pure datadir
  

{-# NOINLINE binDir #-}
binDir :: FilePath
binDir = unsafePerformIO Paths_asterius.getBinDir

{-# NOINLINE dataDir #-}
dataDir :: FilePath
--dataDir = unsafePerformIO Paths_asterius.getDataDir
dataDir = unsafePerformIO getDataDirFromEnv

ahc :: FilePath
ahc = binDir </> "ahc" <.> exeExtension

ahcPkg :: FilePath
ahcPkg = binDir </> "ahc-pkg" <.> exeExtension

ahcLd :: FilePath
ahcLd = binDir </> "ahc-ld" <.> exeExtension

ahcDist :: FilePath
ahcDist = binDir </> "ahc-dist" <.> exeExtension

setupGhcPrim :: FilePath
setupGhcPrim = binDir </> "Setup-ghc-prim" <.> exeExtension

unlit :: FilePath
unlit = binDir </> "unlit" <.> exeExtension

ahcLibDir :: FilePath
ahcLibDir = dataDir </> ".boot" </> "asterius_lib"
