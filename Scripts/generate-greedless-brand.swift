// SPDX-License-Identifier: GPL-2.0-only

import AppKit
import CoreGraphics
import Foundation

private let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
private let deepGreen = CGColor(srgbRed: 14 / 255, green: 63 / 255, blue: 53 / 255, alpha: 1)
private let ivory = CGColor(srgbRed: 247 / 255, green: 244 / 255, blue: 232 / 255, alpha: 1)
private let black = CGColor(gray: 0, alpha: 1)
private let white = CGColor(gray: 1, alpha: 1)

private func roundedRectangle(_ context: CGContext, _ rect: CGRect, radius: CGFloat, color: CGColor) {
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.setFillColor(color)
    context.fillPath()
}

private func drawColumns(_ context: CGContext, in square: CGRect, color: CGColor) {
    context.saveGState()
    context.translateBy(x: square.minX, y: square.minY)
    context.scaleBy(x: square.width / 1024, y: square.height / 1024)
    roundedRectangle(context, CGRect(x: 215, y: 335, width: 157, height: 354), radius: 26, color: color)
    roundedRectangle(context, CGRect(x: 405, y: 252, width: 214, height: 520), radius: 30, color: color)
    roundedRectangle(context, CGRect(x: 652, y: 335, width: 157, height: 354), radius: 26, color: color)
    context.restoreGState()
}

private func drawIcon(_ context: CGContext, side: CGFloat) {
    context.saveGState()
    context.scaleBy(x: side / 1024, y: side / 1024)
    roundedRectangle(context, CGRect(x: 84, y: 84, width: 856, height: 856), radius: 190, color: deepGreen)
    drawColumns(context, in: CGRect(x: 0, y: 0, width: 1024, height: 1024), color: ivory)
    context.restoreGState()
}

private func drawStatus(_ context: CGContext, in square: CGRect, color: CGColor) {
    context.saveGState()
    context.translateBy(x: square.minX, y: square.minY)
    context.scaleBy(x: square.width / 18, y: square.height / 18)
    roundedRectangle(context, CGRect(x: 1.2, y: 4.6, width: 3.6, height: 8.8), radius: 0.55, color: color)
    roundedRectangle(context, CGRect(x: 6.3, y: 2, width: 5.4, height: 14), radius: 0.7, color: color)
    roundedRectangle(context, CGRect(x: 13.2, y: 4.6, width: 3.6, height: 8.8), radius: 0.55, color: color)
    context.restoreGState()
}

private func bitmap(width: Int, height: Int, draw: (CGContext) -> Void) throws -> Data {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ), let image = { () -> CGImage? in
        draw(context)
        return context.makeImage()
    }(), let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
        throw NSError(domain: "GreedlessBrand", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not render PNG"])
    }
    return png
}

private func pdf(at destination: URL, size: CGSize, draw: (CGContext) -> Void) throws {
    var box = CGRect(origin: .zero, size: size)
    guard let context = CGContext(destination as CFURL, mediaBox: &box, nil) else {
        throw NSError(domain: "GreedlessBrand", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create PDF"])
    }
    context.beginPDFPage(nil)
    draw(context)
    context.endPDFPage()
    context.closePDF()
}

private func drawLockup(_ context: CGContext) {
    drawStatus(context, in: CGRect(x: 59, y: 60, width: 72, height: 72), color: white)
    let title = "Greedless Manager" as NSString
    let textX: CGFloat = 158
    let maximumWidth: CGFloat = 600 - textX - 36
    var pointSize: CGFloat = 44
    var attributes: [NSAttributedString.Key: Any] = [:]
    var textSize = NSSize.zero
    repeat {
        attributes = [
            .font: NSFont.systemFont(ofSize: pointSize, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        textSize = title.size(withAttributes: attributes)
        if textSize.width <= maximumWidth { break }
        pointSize -= 1
    } while pointSize >= 34
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    title.draw(at: NSPoint(x: textX, y: (192 - textSize.height) / 2), withAttributes: attributes)
    NSGraphicsContext.restoreGraphicsState()
}

private func generate() throws {
    let fileManager = FileManager.default
    let iconDestination = root.appendingPathComponent("Resources/GreedlessIcon.icns")
    let statusDestination = root.appendingPathComponent("Sources/OmniWM/Resources/GreedlessStatusTemplate.pdf")
    let lockupDestination = root.appendingPathComponent("Sources/OmniWM/Resources/GreedlessLaunchLockup.pdf")
    let temporary = fileManager.temporaryDirectory.appendingPathComponent("GreedlessIcon-\(UUID().uuidString).iconset")
    try fileManager.createDirectory(at: temporary, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: temporary) }

    let representations: [(String, Int)] = [
        ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
    ]
    for (name, pixels) in representations {
        let png = try bitmap(width: pixels, height: pixels) { context in
            drawIcon(context, side: CGFloat(pixels))
        }
        try png.write(to: temporary.appendingPathComponent(name))
    }

    let iconutil = Process()
    iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    iconutil.arguments = ["-c", "icns", temporary.path, "-o", iconDestination.path]
    try iconutil.run()
    iconutil.waitUntilExit()
    guard iconutil.terminationStatus == 0 else {
        throw NSError(domain: "GreedlessBrand", code: 3, userInfo: [NSLocalizedDescriptionKey: "iconutil failed"])
    }

    try pdf(at: statusDestination, size: CGSize(width: 18, height: 18)) { context in
        drawStatus(context, in: CGRect(x: 0, y: 0, width: 18, height: 18), color: black)
    }
    try pdf(at: lockupDestination, size: CGSize(width: 600, height: 192), draw: drawLockup)

    if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--proof" {
        let proof = URL(fileURLWithPath: CommandLine.arguments[2])
        let png = try bitmap(width: 960, height: 400) { context in
            context.setFillColor(CGColor(gray: 0.95, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 480, height: 400))
            context.setFillColor(CGColor(srgbRed: 0.09, green: 0.11, blue: 0.11, alpha: 1))
            context.fill(CGRect(x: 480, y: 0, width: 480, height: 400))
            context.saveGState()
            context.translateBy(x: 70, y: 110)
            drawIcon(context, side: 220)
            context.restoreGState()
            drawStatus(context, in: CGRect(x: 345, y: 220, width: 72, height: 72), color: black)
            drawStatus(context, in: CGRect(x: 545, y: 220, width: 72, height: 72), color: white)
            context.saveGState()
            context.translateBy(x: 565, y: 15)
            context.scaleBy(x: 0.6, y: 0.6)
            drawLockup(context)
            context.restoreGState()
        }
        try png.write(to: proof)
        print("Proof: \(proof.path)")
    }
    print("Generated Greedless Manager icon, status template, and launch lockup")
}

do {
    try generate()
} catch {
    fputs("generate-greedless-brand: \(error)\n", stderr)
    exit(1)
}
