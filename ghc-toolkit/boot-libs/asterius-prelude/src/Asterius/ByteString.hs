{-# LANGUAGE MagicHash #-}

module Asterius.ByteString
  ( foreignPtrFromJSArrayBuffer
  , byteStringFromJSArrayBuffer
  , byteStringToJSArrayBuffer
  ) where

import Asterius.Magic
import Asterius.Types
import Data.ByteString.Internal (ByteString(..))
import Data.ByteString.Unsafe
import GHC.Base
import GHC.ForeignPtr
import GHC.IO
import GHC.Ptr

{-# INLINE foreignPtrFromJSArrayBuffer #-}
foreignPtrFromJSArrayBuffer :: JSArrayBuffer -> ForeignPtr a
foreignPtrFromJSArrayBuffer buf =
  case fromJSArrayBuffer buf of
    ba -> ForeignPtr (byteArrayContents# ba) (PlainPtr (unsafeCoerce# ba))

{-# INLINE byteStringFromJSArrayBuffer #-}
byteStringFromJSArrayBuffer :: JSArrayBuffer -> ByteString
byteStringFromJSArrayBuffer buf =
  case fromJSArrayBuffer buf of
    ba ->
      PS
        (ForeignPtr (byteArrayContents# ba) (PlainPtr (unsafeCoerce# ba)))
        0
        (I# (sizeofByteArray# ba))

{-# INLINE byteStringToJSArrayBuffer #-}
byteStringToJSArrayBuffer :: ByteString -> JSArrayBuffer
byteStringToJSArrayBuffer bs =
  accursedUnutterablePerformIO $
  unsafeUseAsCStringLen bs $ \(Ptr addr, len) ->
    evaluate $ toJSArrayBuffer addr len
