# lipoplastic setup for armv6 + arm64 compilation
export ARCHS = arm64e arm64
#export THEOS_DEVICE_IP = 192.168.0.3
TARGET := iphone:clang:16.5:14.0
THEOS_PACKAGE_INSTALL_PREFIX=/

SUBPROJECTS = appdelegate zxtouch-binary pccontrol zxtouchd

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/aggregate.mk

after-install::
	install.exec "chown -R mobile:mobile /var/mobile/Library/ZXTouch && killall -9 SpringBoard;"
