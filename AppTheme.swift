// AppTheme.swift
// Folder: LifeQuest/Sources/
// Design system: colors, gradients, glass modifier, typography, spacing.
// Used by every view — keep this as the single source of truth for aesthetics.

import SwiftUI

// MARK: - Color hex initialiser (3 / 6 / 8 hex chars)

extension Color {
    init(hex: String) {
        let raw = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch raw.count {
        case 3:  (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6:  (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:  (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - AppTheme

enum AppTheme {

    // ── Gradients ─────────────────────────────────────────────────────────────

    static let cyberZen = LinearGradient(
        colors: [Color(hex: "0F2027"), Color(hex: "203A43"), Color(hex: "2C5364")],
        startPoint: .top,
        endPoint:   .bottom
    )

    static let goldenHour = LinearGradient(
        colors: [Color(hex: "1A0A00"), Color(hex: "7B3F00"), Color(hex: "E58A2B"), Color(hex: "F2C078")],
        startPoint: .bottomLeading,
        endPoint:   .topTrailing
    )

    static let introBackground = LinearGradient(
        colors: [Color(hex: "0B0B0D"), Color(hex: "141416")],
        startPoint: .top,
        endPoint:   .bottom
    )

    // ── Accent colours ────────────────────────────────────────────────────────

    static let cyberAccent  = Color(hex: "00D2FF")
    static let scoutAccent  = Color(hex: "F2994A")
    static let mutedLabel   = Color(hex: "A6B0BD")
    static let cardSurface  = Color.white.opacity(0.07)

    // ── Fog circle colours (IntroView / LivingBackground) ─────────────────────

    static let fogTeal  = Color(hex: "00D2FF").opacity(0.18)
    static let fogAmber = Color(hex: "F2994A").opacity(0.18)

    // ── Typography ────────────────────────────────────────────────────────────

    static func displayFont(size: CGFloat = 52) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func headlineFont(size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func bodyFont(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func captionFont(size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    // ── Corner radii ──────────────────────────────────────────────────────────

    static let cardRadius:   CGFloat = 20
    static let buttonRadius: CGFloat = 14
    static let avatarRadius: CGFloat = 40

    // ── Spacing ───────────────────────────────────────────────────────────────

    static let screenPad: CGFloat  = 24
    static let sectionGap: CGFloat = 20
}

// MARK: - GlassCard modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cardRadius
    var borderColor: Color    = Color.white.opacity(0.14)

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = AppTheme.cardRadius) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - FogCircle helper

struct FogCircle: View {
    let color: Color
    let size: CGFloat
    var offset: CGSize = .zero

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size * 0.5)
            .offset(offset)
    }
}
