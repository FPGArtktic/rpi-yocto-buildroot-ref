################################################################################
#
# rtk-fail-compile
#
################################################################################

RTK_FAIL_COMPILE_VERSION = 1.0
RTK_FAIL_COMPILE_SITE = $(BR2_EXTERNAL_RPI_REF_PATH)/package/rtk-fail-compile/src
RTK_FAIL_COMPILE_SITE_METHOD = local
RTK_FAIL_COMPILE_LICENSE = GPL-3.0-or-later

define RTK_FAIL_COMPILE_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		-o $(@D)/rtk-fail-compile $(@D)/rtk-fail-compile.c
endef

define RTK_FAIL_COMPILE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/rtk-fail-compile $(TARGET_DIR)/usr/bin/rtk-fail-compile
endef

$(eval $(generic-package))
