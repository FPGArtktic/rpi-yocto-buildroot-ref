SUMMARY = "C program that does not compile (failure scenario)"
DESCRIPTION = "Fails in do_compile on purpose, so the output of a failing build can be captured \
and replayed. Never add it to an image."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://rtk-fail-compile.c"
S = "${WORKDIR}"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -o rtk-fail-compile rtk-fail-compile.c
}

do_install() {
    install -Dm0755 rtk-fail-compile ${D}${bindir}/rtk-fail-compile
}
