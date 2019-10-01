#!/bin/sh -e

export CPUS=$(getconf _NPROCESSORS_ONLN 2>/dev/null)
export ASTERIUS_BUILD_OPTIONS=-j1
export ASTERIUS_DEBUG=1
export MAKEFLAGS=-j$CPUS

. utils/clean.sh
stack build -j$CPUS --test --no-run-tests asterius
stack exec ahc-boot
