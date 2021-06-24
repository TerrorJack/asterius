({ sources ? import ./sources.nix {}
, config
, overlays
, pkgs ? import sources.nixpkgs {
    overlays = [
      (import ./binaryenOverlay.nix)
    ];
  }
 }:

with pkgs;
let wasi-sdk = stdenv.mkDerivation rec {
  # wasi-sdk is a runtime dependency of asterius

  name = "wasi-sdk${version}";
  version = "12.0";
  src = fetchurl {
    urls = ["https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-12/wasi-sdk-12.0-linux.tar.gz"];
    sha256 = "0flpg01m7pfpafjgq9yyv81yw9cb569p34p7zfccwvxzfm6njizs";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook

  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    tar xf $src
  '';

  installPhase = ''
    mkdir -p $out && cp -r * $out/
  '';

  meta = with lib; {
    # homepage = https://studio-link.com;
    description = "wasi-sdk";
    platforms = platforms.linux;
    #maintainers = with maintainers; [ makefu ];
  };
}; in
(pkgs//{wasi-sdk = wasi-sdk;})
)
