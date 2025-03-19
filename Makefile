ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ddzs

$(TWEAK_NAME)_FILES = $(wildcard src/*.xm) $(wildcard src/*.m)

$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = UIKit AVFoundation CoreLocation

$(TWEAK_NAME)_INCLUDES_PATHS += $(PROJECT_DIR)/src

$(TWEAK_NAME)_CFLAGS += -w -Werror -Wno-error -Wno-deprecated-declarations -Wno-unused-but-set-variable -Who-incompatible-pointer-types -Wno-missing-braces
ADDITIONAL_CFLAGS = -w

include $(THEOS_MAKE_PATH)/tweak.mk