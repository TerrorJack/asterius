#!/usr/bin/env bash
# Copyright (c) 2021 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---

# Make sure that runfiles and tools are still found after we change directory.
case "$(uname -s)" in
  Darwin)
    abspath() { python -c 'import os.path, sys; sys.stdout.write(os.path.abspath(sys.argv[1]))' "$@"; }
    canonicalpath() { python -c 'import os.path, sys; sys.stdout.write(os.path.realpath(sys.argv[1]))' "$@"; }
    ;;
  *)
    abspath() { realpath -s "$@"; }
    canonicalpath() { readlink -f "$@"; }
    ;;
esac

if [[ -n ${RUNFILES_DIR:-} ]]; then
  export RUNFILES_DIR=$(abspath $RUNFILES_DIR)
fi
if [[ -n ${RUNFILES_MANIFEST_FILE:-} ]]; then
  export RUNFILES_DIR=$(abspath $RUNFILES_MANIFEST_FILE)
fi

case "$(uname -s)" in
  Darwin|Linux)
    # find tar
    tar=$(abspath $(rlocation tar/bin/tar))
    gzip=$(abspath $(rlocation gzip/bin/gzip))
    mktgz=$(abspath $(rlocation bazel_asterius/bazel_utils/sh/mktgz))
    ;;
  CYGWIN*|MINGW*|MSYS*)
    tar=$(abspath $(rlocation tar/usr/bin/tar.exe))
    gzip=$(abspath $(rlocation gzip/urs/bin/gzip.exe))
    mktgz=$(abspath $(rlocation bazel_asterius/bazel_utils/sh/mktgz.exe))
    ;;
esac

set -eou pipefail

WORKDIR="$(mktemp -d)"
trap "rm -rf $WORKDIR" EXIT


OUT=$(abspath $1)
shift 1

# Copy in resources, if any.
if [ $# -gt 0 ]; then
  for res in $*; do
    if [[ "$res" == *.tar.gz ]]; then
      # If a resource is a tarball, e.g., because it originates from another
      # rule we extract it.
      $tar xf "$res" --strip-components=3 -C "$WORKDIR"
    else
      echo "res = $res"
      cp -aL "$res" "$WORKDIR"
    fi
  done
fi

$mktgz $OUT "$WORKDIR"
