#!/bin/bash
# Run a command in a build container, whatever runtime this machine has.
#
#   scripts/run.sh <yocto|buildroot> [command...]      (no command: a shell)
#
# This checkout is mounted read-only at /ref and $RPI_REF_WORK at /work in every runtime, so build
# trees and log paths are identical whichever runtime ran the build. A missing image is pulled, or
# built if the pull fails; a missing .sif is made by scripts/build-image.sh. Runtime, names and
# defaults: scripts/common.sh.
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

flavour "${1:-}" || { echo "usage: ${0##*/} <yocto|buildroot> [command...]" >&2; exit 2; }
shift
[ -f "$REF/containers/$ctx/Containerfile" ] && [ -n "$(ls -A "$REF/yocto/poky" 2>/dev/null)" ] \
    || die "submodules missing in $REF - run: git submodule update --init --recursive"
runtime=$(pick_runtime) || die "no container runtime found (podman, apptainer, singularity, docker)"
mkdir -p "$WORK"

# A terminal gets a terminal (BitBake then draws progress bars); a pipe gets plain output.
tty=()
[ -t 1 ] && tty+=(-t)
[ -t 0 ] && tty+=(-i)

case "$runtime" in
    podman)
        ensure_image podman
        exec podman run --rm "${tty[@]}" --userns=keep-id --security-opt label=disable \
            -v "$REF:/ref:ro" -v "$WORK:/work" "$image" "$@" ;;
    docker)
        ensure_image docker
        exec docker run --rm "${tty[@]}" --user "$(id -u):$(id -g)" --security-opt label=disable \
            -v "$REF:/ref:ro" -v "$WORK:/work" "$image" "$@" ;;
    apptainer|singularity)
        [ -f "$sif" ] || "$REF/scripts/build-image.sh" "$ctx" "$runtime" >&2
        # `run` goes through the image's entrypoint, which sets up the build environment.
        # --no-eval: pass arguments verbatim, as Podman/Docker do; the default runscript would
        # shell-evaluate them ($VAR, $(...)) before the entrypoint has run.
        exec "$runtime" run --cleanenv --no-eval --bind "$REF:/ref:ro,$WORK:/work" "$sif" "$@" ;;
    *)
        die "unsupported CTR_RUNTIME=$runtime" ;;
esac
