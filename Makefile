#
#  DYYY
#
#  Copyright (c) 2024 huami. All rights reserved.
#  Channel: @huamidev
#  Created on: 2024/10/04
#

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
      ARCHS = arm64 arm64e
      TARGET = iphone:clang:latest:15.0
  else
      ARCHS = armv7 armv7s arm64 arm64e
      TARGET = iphone:clang:latest:7.0
  endif
INSTALL_TARGET_PROCESSES = Aweme



include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DYYY

DYYY_FILES = DYYY.x
DYYY_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
