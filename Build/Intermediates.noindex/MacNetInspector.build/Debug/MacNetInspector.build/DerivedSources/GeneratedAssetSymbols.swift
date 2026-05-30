import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "accentBlue" asset catalog color resource.
    static let accentBlue = DeveloperToolsSupport.ColorResource(name: "accentBlue", bundle: resourceBundle)

    /// The "accentGreen" asset catalog color resource.
    static let accentGreen = DeveloperToolsSupport.ColorResource(name: "accentGreen", bundle: resourceBundle)

    /// The "accentOrange" asset catalog color resource.
    static let accentOrange = DeveloperToolsSupport.ColorResource(name: "accentOrange", bundle: resourceBundle)

    /// The "accentPurple" asset catalog color resource.
    static let accentPurple = DeveloperToolsSupport.ColorResource(name: "accentPurple", bundle: resourceBundle)

    /// The "accentRed" asset catalog color resource.
    static let accentRed = DeveloperToolsSupport.ColorResource(name: "accentRed", bundle: resourceBundle)

    /// The "accentTeal" asset catalog color resource.
    static let accentTeal = DeveloperToolsSupport.ColorResource(name: "accentTeal", bundle: resourceBundle)

    /// The "bgBottom" asset catalog color resource.
    static let bgBottom = DeveloperToolsSupport.ColorResource(name: "bgBottom", bundle: resourceBundle)

    /// The "bgTop" asset catalog color resource.
    static let bgTop = DeveloperToolsSupport.ColorResource(name: "bgTop", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "accentBlue" asset catalog color.
    static var accentBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accentBlue)
#else
        .init()
#endif
    }

    /// The "accentGreen" asset catalog color.
    static var accentGreen: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accentGreen)
#else
        .init()
#endif
    }

    /// The "accentOrange" asset catalog color.
    static var accentOrange: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accentOrange)
#else
        .init()
#endif
    }

    /// The "accentPurple" asset catalog color.
    static var accentPurple: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accentPurple)
#else
        .init()
#endif
    }

    /// The "accentRed" asset catalog color.
    static var accentRed: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accentRed)
#else
        .init()
#endif
    }

    /// The "accentTeal" asset catalog color.
    static var accentTeal: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accentTeal)
#else
        .init()
#endif
    }

    /// The "bgBottom" asset catalog color.
    static var bgBottom: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bgBottom)
#else
        .init()
#endif
    }

    /// The "bgTop" asset catalog color.
    static var bgTop: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bgTop)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "accentBlue" asset catalog color.
    static var accentBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accentBlue)
#else
        .init()
#endif
    }

    /// The "accentGreen" asset catalog color.
    static var accentGreen: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accentGreen)
#else
        .init()
#endif
    }

    /// The "accentOrange" asset catalog color.
    static var accentOrange: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accentOrange)
#else
        .init()
#endif
    }

    /// The "accentPurple" asset catalog color.
    static var accentPurple: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accentPurple)
#else
        .init()
#endif
    }

    /// The "accentRed" asset catalog color.
    static var accentRed: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accentRed)
#else
        .init()
#endif
    }

    /// The "accentTeal" asset catalog color.
    static var accentTeal: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accentTeal)
#else
        .init()
#endif
    }

    /// The "bgBottom" asset catalog color.
    static var bgBottom: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .bgBottom)
#else
        .init()
#endif
    }

    /// The "bgTop" asset catalog color.
    static var bgTop: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .bgTop)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "accentBlue" asset catalog color.
    static var accentBlue: SwiftUI.Color { .init(.accentBlue) }

    /// The "accentGreen" asset catalog color.
    static var accentGreen: SwiftUI.Color { .init(.accentGreen) }

    /// The "accentOrange" asset catalog color.
    static var accentOrange: SwiftUI.Color { .init(.accentOrange) }

    /// The "accentPurple" asset catalog color.
    static var accentPurple: SwiftUI.Color { .init(.accentPurple) }

    /// The "accentRed" asset catalog color.
    static var accentRed: SwiftUI.Color { .init(.accentRed) }

    /// The "accentTeal" asset catalog color.
    static var accentTeal: SwiftUI.Color { .init(.accentTeal) }

    /// The "bgBottom" asset catalog color.
    static var bgBottom: SwiftUI.Color { .init(.bgBottom) }

    /// The "bgTop" asset catalog color.
    static var bgTop: SwiftUI.Color { .init(.bgTop) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "accentBlue" asset catalog color.
    static var accentBlue: SwiftUI.Color { .init(.accentBlue) }

    /// The "accentGreen" asset catalog color.
    static var accentGreen: SwiftUI.Color { .init(.accentGreen) }

    /// The "accentOrange" asset catalog color.
    static var accentOrange: SwiftUI.Color { .init(.accentOrange) }

    /// The "accentPurple" asset catalog color.
    static var accentPurple: SwiftUI.Color { .init(.accentPurple) }

    /// The "accentRed" asset catalog color.
    static var accentRed: SwiftUI.Color { .init(.accentRed) }

    /// The "accentTeal" asset catalog color.
    static var accentTeal: SwiftUI.Color { .init(.accentTeal) }

    /// The "bgBottom" asset catalog color.
    static var bgBottom: SwiftUI.Color { .init(.bgBottom) }

    /// The "bgTop" asset catalog color.
    static var bgTop: SwiftUI.Color { .init(.bgTop) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

