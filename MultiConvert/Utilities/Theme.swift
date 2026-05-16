import SwiftUI

// Distinct palette — dark charcoal + amber accent, not Apple's exact Calculator colors.
enum Theme {
    // Backgrounds
    static let appBackground   = Color(hex: "#1A1A1F")
    static let cardBackground  = Color(hex: "#26262D")
    static let displayBg       = Color(hex: "#111116")

    // Buttons
    static let digitButton     = Color(hex: "#2E2E38")
    static let operatorButton  = Color(hex: "#E8923C")
    static let utilityButton   = Color(hex: "#3A3A45")
    static let buttonPressed   = Color(hex: "#4A4A58")

    // Text
    static let primaryText     = Color(hex: "#F0EFE8")
    static let secondaryText   = Color(hex: "#9A9AA8")
    static let accentText      = Color(hex: "#E8923C")
    static let cryptoBadge     = Color(hex: "#3A8AD4")
    static let fiatBadge       = Color(hex: "#3AB87A")

    // Staleness indicator
    static let staleWarning    = Color(hex: "#C85A2A")

    // Typography
    static let displayFont     = Font.system(size: 56, weight: .thin, design: .rounded)
    static let conversionFont  = Font.system(size: 22, weight: .light, design: .rounded)
    static let labelFont       = Font.system(size: 13, weight: .medium, design: .rounded)
    static let keypadFont      = Font.system(size: 28, weight: .regular, design: .rounded)
    static let badgeFont       = Font.system(size: 9, weight: .bold, design: .rounded)
}

extension Color {
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        let scanner = Scanner(string: cleaned)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
