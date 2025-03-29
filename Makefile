#
#  DYYY
#
#  Copyright (c) 2024 huami. All rights reserved.
#  Channel: @huamidev
#  Created on: 2024/10/04
#

TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e

#export THEOS=/Users/huami/theos
#export THEOS_PACKAGE_SCHEME=roothide

ifeq ($(SCHEME),roothide)
    export THEOS_PACKAGE_SCHEME = roothide
else ifeq ($(SCHEME),rootless)
    export THEOS_PACKAGE_SCHEME = rootless
endif

export DEBUG = 0
INSTALL_TARGET_PROCESSES = Aweme

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DYYY

DYYY_FILES = DYYY.xm DYYYSettings.xm DYYYSettingViewController.m DYYYBottomAlertView.m DYYYCustomInputView.m DYYYOptionsSelectionView.m DYYYIconOptionsDialogView.m DYYYAboutDialogView.m DYYYManager.m CityManager.m 
DYYY_CFLAGS = -fobjc-arc -w
CXXFLAGS += -std=c++11
CCFLAGS += -std=c++11
DYYY_LOGOS_DEFAULT_GENERATOR = internal

export THEOS_STRICT_LOGOS=0
export ERROR_ON_WARNINGS=0
export LOGOS_DEFAULT_GENERATOR=internal

include $(THEOS_MAKE_PATH)/tweak.mk

THEOS_DEVICE_IP = 192.168.31.222
THEOS_DEVICE_PORT = 22

clean::
	@echo -e "\033[31m==>\033[0m Cleaning packages…"
	@rm -rf .theos packages

after-package::
	@if [ "$(THEOS_PACKAGE_SCHEME)" = "roothide" ] && [ "$(INSTALL)" = "1" ]; then \
	echo -e "\033[31m==>\033[0m Installing package to device…"; \
	DEB_FILE=$$(ls -t packages/*.deb | head -1); \
	PACKAGE_NAME=$$(basename "$$DEB_FILE" | cut -d'_' -f1); \
	ssh root@$(THEOS_DEVICE_IP) "rm -rf /tmp/$${PACKAGE_NAME}.deb"; \
	scp "$$DEB_FILE" root@$(THEOS_DEVICE_IP):/tmp/$${PACKAGE_NAME}.deb; \
	ssh root@$(THEOS_DEVICE_IP) "dpkg -i --force-overwrite /tmp/$${PACKAGE_NAME}.deb && rm -f /tmp/$${PACKAGE_NAME}.deb"; \
	fi
