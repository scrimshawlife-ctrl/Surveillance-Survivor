import SwiftUI
import UIKit

// Hallmark · component: design-tokens · genre: atmospheric · theme: terminal-grid
// pre-emit critique: P4 H4 E4 S5 R5 V3
// Locked surface tokens for SwiftUI HUD / overlays. SpriteKit world art stays in VisualAssetMap.
// Every HUD color/font reference should come through this file (no mid-render improvisation).

enum VisualDesignTokens {
    // MARK: Surfaces (tinted — not pure black / pure white)

    /// Primary paper for panels. Slight blue-ink cast over pure black.
    static let paper = Color(red: 0.06, green: 0.08, blue: 0.10)
    static let paperElevated = Color(red: 0.10, green: 0.13, blue: 0.16)
    static let paperDimmer = Color(red: 0.02, green: 0.03, blue: 0.04).opacity(0.72)

    // MARK: Ink

    static let ink = Color(red: 0.92, green: 0.94, blue: 0.96)
    static let inkMuted = Color(red: 0.92, green: 0.94, blue: 0.96).opacity(0.72)
    static let inkFaint = Color(red: 0.92, green: 0.94, blue: 0.96).opacity(0.55)
    static let inkDisabled = Color(red: 0.92, green: 0.94, blue: 0.96).opacity(0.35)

    // MARK: Accents (single cool phosphor + warm alarm — no rainbow)

    /// Primary interactive / objective accent.
    static let accent = Color(red: 0.25, green: 0.86, blue: 0.90)
    static let accentSoft = Color(red: 0.25, green: 0.86, blue: 0.90).opacity(0.85)
    static let accentDim = Color(red: 0.25, green: 0.86, blue: 0.90).opacity(0.55)

    /// Threat / defeat / critical integrity.
    static let alarm = Color(red: 0.92, green: 0.28, blue: 0.32)
    static let alarmSoft = Color(red: 0.92, green: 0.28, blue: 0.32).opacity(0.85)

    /// Boss / elevated pressure (warm, not rainbow).
    static let warning = Color(red: 0.95, green: 0.62, blue: 0.22)

    /// Hairline rules on dark panels.
    static let rule = Color.white.opacity(0.28)
    static let ruleSoft = Color.white.opacity(0.14)

    // MARK: Suspicion tier ramp (solid steps — no multi-hue gradient bar)

    static func suspicionFill(tier: Int) -> Color {
        switch min(5, max(0, tier)) {
        case 0: return accent
        case 1: return Color(red: 0.35, green: 0.78, blue: 0.72)
        case 2: return Color(red: 0.88, green: 0.78, blue: 0.28)
        case 3: return warning
        case 4: return Color(red: 0.92, green: 0.42, blue: 0.22)
        default: return alarm
        }
    }

    // MARK: Spacing (4pt scale)

    static let space2: CGFloat = 2
    static let space4: CGFloat = 4
    static let space6: CGFloat = 6
    static let space8: CGFloat = 8
    static let space10: CGFloat = 10
    static let space14: CGFloat = 14
    static let space16: CGFloat = 16
    static let space24: CGFloat = 24

    static let radiusPanel: CGFloat = 12
    static let radiusMeter: CGFloat = 8
    static let radiusChrome: CGFloat = 22

    // MARK: Type (system monospaced for terminal-grid voice; roman headers only)

    static func display(_ style: Font.TextStyle = .headline) -> Font {
        .system(style, design: .monospaced).weight(.bold)
    }

    static func body(_ style: Font.TextStyle = .caption) -> Font {
        .system(style, design: .monospaced)
    }

    static func bodyBold(_ style: Font.TextStyle = .caption) -> Font {
        .system(style, design: .monospaced).weight(.bold)
    }

    static func metric() -> Font {
        .system(.caption, design: .monospaced).weight(.bold).monospacedDigit()
    }

    // MARK: SpriteKit bridge

    /// Auto-fire target acquisition. Distinct from damage/status colours so the
    /// reticle is not mistaken for a hit or a debuff.
    static var skTargetReticle: UIColor {
        UIColor(red: 0.35, green: 0.95, blue: 0.85, alpha: 1)
    }

    /// Blind Spot wayfinding. Matches the extraction decal's cyan so the marker and
    /// the thing it points at read as the same object.
    static var skBlindSpot: UIColor {
        UIColor(red: 0.25, green: 0.86, blue: 0.90, alpha: 0.95)
    }

    static var skPaper: UIColor {
        UIColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 1)
    }
}
