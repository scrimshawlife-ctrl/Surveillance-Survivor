#!/usr/bin/env swift
import AppKit
import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count >= 3, arguments.count.isMultiple(of: 2) == false else {
    fputs("usage: generate_visual_contact_sheet.swift OUTPUT LABEL IMAGE [LABEL IMAGE ...]\n", stderr)
    exit(64)
}

let outputURL = URL(fileURLWithPath: arguments[0])
let pairs = stride(from: 1, to: arguments.count, by: 2).map { (arguments[$0], arguments[$0 + 1]) }
let columns = 2
let cellWidth = 720
let imageHeight = 330
let labelHeight = 38
let cellHeight = imageHeight + labelHeight
let rows = Int(ceil(Double(pairs.count) / Double(columns)))
let canvas = NSImage(size: NSSize(width: columns * cellWidth, height: rows * cellHeight))
canvas.lockFocus()
NSColor(calibratedWhite: 0.055, alpha: 1).setFill()
NSRect(origin: .zero, size: canvas.size).fill()

let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 20, weight: .semibold),
    .foregroundColor: NSColor.white
]

for (index, pair) in pairs.enumerated() {
    guard let image = NSImage(contentsOfFile: pair.1) else {
        fputs("missing contact-sheet image: \(pair.1)\n", stderr)
        exit(66)
    }
    let column = index % columns
    let row = index / columns
    let x = column * cellWidth
    let y = (rows - row - 1) * cellHeight
    (pair.0 as NSString).draw(in: NSRect(x: x + 12, y: y + imageHeight + 7, width: cellWidth - 24, height: labelHeight - 8), withAttributes: attributes)
    image.draw(in: NSRect(x: x, y: y, width: cellWidth, height: imageHeight), from: .zero, operation: .copy, fraction: 1)
}
canvas.unlockFocus()

guard let tiff = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.84]) else {
    fputs("unable to encode contact sheet\n", stderr)
    exit(70)
}
try jpeg.write(to: outputURL)
print("contact sheet: \(outputURL.path) (\(pairs.count) panels)")
