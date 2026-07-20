TARGET = iphone:clang:9.3:9.0
ARCHS = armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MastodonShareExtension

MastodonShareExtension_FILES = MastodonShareExtension/MAShareViewController.m

MastodonShareExtension_FRAMEWORKS = UIKit Foundation Social

MastodonShareExtension_CFLAGS = \
	-fobjc-arc \
	-I$(PWD)/MastodonShareExtension \
	-Wno-deprecated-declarations \
	-Wno-nullability-completeness

MastodonShareExtension_BUNDLE_IDENTIFIER = com.mastonine.app.share-extension
MastodonShareExtension_INSTALL_PATH = /Applications
MastodonShareExtension_CODESIGN_FLAGS = -S/tmp/entitlements.plist

include $(THEOS_MAKE_PATH)/application.mk
