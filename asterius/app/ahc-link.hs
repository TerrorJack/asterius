import Asterius.Main
import Control.Concurrent
import Control.Monad

main :: IO ()
main = do
  task <- getTask
  when (threadPoolSize task > 1) $ setNumCapabilities (threadPoolSize task)
  ahcLinkMain task
