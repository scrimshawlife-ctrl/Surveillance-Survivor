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
guard arguments.count == 1 else { fputs("usage: analyze_visual_matrix.swift ARTIFACT_ROOT\n", stderr); exit(64) }
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

let historyEntry: [String: Any] = [
    "schemaVersion": 1, "commit": receipt["commit"] as Any,
    "generatedAt": receipt["generatedAt"] as Any, "status": errors.isEmpty ? "pass" : "fail",
    "panelCount": panelRows.count, "comparisonCount": comparisons.count,
    "meanLumaMinimum": lumas.min() ?? 0, "meanLumaMaximum": lumas.max() ?? 0,
    "identicalVariantPairs": comparisons.filter { ($0["sameFingerprint"] as? Bool) == true }.count
]
let historyJSON = try JSONSerialization.data(withJSONObject: historyEntry, options: [.prettyPrinted, .sortedKeys])
try historyJSON.write(to: root.appendingPathComponent("visual-history-entry.json"))

var markdown = "# Visual matrix triage\n\n- Commit: `\(receipt["commit"] ?? "unknown")`\n- Panels: \(panelRows.count)\n- Paired comparisons: \(comparisons.count)\n- Status: **\(errors.isEmpty ? "PASS" : "FAIL")**\n- Policy: broad blank/flat-image checks only, not pixel-perfect acceptance.\n\n| District | Luma Δ | Contrast Δ | RGB Δ | Same fingerprint |\n|---|---:|---:|---:|:---:|\n"
for row in comparisons {
    markdown += "| \(row["district"]!) | \(row["meanLumaDelta"]!) | \(row["lumaStdDevDelta"]!) | \(row["meanRGBDelta"]!) | \((row["sameFingerprint"] as! Bool) ? "yes" : "no") |\n"
}
try markdown.write(to: root.appendingPathComponent("visual-triage.md"), atomically: true, encoding: .utf8)
if !errors.isEmpty { fputs("visual triage failed: \(errors.joined(separator: "; "))\n", stderr); exit(1) }
print("visual triage: PASS (\(panelRows.count) panels, \(comparisons.count) pairs)")
