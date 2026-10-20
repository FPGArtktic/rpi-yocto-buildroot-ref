#!/bin/bash
# Run a command inside a Buildroot output directory (out-of-tree build, O=).
#
#   RPI_REF     where this repository is mounted         (default: /ref, may be read-only)
#   BR_OUT      output directory, created on first use   (default: /work/output)
#   BR2_DL_DIR  download cache                           (default: /work/dl)
#
# On first use BR_OUT gets Buildroot's wrapper Makefile with BR2_EXTERNAL registered, so plain
# `make <defconfig>`, `make`, `make <pkg>-rebuild` work from there.
RPI_REF=${RPI_REF:-/ref}
BR_OUT=${BR_OUT:-/work/output}
export BR2_DL_DIR=${BR2_DL_DIR:-/work/dl}

if [ ! -f "$BR_OUT/Makefile" ]; then
    mkdir -p "$BR_OUT" || exit 1
    make -s -C "$RPI_REF/buildroot/buildroot" O="$BR_OUT" \
        BR2_EXTERNAL="$RPI_REF/buildroot/external" outputmakefile >/dev/null || exit 1
fi
cd "$BR_OUT" || exit 1

[ $# -gt 0 ] || set -- bash
exec "$@"
