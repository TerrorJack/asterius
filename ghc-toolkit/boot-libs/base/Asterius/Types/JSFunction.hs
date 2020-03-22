{-# LANGUAGE NoImplicitPrelude #-}

module Asterius.Types.JSFunction
  ( JSFunction (..),
    callJSFunction,
  )
where

import Asterius.Types.JSArray
import Asterius.Types.JSVal
import GHC.Base

newtype JSFunction
  = JSFunction JSVal

{-# INLINE callJSFunction #-}
callJSFunction :: JSFunction -> [JSVal] -> IO JSVal
callJSFunction f args = js_apply f (toJSArray args)

foreign import javascript unsafe "$1(...$2)"
  js_apply :: JSFunction -> JSArray -> IO JSVal
