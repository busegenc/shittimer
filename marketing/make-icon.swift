import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Sit Happens uygulama ikonu — tamamen vektörel, hiçbir karikatür/emoji görsel içermez.
// Motif: uygulamanın sayaç ekranındaki altın ilerleme halkası + saat ibreleri.
let px = 1024.0
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: Int(px), height: Int(px), bitsPerComponent: 8,
                          bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { exit(1) }

// Zemin: koyu kahve degrade
let grad = CGGradient(colorsSpace: cs,
                      colors: [CGColor(red: 0.33, green: 0.20, blue: 0.11, alpha: 1),
                               CGColor(red: 0.10, green: 0.05, blue: 0.03, alpha: 1)] as CFArray,
                      locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: px), end: CGPoint(x: 0, y: 0), options: [])

let center = CGPoint(x: px / 2, y: px / 2)
let radius = px * 0.325
ctx.setLineCap(.round)

// Halka izi
ctx.setLineWidth(px * 0.070)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.10))
ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.strokePath()

// Altın ilerleme yayı: tepeden saat yönünde ~%72
ctx.setStrokeColor(CGColor(red: 1.0, green: 0.78, blue: 0.34, alpha: 1))
ctx.addArc(center: center, radius: radius, startAngle: .pi / 2,
           endAngle: .pi / 2 - .pi * 1.45, clockwise: true)
ctx.strokePath()

// Saat ibreleri (krem)
ctx.setStrokeColor(CGColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1))
ctx.setLineWidth(px * 0.048)
ctx.move(to: center)                                            // uzun ibre: yukarı
ctx.addLine(to: CGPoint(x: center.x, y: center.y + px * 0.175))
ctx.strokePath()
ctx.setLineWidth(px * 0.044)
ctx.move(to: center)                                            // kısa ibre: sağa
ctx.addLine(to: CGPoint(x: center.x + px * 0.120, y: center.y))
ctx.strokePath()

// Merkez nokta
ctx.setFillColor(CGColor(red: 1.0, green: 0.78, blue: 0.34, alpha: 1))
ctx.fillEllipse(in: CGRect(x: center.x - px * 0.030, y: center.y - px * 0.030,
                           width: px * 0.060, height: px * 0.060))

guard let img = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL,
                                                 UTType.png.identifier as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("ikon yazildi")
