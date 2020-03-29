{-# LANGUAGE MagicHash #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE UnliftedFFITypes #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Asterius.TopHandler
  ( runIO,
    runNonIO,
    reportException,
  )
where

import Asterius.Types.JSString
import Control.Exception.Base
import GHC.Base
import GHC.Conc.Sync
import GHC.Show
import GHC.TopHandler (flushStdHandles)

runIO :: IO a -> IO a
runIO = (`finally` flushStdHandles) . (`catch` topHandler)

runNonIO :: a -> IO a
runNonIO = runIO . evaluate

{-# INLINE topHandler #-}
topHandler :: SomeException -> IO a
topHandler err = do
  reportException err
  throwIO err

reportException :: SomeException -> IO ()
reportException err = handle reportException $ do
  ThreadId tid# <- myThreadId
  s <- evaluate $ toJSString $ show err
  c_tsoReportException tid# s

foreign import ccall unsafe "tsoReportException"
  c_tsoReportException ::
    ThreadId# -> JSString -> IO ()
