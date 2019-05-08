{ system, compiler, flags, pkgs, hsPkgs, pkgconfPkgs, ... }:
  ({
    flags = {};
    package = {
      specVersion = "0";
      identifier = { name = "npm-utils"; version = "0.0.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2018 Tweag I/O";
      maintainer = "Shao Cheng <cheng.shao@tweag.io>";
      author = "";
      homepage = "https://github.com/tweag/asterius#readme";
      url = "";
      synopsis = "";
      description = "";
      buildType = "Custom";
      };
    components = {
      "library" = { depends = [ (hsPkgs.base) (hsPkgs.filepath) ]; };
      };
    } // rec { src = (pkgs.lib).mkDefault .././../npm-utils; }) // {
    cabal-generator = "hpack";
    }