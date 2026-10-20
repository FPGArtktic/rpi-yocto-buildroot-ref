SUMMARY = "Recipe whose source can never be fetched (failure scenario)"
DESCRIPTION = "Fails in do_fetch on purpose, so the output of a failing fetch can be captured \
and replayed. Never add it to an image."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# .invalid is reserved (RFC 2606) and never resolves; the default mirrors do not have the file either.
SRC_URI = "https://downloads.example.invalid/rtk-fetch-fail-${PV}.tar.gz"
SRC_URI[sha256sum] = "0000000000000000000000000000000000000000000000000000000000000000"
