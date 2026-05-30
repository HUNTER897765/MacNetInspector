#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"HUNTER.MacNetInspector";

/// The "accentBlue" asset catalog color resource.
static NSString * const ACColorNameAccentBlue AC_SWIFT_PRIVATE = @"accentBlue";

/// The "accentGreen" asset catalog color resource.
static NSString * const ACColorNameAccentGreen AC_SWIFT_PRIVATE = @"accentGreen";

/// The "accentOrange" asset catalog color resource.
static NSString * const ACColorNameAccentOrange AC_SWIFT_PRIVATE = @"accentOrange";

/// The "accentPurple" asset catalog color resource.
static NSString * const ACColorNameAccentPurple AC_SWIFT_PRIVATE = @"accentPurple";

/// The "accentRed" asset catalog color resource.
static NSString * const ACColorNameAccentRed AC_SWIFT_PRIVATE = @"accentRed";

/// The "accentTeal" asset catalog color resource.
static NSString * const ACColorNameAccentTeal AC_SWIFT_PRIVATE = @"accentTeal";

/// The "bgBottom" asset catalog color resource.
static NSString * const ACColorNameBgBottom AC_SWIFT_PRIVATE = @"bgBottom";

/// The "bgTop" asset catalog color resource.
static NSString * const ACColorNameBgTop AC_SWIFT_PRIVATE = @"bgTop";

#undef AC_SWIFT_PRIVATE
