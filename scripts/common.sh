# shellcheck shell=bash disable=SC2034  # ctx/image/sif are read by the scripts that source this
# Sourced by build-image.sh, run.sh and push-images.sh: flavour names, image names, runtime selection.
#
#   CTR_RUNTIME      podman | apptainer | singularity | docker   (default: first found, in that order)
#   RPI_REF_WORK     host directory mounted at /work: build trees, caches, .sif files
#                    (default: this checkout; everything it creates there is git-ignored)
#   IMAGE_YOCTO      default docker.io/fpgartktic/rpi-ref-yocto:scarthgap
#   IMAGE_BUILDROOT  default docker.io/fpgartktic/rpi-ref-buildroot:2026.02
#   SIF_YOCTO        default $RPI_REF_WORK/yocto.sif
#   SIF_BUILDROOT    default $RPI_REF_WORK/buildroot.sif
#
# The images are published under those names (scripts/push-images.sh), so a machine without the
# image pulls it; build-image.sh rebuilds it from this checkout's Containerfile instead.

REF=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=${RPI_REF_WORK:-$REF}

die() { echo "${0##*/}: $*" >&2; exit 1; }

# flavour <yocto|buildroot|br>: sets ctx, image, sif
flavour() {
    case "$1" in
        yocto)        ctx=yocto     image=${IMAGE_YOCTO:-docker.io/fpgartktic/rpi-ref-yocto:scarthgap}
                      sif=${SIF_YOCTO:-$WORK/yocto.sif} ;;
        buildroot|br) ctx=buildroot image=${IMAGE_BUILDROOT:-docker.io/fpgartktic/rpi-ref-buildroot:2026.02}
                      sif=${SIF_BUILDROOT:-$WORK/buildroot.sif} ;;
        *)            return 1 ;;
    esac
}

# ensure_image <podman|docker>: local image, else pull, else build from the Containerfile
ensure_image() {
    "$1" image inspect "$image" >/dev/null 2>&1 && return
    echo "${0##*/}: $image not present, pulling" >&2
    "$1" pull -q "$image" >/dev/null 2>&1 && return
    echo "${0##*/}: pull failed, building $image from $REF/containers/$ctx" >&2
    "$REF/scripts/build-image.sh" "$ctx" "$1" >&2
}

pick_runtime() {
    if [ -n "${CTR_RUNTIME:-}" ]; then echo "$CTR_RUNTIME"; return; fi
    for r in podman apptainer singularity docker; do
        if command -v "$r" >/dev/null 2>&1; then echo "$r"; return; fi
    done
    return 1
}
