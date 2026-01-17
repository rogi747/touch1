THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222
ARCHS = arm64e arm64
TARGET := iphone:clang:16.5:14.0
THEOS_PACKAGE_SCHEME=rootless
THEOS_PACKAGE_INSTALL_PREFIX=/var/jb

include $(THEOS)/makefiles/common.mk

TOOL_NAME = zxtouchd

zxtouchd_FILES = main.mm
zxtouchd_CFLAGS = -Wno-error -Wno-module-import-in-extern-c -fobjc-arc

include $(THEOS_MAKE_PATH)/tool.mk
