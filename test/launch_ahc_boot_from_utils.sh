#export ASTERIUS_CONFIGURE_OPTIONS="--prefix=$(pwd)"
#export ASTERIUS_BUILD_OPTIONS="--prefix=$(pwd)"
#export ASTERIUS_INSTALL_OPTIONS="--prefix=$(pwd)"

# export ASTERIUS_DATA_DIR="$(pwd)/$2"

# mkdir -p $ASTERIUS_DATA_DIR/ghc-libdir $ASTERIUS_DATA_DIR/.boot/asterius_lib

# cp -r /home/stan/.cache/bazel/_bazel_stan/6bde8fdc74fafa156e3c02473711ce63/execroot/bazel_asterius/bazel-out/host/bin/ghc-toolkit/_install/ghc-toolkit-0.0.1_data/boot-libs $ASTERIUS_DATA_DIR/
# cp -r /home/stan/.cache/bazel/_bazel_stan/6bde8fdc74fafa156e3c02473711ce63/execroot/bazel_asterius/bazel-out/host/bin/ghc-toolkit/_install/ghc-toolkit-0.0.1_data/ghc-libdir $ASTERIUS_DATA_DIR/
# cp -r /home/stan/.cache/bazel/_bazel_stan/6bde8fdc74fafa156e3c02473711ce63/execroot/bazel_asterius/bazel-out/host/bin/asterius/_install/asterius-0.0.1_data/* $ASTERIUS_DATA_DIR/

#chmod +w -R datadir/.boot/asterius_lib
set -e

mkdir sandbox_datadir
export ASTERIUS_DATA_DIR="$(pwd)/sandbox_datadir"

AHC_BOOT_PATH="$1"
ORIGINAL_DATADIR="$3"
OUTPUT_DATADIR="$2"
ORIGINAL_GHC_LIBDIR="$4"
ORIGINAL_BOOT_LIBS="$5"

echo "ORIGINAL_BOOT_LIBS = $ORIGINAL_BOOT_LIBS"
echo "ORIGINAL_GHC_LIBDIR = $ORIGINAL_GHC_LIBDIR"
echo "ORIGINAL_DATADIR = $ORIGINAL_DATADIR"
echo "ASTERIUS_DATA_DIR = $ASTERIUS_DATA_DIR"
echo "OUTPUT_DATADIR = $OUTPUT_DATADIR"
echo "NIX_PATH = $NIX_PATH"
echo "PATH_BZL = $PATH_BZL"

#export NIX_PATH="nixpkgs=$(pwd)/external/nixpkghs"

cp -r $ORIGINAL_DATADIR/* $ASTERIUS_DATA_DIR
cp -r $ORIGINAL_GHC_LIBDIR $ASTERIUS_DATA_DIR
cp -r $ORIGINAL_BOOT_LIBS $ASTERIUS_DATA_DIR

ls $ASTERIUS_DATA_DIR
echo "ghc-libdirrrrrr"
ls $ASTERIUS_DATA_DIR/ghc-libdir

export asterius_datadir=$ASTERIUS_DATA_DIR
echo "ASTERIUS_DATA_DIR=$ASTERIUS_DATA_DIR"
echo "pwd=$(pwd)" 

for p in $PATH_BZL; do
    PATH="$(readlink -f $p):$PATH"
done
	 
#export ASTERIUS_BOOT_DIR=$(pwd)/datadir/.boot

#mkdir datadir/asterius_sandbox_ghc_libdir
#export ASTERIUS_SANDBOX_GHC_LIBDIR=$(pwd)/datadir/asterius_sandbox_ghc_libdir

#export ASTERIUS_BOOT_LIBS_DIR=/home/stan/.cache/bazel/_bazel_stan/6bde8fdc74fafa156e3c02473711ce63/execroot/bazel_asterius/bazel-out/host/bin/ghc-toolkit/_install/ghc-toolkit-0.0.1_data/boot-libs
# /home/stan/.cache/bazel/_bazel_stan/6bde8fdc74fafa156e3c02473711ce63/execroot/bazel_asterius/bazel-out/host/bin/ghc-toolkit/_install/ghc-toolkit-0.0.1_data/boot-libs
# /home/stan/.cache/bazel/_bazel_stan/6bde8fdc74fafa156e3c02473711ce63/execroot/bazel_asterius/bazel-out/host/bin/asterius/_install/bin/ahc-boot.runfiles/bazel_asterius/ghc-toolkit/boot-libs

echo "asterius_datadir=$asterius_datadir"
echo '$1'
echo "$1"

echo '$(dirname $1)'
echo "$(dirname $(readlink -f $1))"
# export PATH="$(dirname $(readlink -f $1)):$PATH"
echo "PATH=$PATH"

echo '$2'
echo "$2"

echo "running: $1"
# $AHC_BOOT_PATH
ahc-boot


# pushd sandbox_datadir
# ln -s $(ahc_pkg field base haddock-html --simple-output) docdir
# popd

cp -a "$ASTERIUS_DATA_DIR/." "$OUTPUT_DATADIR/"
