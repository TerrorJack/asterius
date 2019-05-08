import Asterius.Boot
import System.Environment.Blank

main :: IO ()
main = do
  conf_opts <- getEnvDefault "ASTERIUS_CONFIGURE_OPTIONS" ""
  build_opts <- getEnvDefault "ASTERIUS_BUILD_OPTIONS" ""
  install_opts <- getEnvDefault "ASTERIUS_INSTALL_OPTIONS" ""
  defaultBootArgs <- getDefaultBootArgs
  boot
    defaultBootArgs
      { configureOptions = configureOptions defaultBootArgs <> " " <> conf_opts
      , buildOptions = buildOptions defaultBootArgs <> " " <> build_opts
      , installOptions = installOptions defaultBootArgs <> " " <> install_opts
      }
