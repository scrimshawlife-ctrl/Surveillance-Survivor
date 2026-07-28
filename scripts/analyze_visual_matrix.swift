#!/usr/bin/env swift
import AppKit
import Foundation

struct Metrics {
    let meanLuma: Double
    let lumaStdDev: Double
    let darkFraction: Double
    let brightFraction: Double
    let meanRed: Double
    let meanGreen: Double
    let meanBlue: Double
    let fingerprint: String
}

func metrics(for path: String) throws -> Metrics {
    guard let image = NSImage(contentsOfFile: path) else { throw NSError(domain: "VisualTriage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot load \(path)"]) }
    let width = 64, height = 32
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: width * 4, bitsPerPixel: 32) else { throw NSError(domain: "VisualTriage", code: 2) }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    image.draw(in: NSRect(x: 0, y: 0, width: width, height: height), from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    var lumas = [Double](), red = 0.0, green = 0.0, blue = 0.0, dark = 0, bright = 0
    for y in 0..<height {
        for x in 0..<width {
            guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
            let r = Double(color.redComponent), g = Double(color.greenComponent), b = Double(color.blueComponent)
            let luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
            red += r; green += g; blue += b; lumas.append(luma)
            if luma < 0.03 { dark += 1 }
            if luma > 0.97 { bright += 1 }
        }
    }
    let count = Double(lumas.count)
    let mean = lumas.reduce(0, +) / count
    let variance = lumas.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / count
    var hash: UInt64 = 1469598103934665603
    for luma in lumas {
        hash ^= UInt64(max(0, min(255, Int((luma * 255).rounded()))))
        hash &*= 1099511628211
    }
    return Metrics(meanLuma: mean, lumaStdDev: sqrt(variance), darkFraction: Double(dark) / count, brightFraction: Double(bright) / count, meanRed: red / count, meanGreen: green / count, meanBlue: blue / count, fingerprint: String(format: "%016llx", hash))
}

func rounded(_ value: Double) -> Double { (value * 10_000).rounded() / 10_000 }
func metricJSON(_ value: Metrics) -> [String: Any] {[
    "meanLuma": rounded(value.meanLuma), "lumaStdDev": rounded(value.lumaStdDev),
    "darkFraction": rounded(value.darkFraction), "brightFraction": rounded(value.brightFraction),
    "meanRGB": [rounded(value.meanRed), rounded(value.meanGreen), rounded(value.meanBlue)],
    "fingerprint": value.fingerprint
]}

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments == ["--self-test"] {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 64, pixelsHigh: 32, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 64 * 4, bitsPerPixel: 32)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSColor.black.setFill()
    NSRect(x: 0, y: 0, width: 64, height: 32).fill()
    NSGraphicsContext.restoreGraphicsState()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("surveillance-visual-triage-flat.png")
    try bitmap.representation(using: .png, properties: [:])!.write(to: url)
    let value = try metrics(for: url.path)
    try? FileManager.default.removeItem(at: url)
    guard value.lumaStdDev < 0.035, value.darkFraction > 0.96 else {
        fputs("visual triage self-test failed\n", stderr); exit(1)
    }
    print("visual triage self-test: PASS")
    exit(0)
}
guard arguments.count == 1 || arguments.count == 2 else { fputs("usage: analyze_visual_matrix.swift ARTIFACT_ROOT [BASELINE_HISTORY_JSON]\n", stderr); exit(64) }
let root = URL(fileURLWithPath: arguments[0])
let receiptURL = root.appendingPathComponent("matrix-receipt.json")
let receipt = try JSONSerialization.jsonObject(with: Data(contentsOf: receiptURL)) as! [String: Any]
let panels = receipt["panels"] as! [[String: Any]]
var panelRows = [[String: Any]](), byDistrict = [String: [String: Metrics]](), errors = [String]()
for panel in panels {
    let district = panel["district"] as! String, variant = panel["variant"] as! String
    let relative = panel["screenshot"] as! String
    let value = try metrics(for: root.appendingPathComponent(relative).path)
    if value.lumaStdDev < 0.035 { errors.append("\(variant)/\(district): suspiciously flat image") }
    if value.darkFraction > 0.96 { errors.append("\(variant)/\(district): image is nearly all black") }
    if value.brightFraction > 0.96 { errors.append("\(variant)/\(district): image is nearly all white") }
    byDistrict[district, default: [:]][variant] = value
    panelRows.append(["district": district, "variant": variant, "metrics": metricJSON(value)])
}

