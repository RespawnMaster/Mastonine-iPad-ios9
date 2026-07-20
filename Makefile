TARGET = iphone:clang:9.3:9.0
ARCHS = armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Mastonine

Mastonine_FILES = \
	Mastonine/App/main.m \
	Mastonine/App/MAAppDelegate.m \
	Mastonine/Common/MATheme.m \
	Mastonine/Common/MAImageCache.m \
	Mastonine/Common/MAAvatarView.m \
	Mastonine/Common/MALoadingView.m \
	Mastonine/Common/MAHTMLRenderer.m \
	Mastonine/Common/MAIcons.m \
	Mastonine/Common/MAImageViewerController.m \
	Mastonine/Common/MAWebViewController.m \
	Mastonine/Common/MAMainTabBarController.m \
	Mastonine/Common/MAStreamingController.m \
	Mastonine/Common/MAFilterManager.m \
	Mastonine/Common/MADraftManager.m \
	Mastonine/Common/MAMultipleAccountsManager.m \
	Mastonine/Common/MADropdownMenuViewController.m \
	Mastonine/Models/MAAccount.m \
	Mastonine/Models/MAStatus.m \
	Mastonine/Models/MAMediaAttachment.m \
	Mastonine/Models/MANotification.m \
	Mastonine/Models/MAInstance.m \
	Mastonine/Models/MAList.m \
	Mastonine/Models/MAPoll.m \
	Mastonine/Networking/MAAPIClient.m \
	Mastonine/Networking/MAOAuthManager.m \
	Mastonine/Scenes/Auth/MALoginViewController.m \
	Mastonine/Scenes/Auth/MAInstanceSelectionViewController.m \
	Mastonine/Scenes/Timeline/MATimelineViewController.m \
	Mastonine/Scenes/Timeline/MAStatusTableViewCell.m \
	Mastonine/Scenes/Timeline/MAStatusToolbar.m \
	Mastonine/Scenes/Compose/MAComposeViewController.m \
	Mastonine/Scenes/Profile/MAProfileViewController.m \
	Mastonine/Scenes/Profile/MAAccountTableViewCell.m \
	Mastonine/Scenes/Profile/MAAccountListViewController.m \
	Mastonine/Scenes/Profile/MAProfileEditViewController.m \
	Mastonine/Scenes/Notifications/MANotificationsViewController.m \
	Mastonine/Scenes/Notifications/MANotificationTableViewCell.m \
	Mastonine/Scenes/Thread/MAThreadViewController.m \
	Mastonine/Scenes/Search/MASearchViewController.m \
	Mastonine/Scenes/Settings/MASettingsViewController.m \
	Mastonine/Scenes/Settings/MAGlobalTimelineViewController.m \
	Mastonine/Scenes/Bookmarks/MABookmarksViewController.m \
	Mastonine/Scenes/Lists/MAListsViewController.m \
	Mastonine/Scenes/Lists/MAListTimelineViewController.m \
	Mastonine/Scenes/Lists/MAListMembersViewController.m \
	Mastonine/Scenes/Explore/MAExploreViewController.m \
	Mastonine/Scenes/Favourites/MAFavouritesViewController.m \
	Mastonine/Scenes/Drafts/MADraftsViewController.m \
	Mastonine/Scenes/Scheduled/MAScheduledPostsViewController.m \
	Mastonine/Scenes/Settings/MAFiltersViewController.m \
	Mastonine/Scenes/Settings/MAMultipleAccountsViewController.m \
	Mastonine/Scenes/Hashtags/MAManageHashtagsViewController.m \
	Mastonine/Common/MASpotlightIndexer.m \
	Mastonine/Common/MAEmptyStateView.m \
	Mastonine/Scenes/Status/MAEditHistoryViewController.m

Mastonine_FRAMEWORKS = UIKit Foundation Security CFNetwork SystemConfiguration WebKit QuartzCore CoreGraphics CoreSpotlight

Mastonine_CFLAGS = \
	-fobjc-arc \
	-I$(PWD)/Mastonine/App \
	-I$(PWD)/Mastonine/Common \
	-I$(PWD)/Mastonine/Models \
	-I$(PWD)/Mastonine/Networking \
	-I$(PWD)/Mastonine/Scenes/Auth \
	-I$(PWD)/Mastonine/Scenes/Timeline \
	-I$(PWD)/Mastonine/Scenes/Compose \
	-I$(PWD)/Mastonine/Scenes/Profile \
	-I$(PWD)/Mastonine/Scenes/Notifications \
	-I$(PWD)/Mastonine/Scenes/Thread \
	-I$(PWD)/Mastonine/Scenes/Search \
	-I$(PWD)/Mastonine/Scenes/Settings \
	-I$(PWD)/Mastonine/Scenes/Bookmarks \
	-I$(PWD)/Mastonine/Scenes/Lists \
	-I$(PWD)/Mastonine/Scenes/Explore \
	-I$(PWD)/Mastonine/Scenes/Favourites \
	-I$(PWD)/Mastonine/Scenes/Drafts \
	-I$(PWD)/Mastonine/Scenes/Scheduled \
	-I$(PWD)/Mastonine/Scenes/Hashtags \
	-I$(PWD)/Mastonine/Scenes/Status \
	-Wno-deprecated-declarations \
	-Wno-nullability-completeness \
	-Wno-strict-prototypes \
	-ferror-limit=0

Mastonine_LDFLAGS = -lz

Mastonine_RESOURCE_DIRS = Mastonine/Resources
Mastonine_BUNDLE_IDENTIFIER = com.mastonine.app
Mastonine_INSTALL_PATH = /Applications
Mastonine_INFOPLIST_FILE = Info.plist
Mastonine_CODESIGN_FLAGS = -S/tmp/entitlements.plist

include $(THEOS_MAKE_PATH)/application.mk
