import AppKit
import Foundation

guard CommandLine.arguments.count > 1 else { exit(1) }

let path = CommandLine.arguments[1]
guard let source = NSImage(contentsOfFile: path),
      let tiff = source.tiffRepresentation,
      let src = NSBitmapImageRep(data: tiff) else { exit(1) }

let w = src.pixelsWide
let h = src.pixelsHigh

guard let out = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { exit(1) }

guard let srcData = src.bitmapData, let outData = out.bitmapData else { exit(1) }
let srcBPR = src.bytesPerRow
let outBPR = out.bytesPerRow

for y in 0..<h {
    for x in 0..<w {
        let si = y * srcBPR + x * 4
        let oi = y * outBPR + x * 4
        let r = srcData[si]
        let g = srcData[si + 1]
        let b = srcData[si + 2]
        let a = srcData[si + 3]
        if r < 6 && g < 6 && b < 6 {
            outData[oi] = 0; outData[oi+1] = 0; outData[oi+2] = 0; outData[oi+3] = 0
        } else {
            outData[oi] = r; outData[oi+1] = g; outData[oi+2] = b; outData[oi+3] = a > 0 ? a : 255
        }
    }
}

guard let png = out.representation(using: .png, properties: [:]) else { exit(1) }
try? png.write(to: URL(fileURLWithPath: path))
