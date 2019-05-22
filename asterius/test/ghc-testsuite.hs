{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE StrictData #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ImplicitParams #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# OPTIONS_GHC -funbox-strict-fields #-}


import Asterius.JSRun.Main
import qualified Data.ByteString.Lazy as LBS
import Data.Traversable
import Control.Monad (when)
import Language.JavaScript.Inline.Core
import System.Directory
import System.FilePath
import System.Process
import Test.Tasty
import Test.Tasty.Ingredients
import Test.Tasty.Ingredients.ConsoleReporter
import Data.Monoid (Any(..))
import Control.Concurrent.STM.TVar
import Control.Concurrent.STM
import Test.Tasty.Hspec
import Test.Tasty.Runners
import Control.Exception
import Data.IORef
import GHC.Generics
import System.IO (stdout)
import System.Console.ANSI (hSupportsANSIColor)
import Control.Arrow ((&&&))
import Data.Csv
import Data.List (sort)

-- Much of the code is shamelessly stolen from:
-- http://hackage.haskell.org/package/tasty-1.2.2/docs/src/Test.Tasty.Ingredients.ConsoleReporter.html#consoleTestReporter
--
-- TODO: Update the code to not re-implement tasty internals when
-- the new version is released, since we had a PR that exposes some
-- tasty internals for us:
-- https://github.com/feuerbach/tasty/pull/252

data TestCase = TestCase
  { casePath :: FilePath
  , caseStdIn, caseStdOut, caseStdErr :: LBS.ByteString
  } deriving (Show)

readFileNullable :: FilePath -> IO LBS.ByteString
readFileNullable p = do
  exist <- doesFileExist p
  if exist
    then LBS.readFile p
    else pure LBS.empty

getTestCases :: IO [TestCase]
getTestCases = do
  let root = "test" </> "ghc-testsuite"
  subdirs <- sort <$> listDirectory root
  fmap concat $
    for subdirs $ \subdir -> do
      let subroot = root </> subdir
      files <- sort <$> listDirectory subroot
      let cases = map (subroot </>) $ filter ((== ".hs") . takeExtension) files
      for cases $ \c ->
        TestCase c <$> readFileNullable (c -<.> "stdin") <*>
        readFileNullable (c -<.> "stdout") <*>
        readFileNullable (c -<.> "stderr")




data TestOutcome = TestSuccess | TestFailure deriving(Eq, Show, Generic)
instance ToField TestOutcome where
  toField = toField . show


data TestRecord = TestRecord
  { trOutcome :: !TestOutcome
  , trPath :: !FilePath -- ^ Path of the test case
  , trErrorMessage :: !String -- ^ If the test failed, then the error message associated to the failure.
  } deriving(Generic)

instance ToRecord TestRecord where
instance DefaultOrdered TestRecord where
instance ToNamedRecord TestRecord where



-- | Log of tests that have run
newtype TestLog = TestLog { unTestLog :: [TestRecord] } deriving(Semigroup, Monoid, Generic)

atomicModifyIORef'_ :: IORef a -> (a -> a) -> IO ()
atomicModifyIORef'_ r f = atomicModifyIORef' r $ f &&& const ()


-- | Append a value to the test log in safe way when we have multiple threads
consTestLog :: TestRecord -> IORef TestLog -> IO ()
consTestLog tr tlref = atomicModifyIORef'_ tlref (\(TestLog tl) -> TestLog $ tr:tl)



-- [Note: Abusing Tasty APIs to get readable console logs]
-- | Have the Show instance print the exception after the separator  so we can
-- | strip out the separator in the printer
-- | This way, our custom ingredient can still serialize all the information
-- | that comes after the ``, but when we print, we strip out the leading
-- | separator and all text that follows it.
separator :: Char
separator = 'γ'


-- | What happened when we tried to run the test
data RunOutcome = RunSuccess | RunFailure String deriving(Eq)

instance Show RunOutcome where
  show (RunSuccess) = "RunSuccess"
  show (RunFailure e) = "RunFailure" <> [separator] <> e



-- | What happened when we tried to compile the test
data CompileOutcome = CompileFailure String | CompileSuccess JSVal  deriving(Eq)

-- | Test if the compile outcome was true or not.
isCompileSuccess :: CompileOutcome -> Bool
isCompileSuccess (CompileSuccess _) = True
isCompileSuccess _ = False

instance Show CompileOutcome where
  show (CompileSuccess _) = show "CompileSuccess "
  show (CompileFailure e) = "CompileFailure" <> [separator] <> e

runTestCase :: TestCase -> IO ()
runTestCase TestCase {..} = do
  _ <- readProcess "ahc-link" ["--input-hs", casePath, "--binaryen"] ""
  mod_buf <- LBS.readFile $ casePath -<.> "wasm"
  withJSSession defJSSessionOpts $ \s -> do
    -- | Try to compile and setup the program. If we throw an exception,
    -- return a CompileFailure with the error message
    co <-
        (do
          i <- newAsteriusInstance s (casePath -<.> "lib.mjs") mod_buf
          hsInit s i
          pure (CompileSuccess i))
            `catch` (\(e :: SomeException) -> pure . CompileFailure . show $ e)
    co `shouldSatisfy` isCompileSuccess

    let CompileSuccess i = co

    -- | Try to run main. If we throw an exception, return a
    -- RunFailure with the error message.
    ro <- (hsMain s i *> pure RunSuccess)
      `catch` (\(e :: SomeException) -> pure . RunFailure . show $ e)
    -- | Check that the run succeeded. If it did not, report a failing
    -- test case
    ro `shouldBe` RunSuccess

    -- | If the run succeded, now compare outputs.
    hs_stdout <- hsStdOut s i
    hs_stderr <- hsStdErr s i

    hs_stdout `shouldBe` caseStdOut
    hs_stderr `shouldBe` caseStdErr


makeTestTree :: TestCase -> IO TestTree
makeTestTree c@TestCase {..} =
  testSpec casePath $
    it casePath $ runTestCase  c


-- | save the test log to disk as a CSV file
saveTestLogToCSV :: IORef TestLog -> FilePath -> IO ()
saveTestLogToCSV tlref out_basepath = do
  let out_csvpath = out_basepath <.> "csv"
  tlv <- readIORef tlref
  putStrLn $ "[INFO] Writing log CSV file to path: " <> out_csvpath
  LBS.writeFile out_csvpath (encodeDefaultOrderedByName . unTestLog $ tlv)

-- | Prune the description of the test result to be legible for rendering.
-- | See [Note: Abusing Tasty APIs to get readable console logs]
resultPruneDescription :: Test.Tasty.Runners.Result -> Test.Tasty.Runners.Result
resultPruneDescription Result{..} =
   Result{resultDescription=takeWhile (/= separator) resultDescription, ..}

-- TestReporter [OptionDescription] (OptionSet -> TestTree -> Maybe (StatusMap -> IO (Time -> IO Bool)))
consoleOutput ::  IORef TestLog -> TestOutput -> StatusMap -> IO ()
consoleOutput tlref toutput smap =
  getTraversal . fst $ foldTestOutput foldTest foldHeading toutput smap
  where
    foldTest _name printName getResult printResult =
      ( Traversal $ do
          printName :: IO ()
          r <- getResult
          _ <- printResult . resultPruneDescription $ r
          let tr = if resultSuccessful r
              then TestRecord TestSuccess _name ""
              else TestRecord TestFailure _name (resultDescription r)
          consTestLog tr tlref

      , Any True)
    foldHeading _name printHeading (printBody, Any nonempty) =
      ( Traversal $ do
          when nonempty $ do printHeading :: IO (); getTraversal printBody
      , Any nonempty
      )


getResultFromTVar :: TVar Status -> IO Test.Tasty.Runners.Result
getResultFromTVar var =
  atomically $ do
    status <- readTVar var
    case status of
      Done r -> return r
      _ -> retry

computeStatistics :: StatusMap -> IO Statistics
computeStatistics = getApp . foldMap (\var -> Ap $
  (\r -> Statistics 1 (if resultSuccessful r then 0 else 1))
    <$> getResultFromTVar var)


-- | Code stolen from Test.Tasty.Ingredients.ConsoleReporter
serializeToDisk :: IORef TestLog -> Ingredient
serializeToDisk tlref = TestReporter [] $
  \opts tree -> Just $ \smap ->
  let
  in do
    isTermColor <- hSupportsANSIColor stdout
    let ?colors = isTermColor
    -- let toutput = let ?colors = isTermColor in buildTestOutput opts tree
    let toutput = buildTestOutput opts tree
    consoleOutput tlref toutput smap
    return $ \time -> do
      stats <- computeStatistics smap
      printStatistics stats time
      return $ statFailures stats == 0

main :: IO ()
main = do
  tlref <- newIORef mempty
  trees <- getTestCases >>= traverse makeTestTree

  cwd <- getCurrentDirectory
  let out_basepath = cwd </> "test-report"

  -- | Tasty throws an exception if stuff fails, so re-throw the exception
  -- | in case this happens.
  (defaultMainWithIngredients [serializeToDisk tlref] $ testGroup "asterius ghc-testsuite" trees)
    `finally` (saveTestLogToCSV tlref out_basepath)


