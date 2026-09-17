import Cocoa
import QuartzCore
// Native adaptation of transitions.dev: short text swap, reversible page motion.
enum BrandMotion { static let textSwap = 0.15; static let page = 0.25 }

// MARK: - Apple Liquid Glass Design Tokens (macOS 27 HIG)
enum LiquidGlass {
    // Continuous super-ellipse corner radius (squircle)
    static let cornerRadius: CGFloat = 18
    static let pillCornerRadius: CGFloat = 14
    static let smallCornerRadius: CGFloat = 10

    // Specular rim gradient (top-lit glass refraction)
    static let specularTopAlpha: CGFloat = 0.18
    static let specularBottomAlpha: CGFloat = 0.04

    // Ambient shadow
    static let shadowRadius: CGFloat = 18
    static let shadowOffset = CGSize(width: 0, height: -4)
    static let shadowOpacity: Float = 0.12

    static func isDark(for view: NSView) -> Bool {
        // swiftlint:disable:next raw_appearance_check
        view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    // MARK: - Card Backgrounds
    static func cardBackground(isDark: Bool) -> NSColor {
        isDark
            ? NSColor(calibratedRed: 0.14, green: 0.17, blue: 0.23, alpha: 0.92)
            : NSColor(calibratedRed: 0.98, green: 0.98, blue: 1.0, alpha: 0.96)
    }

    static func elevatedCardBackground(isDark: Bool) -> NSColor {
        isDark
            ? NSColor(calibratedRed: 0.16, green: 0.19, blue: 0.26, alpha: 0.94)
            : NSColor(calibratedRed: 0.99, green: 0.99, blue: 1.0, alpha: 0.97)
    }

    // MARK: - Accent Colors
    static func accent(isDark: Bool) -> NSColor {
        isDark
            // swiftlint:disable:next hardcoded_accent_blue
            ? NSColor(calibratedRed: 0.38, green: 0.78, blue: 1.0, alpha: 1.0)
            : NSColor.systemBlue
    }

    static func researchAccent(isDark: Bool) -> NSColor {
        isDark
            // swiftlint:disable:next hardcoded_accent_orange
            ? NSColor(calibratedRed: 1.0, green: 0.65, blue: 0.2, alpha: 1.0)
            : NSColor.systemOrange
    }

    static func essayAccent(isDark: Bool) -> NSColor {
        isDark
            // swiftlint:disable:next hardcoded_accent_purple
            ? NSColor(calibratedRed: 0.75, green: 0.5, blue: 1.0, alpha: 1.0)
            : NSColor.systemPurple
    }

    // MARK: - Hover States
    static func hoverFill(isDark: Bool) -> NSColor {
        isDark
            ? NSColor.white.withAlphaComponent(0.10)
            : NSColor.black.withAlphaComponent(0.06)
    }

    static func pillActiveFill(isDark: Bool, accent: NSColor) -> NSColor {
        isDark ? accent.withAlphaComponent(0.26) : accent.withAlphaComponent(0.18)
    }

    static func pillInactiveFill(isDark: Bool) -> NSColor {
        isDark
            ? NSColor.white.withAlphaComponent(0.08)
            : NSColor.black.withAlphaComponent(0.05)
    }

    // MARK: - Drawing Helpers

    /// Configure a layer for Liquid Glass continuous corners + ambient shadow.
    static func configureLayer(_ layer: CALayer, radius: CGFloat = cornerRadius, shadow: Bool = true) {
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        if shadow {
            layer.shadowColor = NSColor.black.cgColor
            layer.shadowOpacity = shadowOpacity
            layer.shadowRadius = shadowRadius
            layer.shadowOffset = shadowOffset
            layer.masksToBounds = false
        }
    }

    /// Draw a Liquid Glass card fill + gradient specular rim.
    static func drawCard(in rect: NSRect, isDark: Bool, radius: CGFloat = cornerRadius, elevated: Bool = false) {
        let bg = elevated ? elevatedCardBackground(isDark: isDark) : cardBackground(isDark: isDark)
        bg.setFill()
        let insetRect = rect.insetBy(dx: 0.5, dy: 0.5)
        let path = NSBezierPath(roundedRect: insetRect, xRadius: radius, yRadius: radius)
        path.fill()

        // Gradient specular rim: brighter at top, fading toward bottom
        drawSpecularRim(in: insetRect, isDark: isDark, radius: radius)
    }

    /// Draw the signature Liquid Glass gradient specular border.
    static func drawSpecularRim(in rect: NSRect, isDark: Bool, radius: CGFloat = cornerRadius) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()

        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        ctx.addPath(path)
        ctx.replacePathWithStrokedPath()
        ctx.clip()

        let topColor: CGColor
        let bottomColor: CGColor
        if isDark {
            topColor = NSColor.white.withAlphaComponent(specularTopAlpha).cgColor
            bottomColor = NSColor.white.withAlphaComponent(specularBottomAlpha).cgColor
        } else {
            topColor = NSColor.black.withAlphaComponent(0.10).cgColor
            bottomColor = NSColor.black.withAlphaComponent(0.03).cgColor
        }

        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: [topColor, bottomColor] as CFArray,
                                        locations: [0.0, 1.0]) else { ctx.restoreGState(); return }
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: rect.midX, y: rect.minY),
                               end: CGPoint(x: rect.midX, y: rect.maxY),
                               options: [])
        ctx.restoreGState()
    }
}
final class PaperBackdrop:NSView {
 var receiveFiles:(([URL])->Void)?
 override init(frame:NSRect){super.init(frame:frame);registerForDraggedTypes([.fileURL])}
 required init?(coder:NSCoder){super.init(coder:coder);registerForDraggedTypes([.fileURL])}
 override func draggingEntered(_ sender:NSDraggingInfo)->NSDragOperation {.copy}
 override func performDragOperation(_ sender:NSDraggingInfo)->Bool {
  guard let urls = sender.draggingPasteboard.readObjects(forClasses:[NSURL.self],options:[.urlReadingFileURLsOnly:true]) as? [URL], !urls.isEmpty else{return false}
  receiveFiles?(urls);return true
 }
 var decorated = false {didSet{needsDisplay = true}}
 var backgroundImage: NSImage? {didSet{needsDisplay = true}}
 override func draw(_ dirtyRect:NSRect){
  let dark = LiquidGlass.isDark(for: self)
  let bg = dark ? NSColor(calibratedRed:0.11,green:0.12,blue:0.15,alpha:1) : NSColor(calibratedRed:0.96,green:0.96,blue:0.97,alpha:1)
  bg.setFill()
  dirtyRect.fill()
  super.draw(dirtyRect)
  if let img = backgroundImage {
   let imgSize = img.size
   if imgSize.width > 0 && imgSize.height > 0 {
    let scale = max(bounds.width / imgSize.width, bounds.height / imgSize.height)
    let w = imgSize.width * scale
    let h = imgSize.height * scale
    let drawRect = NSRect(x: (bounds.width - w) / 2, y: (bounds.height - h) / 2, width: w, height: h)
    let alpha: CGFloat = dark ? 0.18 : 0.14
    img.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: alpha, respectFlipped: true, hints: nil)
   }
  }
  guard decorated else{return}
  (dark ? NSColor.white : NSColor(calibratedRed:0.12,green:0.35,blue:0.33,alpha:1)).withAlphaComponent(0.045).setStroke()
  for index in 0..<6 {
   let rect = NSRect(x:bounds.maxX - 300 + CGFloat(index) * 28,y:bounds.midY - 170 + CGFloat(index) * 10,width:470,height:470)
   let path = NSBezierPath(roundedRect:rect,xRadius:150,yRadius:150);path.lineWidth = 1;path.stroke()
  }
 }
}
