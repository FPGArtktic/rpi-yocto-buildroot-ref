#!/bin/bash
# Build both images from this checkout and push them under the names in scripts/common.sh.
#
#   scripts/push-images.sh [podman|docker]      (default: podman if installed, else docker)
#
# Needs `<runtime> login docker.io` first. Refuses to run with uncommitted changes in containers/,
# so a published image always matches a commit (recorded in its org.opencontainers.image.revision).
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

runtime=${1:-$(command -v podman >/dev/null 2>&1 && echo podman || echo docker)}
case "$runtime" in podman|docker) ;; *) die "usage: ${0##*/} [podman|docker]" ;; esac
[ -z "$(git -C "$REF" status --porcelain -- containers)" ] \
    || die "containers/ has uncommitted changes - commit them before publishing images"

for f in yocto buildroot; do
    flavour "$f"
    "$REF/scripts/build-image.sh" "$ctx" "$runtime"
    "$runtime" push "$image"
done
