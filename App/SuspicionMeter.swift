import SwiftUI
import UIKit

struct SuspicionMeter: View {
    let value: Double
    let tier: Int

    private var clampedValue: Double { min(100, max(0, value)) }
    private var clampedTier: Int { min(5, max(0, tier)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                TierGlyph(tier: clampedTier)
                VStack(alignment: .leading, spacing: 0) {
                    Text("SUSPICION")
                        .font(.caption2.bold().monospaced())
                    Text("TIER \(clampedTier) / 5")
                        .font(.headline.bold().monospacedDigit())
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule()
                        .fill(fillStyle)
                        .frame(width: proxy.size.width * clampedValue / 100)
                }
            }
            .frame(width: 190, height: 10)

            Text(tierLabel)
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.78))
        }
        .padding(10)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(.white)
        .animation(.snappy(duration: 0.24), value: clampedTier)
        .animation(.linear(duration: 0.12), value: clampedValue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Suspicion tier \(clampedTier) of 5")
        .accessibilityValue("\(Int(clampedValue)) percent, \(tierLabel)")
    }

    private var fillStyle: AnyShapeStyle {
        switch clampedTier {
        case 0: AnyShapeStyle(.cyan)
        case 1: AnyShapeStyle(.mint)
        case 2: AnyShapeStyle(.yellow)
        case 3: AnyShapeStyle(.orange)
        case 4: AnyShapeStyle(.red)
        default: AnyShapeStyle(LinearGradient(colors: [.red, .purple, .cyan], startPoint: .leading, endPoint: .trailing))
        }
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
                .strokeBorder(.white.opacity(0.35), lineWidth: 1)
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
                    .symbolEffect(.pulse, options: tier >= 4 ? .repeating : .nonRepeating, value: tier)
            }
        }
    }
}
