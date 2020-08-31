#!/bin/sh

set -eu

ahc-cabal v1-install --ipid="\$pkg-\$version" --ghc-option=-j$jobs \
  Cabal

export ASTERIUS_TH_IGNORE=1
ahc-cabal v1-install --ipid="\$pkg-\$version" -j$jobs --keep-going \
  $(cat pkgs.txt) || true

unset ASTERIUS_TH_IGNORE
ahc-cabal v1-install --ipid="\$pkg-\$version" -j$jobs_th --keep-going \
  $(cat pkgs.txt) || true