var comparisons = [[String: Any]]()
for district in byDistrict.keys.sorted() {
    guard let combat = byDistrict[district]?["combat"], let reduced = byDistrict[district]?["reduced"] else {
        errors.append("\(district): missing paired variants"); continue
    }
    comparisons.append([
        "district": district,
        "meanLumaDelta": rounded(abs(combat.meanLuma - reduced.meanLuma)),
        "lumaStdDevDelta": rounded(abs(combat.lumaStdDev - reduced.lumaStdDev)),
        "meanRGBDelta": rounded((abs(combat.meanRed - reduced.meanRed) + abs(combat.meanGreen - reduced.meanGreen) + abs(combat.meanBlue - reduced.meanBlue)) / 3),
        "sameFingerprint": combat.fingerprint == reduced.fingerprint
    ])
}
let lumas = panelRows.compactMap { (($0["metrics"] as? [String: Any])?["meanLuma"] as? Double) }
let summary: [String: Any] = [
    "schemaVersion": 1, "status": errors.isEmpty ? "pass" : "fail",
    "commit": receipt["commit"] as Any, "generatedAt": receipt["generatedAt"] as Any,
    "panelCount": panelRows.count, "comparisonCount": comparisons.count,
    "meanLumaRange": [lumas.min() ?? 0, lumas.max() ?? 0],
    "panels": panelRows, "variantComparisons": comparisons, "errors": errors,
    "policy": "Triage metrics and broad blank/flat-image sanity bounds only; no pixel-perfect golden or release gate."
]
let json = try JSONSerialization.data(withJSONObject: summary, options: [.prettyPrinted, .sortedKeys])
try json.write(to: root.appendingPathComponent("visual-triage.json"))

var perCityHistory = [String: [String: [String: Any]]]()
for row in panelRows {
    let district = row["district"] as! String, variant = row["variant"] as! String
    let metrics = row["metrics"] as! [String: Any]
    perCityHistory[district, default: [:]][variant] = [
        "meanLuma": metrics["meanLuma"]!, "lumaStdDev": metrics["lumaStdDev"]!,
        "fingerprint": metrics["fingerprint"]!
    ]
}
let historyEntry: [String: Any] = [
    "schemaVersion": 2, "commit": receipt["commit"] as Any,
    "generatedAt": receipt["generatedAt"] as Any, "status": errors.isEmpty ? "pass" : "fail",
    "panelCount": panelRows.count, "comparisonCount": comparisons.count,
    "meanLumaMinimum": lumas.min() ?? 0, "meanLumaMaximum": lumas.max() ?? 0,
    "identicalVariantPairs": comparisons.filter { ($0["sameFingerprint"] as? Bool) == true }.count,
    "perCity": perCityHistory
]
let historyJSON = try JSONSerialization.data(withJSONObject: historyEntry, options: [.prettyPrinted, .sortedKeys])
try historyJSON.write(to: root.appendingPathComponent("visual-history-entry.json"))

