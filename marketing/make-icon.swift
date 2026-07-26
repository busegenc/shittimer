import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

let px = 1024.0
let cs = CGColorSpaceCreateDeviceRGB()
// alfa yok: App Store ikonu saydamlık kabul etmiyor
guard let ctx = CGContext(data: nil, width: Int(px), height: Int(px), bitsPerComponent: 8,
                          bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { exit(1) }

// 1) Kahverengi degrade zemin (uygulamanın Kaka teması)
let grad = CGGradient(colorsSpace: cs,
                      colors: [CGColor(red: 0.30, green: 0.18, blue: 0.10, alpha: 1),
                               CGColor(red: 0.09, green: 0.05, blue: 0.02, alpha: 1)] as CFArray,
                      locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: px), end: CGPoint(x: 0, y: 0), options: [])

// 2) Altın ilerleme halkası — uygulamadaki sayaç halkasının aynısı
let center = CGPoint(x: px / 2, y: px / 2)
let radius = px * 0.335
ctx.setLineCap(.round)
ctx.setLineWidth(px * 0.062)
// soluk tam halka (iz)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.10))
ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.strokePath()
// altın yay: tepeden başlayıp saat yönünde ~%72
ctx.setStrokeColor(CGColor(red: 1.0, green: 0.78, blue: 0.34, alpha: 1))
ctx.addArc(center: center, radius: radius, startAngle: .pi / 2,
           endAngle: .pi / 2 - .pi * 1.45, clockwise: true)
ctx.strokePath()

// 3) Ortada emoji
let font = CTFontCreateWithName("AppleColorEmoji" as CFString, px * 0.44, nil)
let line = CTLineCreateWithAttributedString(NSAttributedString(
    string: "💩", attributes: [kCTFontAttributeName as NSAttributedString.Key: font]))
let b = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
ctx.textPosition = CGPoint(x: (px - b.width) / 2 - b.origin.x, y: (px - b.height) / 2 - b.origin.y)
CTLineDraw(line, ctx)

guard let img = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL,
                                                 UTType.png.identifier as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("yazildi")
