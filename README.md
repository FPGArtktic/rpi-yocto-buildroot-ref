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
| Container image | `docker.io/fpgartktic/rpi-ref-yocto:scarthgap` | `docker.io/fpgartktic/rpi-ref-buildroot:2026.02` |

All upstream sources are git submodules pinned to a commit.

## Layout

```
containers/yocto/        Containerfile + entrypoint (Ubuntu 24.04, Yocto host packages)
containers/buildroot/    Containerfile + entrypoint (Ubuntu 24.04, Buildroot host packages)
scripts/                 run.sh, build-image.sh, push-images.sh (+ common.sh: names and defaults)
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

scripts/run.sh yocto bitbake core-image-minimal
scripts/run.sh buildroot make raspberrypi4_64_defconfig
scripts/run.sh buildroot make
scripts/run.sh yocto                      # interactive shell in the initialised build directory
```

`scripts/run.sh <yocto|buildroot> [command...]` runs the command in the build container with whichever runtime
the machine has. It tries `podman`, `apptainer`, `singularity` and `docker`, in that order; set `CTR_RUNTIME=` to
force one. On first use it pulls the image, or builds it from `containers/<flavour>/Containerfile` if the pull
fails. For Apptainer or Singularity it creates a `.sif`.

Every runtime gets the same two mounts:

- `/ref`: this checkout, mounted read-only. Nothing is written into the source tree.
- `/work`: `$RPI_REF_WORK`, which defaults to this checkout. Build trees and caches go here, and all of them are
  git-ignored.

| Path under `/work` | Contents |
|---|---|
| `build/` | Yocto build directory, created from `meta-rpi-ref/conf/templates/default` on first run |
| `downloads/`, `sstate-cache/` | Yocto `DL_DIR` and `SSTATE_DIR` |
| `output/` | Buildroot `O=` directory with `BR2_EXTERNAL` registered on first run |
| `dl/` | Buildroot `BR2_DL_DIR` |
| `yocto.sif`, `buildroot.sif` | Apptainer/Singularity images |

Because the paths are the same everywhere, a build started under one runtime can continue under another. Images are
written to `build/tmp/deploy/images/raspberrypi4-64/` (Yocto) and `output/images/` (Buildroot).

| Script | Does |
|---|---|
| `scripts/run.sh <flavour> [cmd...]` | run a command (default: a shell) in the build container |
| `scripts/build-image.sh <flavour> [runtime]` | (re)build the image from the Containerfile; for Apptainer/Singularity also convert it to `.sif` |
| `scripts/push-images.sh [podman\|docker]` | build both images from a clean `containers/` and push them |

Defaults live in `scripts/common.sh`: `IMAGE_YOCTO`, `IMAGE_BUILDROOT`, `SIF_YOCTO`, `SIF_BUILDROOT`,
`RPI_REF_WORK`, `CTR_RUNTIME`. The per-runtime details are already handled by `run.sh`:

- rootless Podman runs with `--userns=keep-id`, because BitBake refuses to run as root;
- Docker runs with `--user $(id -u):$(id -g)`;
- Apptainer/Singularity use `run --cleanenv`, so the image's entrypoint sets up the build environment.

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
