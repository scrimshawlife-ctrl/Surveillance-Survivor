import SwiftUI
import UIKit

// Hallmark · component: suspicion-meter · genre: atmospheric · theme: terminal-grid
// Solid tier ramp; no rainbow gradient bar (anti-pattern: gradient headline/meter).

struct SuspicionMeter: View {
    let value: Double
    let tier: Int
    var reducedMotion: Bool = false

    private var clampedValue: Double { min(100, max(0, value)) }
    private var clampedTier: Int { min(5, max(0, tier)) }

    var body: some View {
        VStack(alignment: .leading, spacing: VisualDesignTokens.space6) {
            HStack(spacing: VisualDesignTokens.space8) {
                TierGlyph(tier: clampedTier, reducedMotion: reducedMotion)
                VStack(alignment: .leading, spacing: VisualDesignTokens.space2) {
                    Text("SUSPICION")
                        .font(VisualDesignTokens.bodyBold(.caption2))
                        .foregroundStyle(VisualDesignTokens.inkMuted)
                    Text("TIER \(clampedTier) / 5")
                        .font(VisualDesignTokens.metric())
                        .foregroundStyle(VisualDesignTokens.ink)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(VisualDesignTokens.ruleSoft)
                    Capsule()
                        .fill(VisualDesignTokens.suspicionFill(tier: clampedTier))
                        .frame(width: max(4, proxy.size.width * clampedValue / 100))
                }
            }
            .frame(width: 190, height: 10)

            Text(tierLabel)
                .font(VisualDesignTokens.body(.caption2))
                .foregroundStyle(VisualDesignTokens.inkMuted)
                .lineLimit(1)
        }
        .padding(VisualDesignTokens.space10)
        .background(VisualDesignTokens.paper.opacity(0.88), in: RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter))
        .overlay(
            RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
                .strokeBorder(VisualDesignTokens.rule, lineWidth: 1)
        )
        .foregroundStyle(VisualDesignTokens.ink)
        .animation(reducedMotion ? nil : .easeOut(duration: 0.2), value: clampedTier)
        .animation(reducedMotion ? nil : .linear(duration: 0.12), value: clampedValue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Suspicion tier \(clampedTier) of 5")
        .accessibilityValue("\(Int(clampedValue)) percent, \(tierLabel)")
    }

    private var tierLabel: String {
        switch clampedTier {
        case 0: "BACKGROUND NOISE"
        case 1: "PERSON OF INTEREST"
        case 2: "PATTERN DETECTED"
        case 3: "COORDINATED RESPONSE"
        case 4: "NARRATIVE LOCK"
        default: "TOTAL VISIBILITY"
        }
    }
}

/// Glyph uses optional `suspicion_tier_N` textures from `VisualAssetMap` when present;
/// otherwise falls back to SF Symbol (native meter remains authority for bar/labels/a11y).
private struct TierGlyph: View {
    let tier: Int
    var reducedMotion: Bool = false

    private var assetName: String {
        VisualAssetMap.assetName(VisualAssetMap.suspicionRole(tier: tier))
    }

    private var glyphSize: CGSize {
        VisualAssetMap.entry(VisualAssetMap.suspicionRole(tier: tier)).displaySize
    }

    var body: some View {
        let size = glyphSize
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(VisualDesignTokens.rule, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(VisualDesignTokens.paperElevated)
                )
                .frame(width: size.width, height: size.height)
            if UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: size.width - 4, height: size.height - 4)
            } else {
                Image(systemName: tier >= 5 ? "eye.trianglebadge.exclamationmark.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(VisualDesignTokens.suspicionFill(tier: tier))
                    // Pulse only at high tiers; never bounce/overshoot; respect reduced motion.
                    .modifier(TierPulseModifier(tier: tier, reducedMotion: reducedMotion))
            }
        }
    }
}

private struct TierPulseModifier: ViewModifier {
    let tier: Int
    let reducedMotion: Bool

    func body(content: Content) -> some View {
        if reducedMotion || tier < 4 {
            content
        } else {
            content.symbolEffect(.pulse, options: .repeating, value: tier)
        }
    }
}
