# To use this run `nix-shell`.  In the shell run `cabal new-build asterius`
# to build the asterius executables.  Check that the resulting binaries
# are in the PATH with `ahc-pkg list --global`.
let
  nixpkgs = import <nixpkgs> {};

  # Use this to set the version of asterius to be booted
  cached = import (nixpkgs.fetchgit {
    url = "https://github.com/input-output-hk/asterius";
    rev = "ec674bd3cada1656537d10eaaf6d5b81d3311643";
    sha256 = "1wzj29k2367ad35l8c8jm35z6bx580phnx340y67v3f6x56ldaz6";
    fetchSubmodules = true;
  }) {};
  nix-tools = (import ./. {}).nix-tools;
  hsPkgs = nix-tools._raw.hsPkgs;
  cabalSystem = builtins.replaceStrings ["-darwin"] ["-osx"] nixpkgs.stdenv.system;
in (hsPkgs.shellFor {
    # Shell will provide the dependencies of asterius, but not asterius itself.
    packages = ps: with ps; [ asterius binaryen ];
  }).overrideAttrs (oldAttrs: {
    shellHook = (oldAttrs.shellHook or "") + ''
      unset CABAL_CONFIG
      export asterius_bootdir=${cached.nix-tools._raw.asterius-boot}/boot
      find . -name package.yaml -exec hpack "{}" \;
      export asterius_datadir=$(pwd)/asterius
      export binaryen_datadir=$(pwd)/binaryen
      export ghc_toolkit_datadir=$(pwd)/ghc-toolkit
      export inline_js_datadir=$(pwd)/inline-js/inline-js
      export inline_js_core_datadir=$(pwd)/inline-js/inline-js-core
      export wabt_datadir=$(pwd)/wabt
      export wasm_toolkit_datadir=$(pwd)/wasm-toolkit
      mkdir -p asterius-cabal-bin
      cd asterius-cabal-bin
      export asterius_bindir=$(pwd)
      export PATH=$(pwd):$PATH
      ''
      + nixpkgs.lib.concatMapStrings (exe: ''
        ln -sf ../dist-newstyle/build/${cabalSystem}/ghc-8.6.4/asterius-0.0.1/build/${exe}/${exe} ${exe}
      '') ["ahc" "ahc-boot" "ahc-cabal" "ahc-dist" "ahc-ld" "ahc-link" "ahc-pkg"]
      + ''
      cd ..
    '';
  })
