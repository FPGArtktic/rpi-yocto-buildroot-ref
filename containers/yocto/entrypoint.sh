#!/bin/bash
# Run a command inside an initialised Yocto build directory.
#
#   RPI_REF   where this repository is mounted          (default: /ref, may be read-only)
#   BUILDDIR  build directory, created on first use     (default: /work/build)
#
# The build directory is created from meta-rpi-ref/conf/templates/default, so DL_DIR and
# SSTATE_DIR end up next to it: /work/downloads, /work/sstate-cache.
RPI_REF=${RPI_REF:-/ref}
BUILDDIR=${BUILDDIR:-/work/build}

export TEMPLATECONF="$RPI_REF/yocto/meta-rpi-ref/conf/templates/default"
cd "$RPI_REF/yocto/poky" || exit 1
# oe-init-build-env prints a banner on stdout; errors still reach stderr.
. ./oe-init-build-env "$BUILDDIR" >/dev/null || exit 1

[ $# -gt 0 ] || set -- bash
exec "$@"