let baselinePath = arguments.count == 2 ? arguments[1] : nil
var trend: [String: Any] = [
    "schemaVersion": 1, "status": "no-baseline", "currentCommit": receipt["commit"] as Any,
    "baselineCommit": NSNull(), "deltas": [:], "annotations": [],
    "policy": "Advisory cross-run trend only; visual drift never fails CI."
]
var cityAnomalies = [[String: Any]]()
var baselineCompatibility = "none"
if let baselinePath, FileManager.default.fileExists(atPath: baselinePath) {
    let baseline = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: baselinePath))) as! [String: Any]
    func number(_ key: String, in object: [String: Any]) -> Double { (object[key] as? NSNumber)?.doubleValue ?? 0 }
    let minDelta = (lumas.min() ?? 0) - number("meanLumaMinimum", in: baseline)
    let maxDelta = (lumas.max() ?? 0) - number("meanLumaMaximum", in: baseline)
    let identicalDelta = Double(historyEntry["identicalVariantPairs"] as! Int) - number("identicalVariantPairs", in: baseline)
    var annotations = [String]()
    if abs(minDelta) > 0.04 || abs(maxDelta) > 0.04 { annotations.append("large aggregate luminance-range shift; inspect contact sheet") }
    if abs(identicalDelta) >= 3 { annotations.append("paired-variant fingerprint behavior changed materially") }
    if let baselineCities = baseline["perCity"] as? [String: Any] {
        baselineCompatibility = "per-city"
        for district in perCityHistory.keys.sorted() {
            guard let baselineDistrict = baselineCities[district] as? [String: Any] else { continue }
            var variantRows = [[String: Any]]()
            for variant in ["combat", "reduced"] {
                guard let current = perCityHistory[district]?[variant],
                      let prior = baselineDistrict[variant] as? [String: Any] else { continue }
                let lumaDelta = number("meanLuma", in: current) - number("meanLuma", in: prior)
                let contrastDelta = number("lumaStdDev", in: current) - number("lumaStdDev", in: prior)
                if abs(lumaDelta) > 0.025 || abs(contrastDelta) > 0.025 {
                    variantRows.append(["variant": variant, "meanLumaDelta": rounded(lumaDelta), "lumaStdDevDelta": rounded(contrastDelta)])
                }
            }
            if !variantRows.isEmpty {
                cityAnomalies.append(["district": district, "variants": variantRows,
                    "combatPanel": "combat/\(district)/launch-landscape.png",
                    "reducedPanel": "reduced/\(district)/launch-landscape.png"])
            }
        }
        if !cityAnomalies.isEmpty { annotations.append("city-level visual shifts detected in \(cityAnomalies.count) district(s)") }
    } else {
        baselineCompatibility = "legacy-aggregate"
    }
    trend = [
        "schemaVersion": 1, "status": annotations.isEmpty ? "stable" : "review",
        "currentCommit": receipt["commit"] as Any, "baselineCommit": baseline["commit"] as Any,
        "deltas": ["meanLumaMinimum": rounded(minDelta), "meanLumaMaximum": rounded(maxDelta), "identicalVariantPairs": Int(identicalDelta)],
        "annotations": annotations, "cityAnomalies": cityAnomalies,
        "baselineCompatibility": baselineCompatibility,
        "policy": "Advisory cross-run trend only; visual drift never fails CI."
    ]
}
let trendJSON = try JSONSerialization.data(withJSONObject: trend, options: [.prettyPrinted, .sortedKeys])
try trendJSON.write(to: root.appendingPathComponent("visual-trend.json"))
let trendAnnotations = (trend["annotations"] as? [String]) ?? []
let currentCommit = trend["currentCommit"] as? String ?? "unknown"
let baselineCommit = trend["baselineCommit"] as? String ?? "none"
let trendMarkdown = """
    # Visual history trend

    - Current commit: `\(currentCommit)`
    - Baseline commit: `\(baselineCommit)`
    - Status: **\(String(describing: trend["status"]!))**
    - Policy: advisory only; visual drift does not fail CI.

    \(trendAnnotations.isEmpty ? "No anomaly annotations." : trendAnnotations.map { "- ⚠️ \($0)" }.joined(separator: "\n"))
    """
try trendMarkdown.write(to: root.appendingPathComponent("visual-trend.md"), atomically: true, encoding: .utf8)

