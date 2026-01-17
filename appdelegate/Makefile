#export THEOS_DEVICE_IP = 192.168.0.6

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = appdelegate

appdelegate_FILES = Tweak.xm UIKeyboard.xm
appdelegate_CFLAGS = -Wno-error -Wno-module-import-in-extern-c -fobjc-arc

appdelegate_ARCHS = arm64e arm64
TARGET := iphone:clang:16.5:14.0
THEOS_PACKAGE_SCHEME=rootful
THEOS_PACKAGE_INSTALL_PREFIX=/
appdelegate_FRAMEWORKS = UIKit
#appdelegate_CCFLAGS = -std=c++11

include $(THEOS_MAKE_PATH)/tweak.mk
