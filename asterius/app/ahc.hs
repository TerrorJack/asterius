import qualified Asterius.BuildInfo as A
import qualified Asterius.FrontendPlugin as A
import Language.Haskell.GHC.Toolkit.FakeGHC hiding (ghc)
import System.Directory
import System.FilePath

main :: IO ()
main = do
  Just ghc <- findExecutable "ghc-asterius"
  fakeGHCMain $
    FakeGHCOptions
      ghc
      (A.dataDir </> ".boot" </> "asterius_lib")
      A.frontendPlugin