let bundleStatus = cityAnomalies.isEmpty ? (baselineCompatibility == "legacy-aggregate" ? "legacy-baseline" : "none") : "review"
let bundle: [String: Any] = [
    "schemaVersion": 1, "status": bundleStatus, "currentCommit": currentCommit,
    "baselineCommit": baselineCommit, "baselineCompatibility": baselineCompatibility,
    "districts": cityAnomalies, "contactSheet": "contact-sheet.jpg",
    "policy": "Reviewer aid only; anomaly bundles never fail CI."
]
let bundleJSON = try JSONSerialization.data(withJSONObject: bundle, options: [.prettyPrinted, .sortedKeys])
try bundleJSON.write(to: root.appendingPathComponent("anomaly-review.json"))
var bundleMarkdown = "# Visual anomaly review\n\n- Status: **\(bundleStatus)**\n- Current: `\(currentCommit)`\n- Baseline: `\(baselineCommit)`\n- Compatibility: `\(baselineCompatibility)`\n- Policy: reviewer aid only; never a visual-drift release gate.\n\n"
if cityAnomalies.isEmpty {
    bundleMarkdown += "No city-level anomalies. Review [the full contact sheet](contact-sheet.jpg) if needed.\n"
} else {
    for anomaly in cityAnomalies {
        let district = anomaly["district"] as! String
        bundleMarkdown += "## \(district)\n\n- [Combat panel](combat/\(district)/launch-landscape.png)\n- [Reduced panel](reduced/\(district)/launch-landscape.png)\n\n"
    }
}
try bundleMarkdown.write(to: root.appendingPathComponent("anomaly-review.md"), atomically: true, encoding: .utf8)
let cards = cityAnomalies.map { anomaly -> String in
    let district = anomaly["district"] as! String
    return "<section><h2>\(district)</h2><figure><img src=\"combat/\(district)/launch-landscape.png\"><figcaption>combat</figcaption></figure><figure><img src=\"reduced/\(district)/launch-landscape.png\"><figcaption>reduced</figcaption></figure></section>"
}.joined(separator: "\n")
let htmlBody = cards.isEmpty ? "<p>No city-level anomalies.</p><img class=\"sheet\" src=\"contact-sheet.jpg\">" : cards
let html = """
<!doctype html><meta charset="utf-8"><title>Visual anomaly review</title>
<style>body{font:16px -apple-system;background:#111;color:#eee;margin:24px}section{border-top:1px solid #555;margin-top:24px}figure{display:inline-block;width:48%;margin:1%}img{max-width:100%;height:auto}.sheet{width:100%}code{color:#5ee}</style>
<h1>Visual anomaly review</h1><p>Status: <strong>\(bundleStatus)</strong> · current <code>\(currentCommit)</code> · baseline <code>\(baselineCommit)</code></p><p>Advisory reviewer aid only. Visual drift never fails CI.</p>\(htmlBody)
"""
try html.write(to: root.appendingPathComponent("anomaly-review.html"), atomically: true, encoding: .utf8)

var markdown = "# Visual matrix triage\n\n- Commit: `\(receipt["commit"] ?? "unknown")`\n- Panels: \(panelRows.count)\n- Paired comparisons: \(comparisons.count)\n- Status: **\(errors.isEmpty ? "PASS" : "FAIL")**\n- Policy: broad blank/flat-image checks only, not pixel-perfect acceptance.\n\n| District | Luma Δ | Contrast Δ | RGB Δ | Same fingerprint |\n|---|---:|---:|---:|:---:|\n"
for row in comparisons {
    markdown += "| \(row["district"]!) | \(row["meanLumaDelta"]!) | \(row["lumaStdDevDelta"]!) | \(row["meanRGBDelta"]!) | \((row["sameFingerprint"] as! Bool) ? "yes" : "no") |\n"
}
try markdown.write(to: root.appendingPathComponent("visual-triage.md"), atomically: true, encoding: .utf8)
if !errors.isEmpty { fputs("visual triage failed: \(errors.joined(separator: "; "))\n", stderr); exit(1) }
print("visual triage: PASS (\(panelRows.count) panels, \(comparisons.count) pairs)")
