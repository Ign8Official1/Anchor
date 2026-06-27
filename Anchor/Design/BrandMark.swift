import SwiftUI
import AppKit

enum BrandMark {
    static var image: NSImage? {
        guard let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        return image
    }
}

struct AnchorBrandIcon: View {
    var size: CGFloat = 32
    var cornerRadius: CGFloat? = nil

    private var radius: CGFloat { cornerRadius ?? size * 0.22 }

    var body: some View {
        if let image = BrandMark.image {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: size * 0.08, y: size * 0.04)
        } else {
            Image(systemName: "anchor")
                .font(.system(size: size * 0.55, weight: .light))
                .foregroundStyle(AnchorColor.surfaceLight)
        }
    }
}
