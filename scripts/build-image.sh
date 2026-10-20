#!/bin/bash
# Build the build-host image of one flavour for one container runtime.
#
#   scripts/build-image.sh <yocto|buildroot> [podman|docker|apptainer|singularity]
#
# Podman and Docker build from containers/<flavour>/Containerfile. Apptainer and Singularity cannot
# read a Containerfile: the image is built with Podman (or Docker) and converted to $SIF_<FLAVOUR>;
# with neither installed, the published image is converted instead (docker://$IMAGE_<FLAVOUR>).
# Names and defaults: scripts/common.sh.
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

flavour "${1:-}" || { echo "usage: ${0##*/} <yocto|buildroot> [podman|docker|apptainer|singularity]" >&2; exit 2; }
runtime=${2:-$(pick_runtime)} || die "no container runtime found (podman, apptainer, singularity, docker)"
dir="$REF/containers/$ctx"

oci_build() {   # <podman|docker>
    "$1" build -t "$image" -f "$dir/Containerfile" \
        --label org.opencontainers.image.source=https://github.com/FPGArtktic/rpi-yocto-buildroot-ref \
        --label org.opencontainers.image.revision="$(git -C "$REF" rev-parse HEAD 2>/dev/null || echo unknown)" \
        "$dir"
}

case "$runtime" in
    podman|docker)
        oci_build "$runtime" ;;
    apptainer|singularity)
        command -v "$runtime" >/dev/null 2>&1 || die "$runtime not installed"
        mkdir -p "$(dirname "$sif")"
        if command -v podman >/dev/null 2>&1; then
            oci_build podman
            tmp=$(mktemp -d)
            trap 'rm -rf "$tmp"' EXIT
            podman save --format oci-archive -o "$tmp/image.tar" "$image"
            "$runtime" build -F "$sif" "oci-archive://$tmp/image.tar"
        elif command -v docker >/dev/null 2>&1; then
            oci_build docker
            "$runtime" build -F "$sif" "docker-daemon://$image"
        else
            "$runtime" build -F "$sif" "docker://$image"
        fi ;;
    *)
        die "unsupported runtime: $runtime" ;;
esac
