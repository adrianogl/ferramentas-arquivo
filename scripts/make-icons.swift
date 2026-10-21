import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let resources = root.appendingPathComponent("Resources")
let artworkFraction: CGFloat = 0.82
let iconSizes: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

func color(_ hex: UInt32) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

func squarePath() -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 22, y: 6))
    path.addLine(to: CGPoint(x: 70, y: 6))
    path.addLine(to: CGPoint(x: 94, y: 30))
    path.addLine(to: CGPoint(x: 94, y: 78))
    path.addArc(tangent1End: CGPoint(x: 94, y: 94), tangent2End: CGPoint(x: 78, y: 94), radius: 16)
    path.addLine(to: CGPoint(x: 22, y: 94))
    path.addArc(tangent1End: CGPoint(x: 6, y: 94), tangent2End: CGPoint(x: 6, y: 78), radius: 16)
    path.addLine(to: CGPoint(x: 6, y: 22))
    path.addArc(tangent1End: CGPoint(x: 6, y: 6), tangent2End: CGPoint(x: 22, y: 6), radius: 16)
    path.closeSubpath()
    return path
}

func foldPath() -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 70, y: 6))
    path.addLine(to: CGPoint(x: 70, y: 22))
    path.addArc(tangent1End: CGPoint(x: 70, y: 30), tangent2End: CGPoint(x: 78, y: 30), radius: 8)
    path.addLine(to: CGPoint(x: 94, y: 30))
    path.closeSubpath()
    return path
}

func sectorPath(center: CGPoint, radius: CGFloat, width: CGFloat, start: CGFloat, sweep: CGFloat) -> CGPath {
    let outer = radius + width / 2
    let inner = radius - width / 2
    let end = start + sweep
    let path = CGMutablePath()
    path.addArc(center: center, radius: outer, startAngle: start, endAngle: end, clockwise: false)
    path.addLine(to: CGPoint(x: center.x + inner * cos(end), y: center.y + inner * sin(end)))
    path.addArc(center: center, radius: inner, startAngle: end, endAngle: start, clockwise: true)
    path.closeSubpath()
    return path
}

func drawArtwork(in context: CGContext, scale: CGFloat, offset: CGFloat, canvas: CGFloat) {
    context.saveGState()
    context.translateBy(x: offset, y: canvas - offset)
    context.scaleBy(x: scale, y: -scale)

    context.setFillColor(color(0x0B1B33))
    context.addPath(squarePath())
    context.fillPath()
    context.setFillColor(color(0x2F8CFF))
    context.addPath(foldPath())
    context.fillPath()

    let center = CGPoint(x: 50, y: 52)
    let radius: CGFloat = 22
    let sweep: CGFloat = 14.8 / radius
    for index in 0..<8 {
        let degrees = -110.5 + 45.0 * Double(index)
        let start = CGFloat(degrees * .pi / 180)
        let hex: UInt32 = index == 0 ? 0x2F8CFF : (index == 7 ? 0x34507A : 0xFFFFFF)
        context.setFillColor(color(hex))
        context.addPath(sectorPath(center: center, radius: radius, width: 11, start: start, sweep: sweep))
        context.fillPath()
    }
    context.restoreGState()
}

func writePNG(pixels: Int, to url: URL) throws {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(
        data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("contexto") }
    context.interpolationQuality = .high
    let canvas = CGFloat(pixels)
    let scale = canvas * artworkFraction / 100
    let offset = canvas * (1 - artworkFraction) / 2
    drawArtwork(in: context, scale: scale, offset: offset, canvas: canvas)
    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { fatalError("png") }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("png finalize") }
}

func writeMenuBarPDF(to url: URL) {
    var box = CGRect(x: 0, y: 0, width: 18, height: 18)
    guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { fatalError("pdf") }
    context.beginPDFPage(nil)
    let path = CGMutablePath()
    path.addPath(squarePath())
    path.addEllipse(in: CGRect(x: 50 - 26.5, y: 52 - 26.5, width: 53, height: 53))
    path.addEllipse(in: CGRect(x: 50 - 13.5, y: 52 - 13.5, width: 27, height: 27))
    context.translateBy(x: 0, y: 18)
    context.scaleBy(x: 0.18, y: -0.18)
    context.setFillColor(CGColor(gray: 0, alpha: 1))
    context.addPath(path)
    context.fillPath(using: .evenOdd)
    context.endPDFPage()
    context.closePDF()
}

let fileManager = FileManager.default
let iconset = fileManager.temporaryDirectory.appendingPathComponent("AppIcon-\(UUID().uuidString).iconset")
try fileManager.createDirectory(at: iconset, withIntermediateDirectories: true)
defer { try? fileManager.removeItem(at: iconset) }
for entry in iconSizes {
    try writePNG(pixels: entry.pixels, to: iconset.appendingPathComponent("\(entry.name).png"))
}
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", resources.appendingPathComponent("AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { fatalError("iconutil") }
writeMenuBarPDF(to: resources.appendingPathComponent("MenuBarIcon.pdf"))
print("ícones gerados em \(resources.path)")
