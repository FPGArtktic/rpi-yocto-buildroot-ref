# rpi-yocto-buildroot-ref

A Raspberry Pi 4 (64-bit) reference design built two ways, with Yocto and with Buildroot, inside pinned build
containers. It exists as the test bed for [rtk-embedded-linux](https://github.com/FPGArtktic/rtk-embedded-linux),
which captures the output of real Yocto and Buildroot commands from it. It also works as a small, reproducible
starting point for either build system.

| | Yocto | Buildroot |
|---|---|---|
| Release | Poky `yocto-5.0.20` (scarthgap LTS) | `2026.02.3` (LTS) |
| BSP | meta-raspberrypi, `scarthgap` branch | in-tree |
| Machine / defconfig | `MACHINE = "raspberrypi4-64"` | `raspberrypi4_64_defconfig` |
| Default target | `core-image-minimal` | `make` |
| Container image | `rpi-ref-yocto:scarthgap` | `rpi-ref-buildroot:2026.02` |

All upstream sources are git submodules pinned to a commit.

## Layout

```
containers/yocto/        Containerfile + entrypoint (Ubuntu 24.04, Yocto host packages)
containers/buildroot/    Containerfile + entrypoint (Ubuntu 24.04, Buildroot host packages)
yocto/poky/              submodule
yocto/meta-raspberrypi/  submodule
yocto/meta-rpi-ref/      this design: build templates + failure-scenario recipes
buildroot/buildroot/     submodule
buildroot/external/      BR2_EXTERNAL tree: failure-scenario package
```

## Usage

```bash
git clone --recursive https://github.com/FPGArtktic/rpi-yocto-buildroot-ref.git
cd rpi-yocto-buildroot-ref

podman build -t rpi-ref-yocto:scarthgap     containers/yocto
podman build -t rpi-ref-buildroot:2026.02   containers/buildroot
```

The images expect two mounts:

- `/ref`: this checkout. It can be mounted read-only, because nothing is written into the source tree.
- `/work`: where build trees and caches go.

| Path under `/work` | Contents |
|---|---|
| `build/` | Yocto build directory, created from `meta-rpi-ref/conf/templates/default` on first run |
| `downloads/`, `sstate-cache/` | Yocto `DL_DIR` and `SSTATE_DIR` |
| `output/` | Buildroot `O=` directory with `BR2_EXTERNAL` registered on first run |
| `dl/` | Buildroot `BR2_DL_DIR` |

The entrypoint sets up the build environment and runs its arguments. With no arguments it starts a shell.

```bash
mkdir -p ../rpi-work
RUN="podman run --rm -it --userns=keep-id -v $PWD:/ref:ro -v $PWD/../rpi-work:/work"

$RUN rpi-ref-yocto:scarthgap bitbake core-image-minimal
$RUN rpi-ref-buildroot:2026.02 make raspberrypi4_64_defconfig
$RUN rpi-ref-buildroot:2026.02 make
```

Use `--userns=keep-id` with rootless Podman, because BitBake refuses to run as root. With Docker, use
`--user "$(id -u):$(id -g)"` instead. To run under Apptainer, convert the image first. This path has not been
tested here.

```bash
podman save --format oci-archive -o yocto.tar rpi-ref-yocto:scarthgap
apptainer build yocto.sif oci-archive://yocto.tar
apptainer run --bind $PWD:/ref,$PWD/../rpi-work:/work yocto.sif bitbake core-image-minimal   # run = through the entrypoint
```

Images are written to `build/tmp/deploy/images/raspberrypi4-64/` (Yocto) and `output/images/` (Buildroot).

## Failure scenarios

These targets fail on purpose, so tools that read build logs can be tested against real failure output. None of
them is part of an image or a defconfig.

| Build system | Command | Fails in |
|---|---|---|
| Yocto | `bitbake rtk-fail-compile` | `do_compile`: undeclared identifier in C |
| Yocto | `bitbake rtk-fetch-fail` | `do_fetch`: the `SRC_URI` host is under `.invalid` (RFC 2606) |
| Buildroot | `make rtk-fail-compile` | build step: undeclared identifier in C (run it after a full `make`, so the toolchain exists) |

## Notes

- The Synaptics "killswitch" licence flag for the Pi WiFi/BT firmware is **not** accepted by the default
  `local.conf`. The image builds without the firmware. See `yocto/meta-rpi-ref/conf/templates/default/local.conf.sample`.
- To bump a submodule, run `git -C yocto/poky checkout <tag>` and then `git add yocto/poky`. The same applies to the other submodules.

## License

GPL-3.0-only for the files in this repository; see [LICENSE](LICENSE). Each submodule is under its own license.
