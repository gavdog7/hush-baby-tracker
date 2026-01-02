import SwiftUI

extension Color {
    // MARK: - Event Colors (per PRD specifications)

    /// Sleep events - soft purple
    static let sleep = Color(light: Color(hex: "9B8AA5"), dark: Color(hex: "7A6B82"))

    /// Eat events - soft green
    static let eat = Color(light: Color(hex: "7BAE7F"), dark: Color(hex: "5E8A61"))

    /// Diaper events - soft amber
    static let diaper = Color(light: Color(hex: "E5C07B"), dark: Color(hex: "B8995F"))

    // MARK: - Expiry Warning Colors

    /// Safe - more than 30 minutes remaining
    static let expirySafe = Color.green

    /// Warning - 15-30 minutes remaining
    static let expiryWarning = Color.yellow

    /// Urgent - less than 15 minutes remaining
    static let expiryUrgent = Color.red

    /// Expired - grey strikethrough
    static let expiryExpired = Color.gray

    // MARK: - Helpers

    /// Creates an adaptive color that changes between light and dark mode
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    /// Creates a color from a hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Dark Mode Background

extension Color {
    /// True black for OLED optimization in dark mode
    static let darkBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.black : UIColor.systemBackground
    })
}
