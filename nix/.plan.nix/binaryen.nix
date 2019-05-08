{ system, compiler, flags, pkgs, hsPkgs, pkgconfPkgs, ... }:
  ({
    flags = {};
    package = {
      specVersion = "0";
      identifier = { name = "binaryen"; version = "0.0.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2018 Tweag I/O";
      maintainer = "Shao Cheng <cheng.shao@tweag.io>";
      author = "";
      homepage = "https://github.com/tweag/asterius#readme";
      url = "";
      synopsis = "";
      description = "";
      buildType = "Custom";
      setup-depends = [
        (hsPkgs.buildPackages.Cabal or (pkgs.buildPackages.Cabal))
        (hsPkgs.buildPackages.base or (pkgs.buildPackages.base))
        (hsPkgs.buildPackages.directory or (pkgs.buildPackages.directory))
        (hsPkgs.buildPackages.filepath or (pkgs.buildPackages.filepath))
        (hsPkgs.buildPackages.ghc or (pkgs.buildPackages.ghc))
        ];
      };
    components = {
      "library" = {
        depends = [ (hsPkgs.base) ];
        build-tools = [
          (hsPkgs.buildPackages.cmake or (pkgs.buildPackages.cmake))
          (hsPkgs.buildPackages.python or (pkgs.buildPackages.python))
          ];
        };
      tests = {
        "binaryen-test" = { depends = [ (hsPkgs.base) (hsPkgs.binaryen) ]; };
        };
      };
    } // rec { src = (pkgs.lib).mkDefault .././../binaryen; }) // {
    cabal-generator = "hpack";
    }