#!/usr/bin/env bash


export asterius_bindir=$(dirname $0)
export bundle_root="$(dirname $(dirname $asterius_bindir))"
export WASI_SDK_PATH="$bundle_root/resources/wasilibc/wasi-sdk-12.0/"
