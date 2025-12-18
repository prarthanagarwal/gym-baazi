import SwiftUI

/// Font manager for Outfit font family
struct AppFont {
    /// Outfit Regular
    static func regular(size: CGFloat) -> Font {
        .custom("Outfit-Regular", size: size)
    }
    
    /// Outfit Medium
    static func medium(size: CGFloat) -> Font {
        .custom("Outfit-Medium", size: size)
    }
    
    /// Outfit SemiBold
    static func semiBold(size: CGFloat) -> Font {
        .custom("Outfit-SemiBold", size: size)
    }
    
    /// Outfit Bold
    static func bold(size: CGFloat) -> Font {
        .custom("Outfit-Bold", size: size)
    }
}

/// Extension to easily apply Outfit font styles
public extension Font {
    // MARK: - Title Styles (30px)
    static let appTitle = AppFont.bold(size: 30)
    static let appTitleRegular = AppFont.regular(size: 30)
    
    // MARK: - Heading Styles (22px)
    static let appHeading = AppFont.semiBold(size: 22)
    static let appHeadingBold = AppFont.bold(size: 22)
    
    // MARK: - Body Styles (18px)
    static let appBody = AppFont.regular(size: 18)
    static let appBodyMedium = AppFont.medium(size: 18)
    static let appBodyBold = AppFont.bold(size: 18)
    
    // MARK: - Custom Sizes
    static func outfit(_ size: CGFloat, weight: OutfitWeight = .regular) -> Font {
        switch weight {
        case .regular:
            return AppFont.regular(size: size)
        case .medium:
            return AppFont.medium(size: size)
        case .semiBold:
            return AppFont.semiBold(size: size)
        case .bold:
            return AppFont.bold(size: size)
        }
    }
}

public enum OutfitWeight {
    case regular
    case medium
    case semiBold
    case bold
}
