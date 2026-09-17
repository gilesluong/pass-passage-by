import Cocoa

func readingType(_ raw:String)->String {
    switch raw {
    case "task1": return "IELTS · Task 1"
    case "task2": return "IELTS · Task 2"
    case "research": return "Research"
    case "discursive": return "Essay"
    case "administrative": return "Văn bản hành chính"
    case "onboarding": return "SOP & Onboarding"
    case "speech": return "Diễn thuyết"
    default: return "Writing"
    }
}
import UniformTypeIdentifiers

func readingPreview(_ text:String)->String {
    text.components(separatedBy:"\n").filter{!$0.trimmingCharacters(in:.whitespaces).hasPrefix("#")}.joined(separator:" ")
}
func featuredTitle(_ doc:Breakdown)->String {
    switch doc.document.id {
    case "ppb-open-workplace": return "Enhancing workplace digital learning"
    case "ppb-open-sleep": return "Sleep and eyewitness memory"
    default:return doc.document.title
    }
}

final class SidebarItemButton: NSButton {
    override var isFlipped: Bool { true }
    private var trackingArea: NSTrackingArea?
    private var isHovered = false { didSet { needsDisplay = true } }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea { removeTrackingArea(area) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isHovered = false
    }

    override func draw(_ dirtyRect: NSRect) {
        if wantsLayer, let l = layer { l.cornerCurve = .continuous }
        if isHovered {
            LiquidGlass.hoverFill(isDark: LiquidGlass.isDark(for: self)).setFill()
            let path = NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8)
            path.fill()
        }
        super.draw(dirtyRect)
    }
}

final class GlassPillButton: NSButton {
    override var isFlipped: Bool { true }
    var isActive: Bool = false { didSet { needsDisplay = true } }
    override func draw(_ dirtyRect: NSRect) {
        let isDark = LiquidGlass.isDark(for: self)
        let accent = LiquidGlass.accent(isDark: isDark)
        let bg = isActive
            ? LiquidGlass.pillActiveFill(isDark: isDark, accent: accent)
            : LiquidGlass.pillInactiveFill(isDark: isDark)
        bg.setFill()
        let radius = bounds.height / 2
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius)
        path.fill()
        // Specular rim
        LiquidGlass.drawSpecularRim(in: bounds.insetBy(dx: 0.5, dy: 0.5), isDark: isDark, radius: radius)
        super.draw(dirtyRect)
    }
}

final class CardActionPill: NSButton {
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        let isDark = LiquidGlass.isDark(for: self)
        let accent = LiquidGlass.accent(isDark: isDark)
        let bg = isDark ? accent.withAlphaComponent(0.18) : accent.withAlphaComponent(0.10)
        bg.setFill()
        let radius = bounds.height / 2
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius)
        path.fill()
        LiquidGlass.drawSpecularRim(in: bounds.insetBy(dx: 0.5, dy: 0.5), isDark: isDark, radius: radius)
        super.draw(dirtyRect)
    }
}

final class AppleTVSidebarItem: NSButton {
    override var isFlipped: Bool { true }
    private var trackingArea: NSTrackingArea?
    private var isHovered = false { didSet { needsDisplay = true } }
    var isSelected: Bool = false { didSet { updateItemStyle() } }
    var itemTitle: String = "" { didSet { updateItemStyle() } }
    var sfSymbol: String = "" { didSet { updateItemStyle() } }
    var isSearch: Bool = false { didSet { updateItemStyle() } }

    private let iconImageView = NSImageView()
    private let titleLabelView = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        bezelStyle = .regularSquare
        isBordered = false
        title = ""
        attributedTitle = NSAttributedString(string: "")
        image = nil

        iconImageView.imageScaling = .scaleProportionallyDown
        titleLabelView.isEditable = false
        titleLabelView.isSelectable = false
        titleLabelView.drawsBackground = false
        titleLabelView.isBordered = false
        titleLabelView.lineBreakMode = .byTruncatingTail

        addSubview(iconImageView)
        addSubview(titleLabelView)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("This view is created programmatically") }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea { removeTrackingArea(area) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isHovered = false
    }

    func updateItemStyle() {
        let fgColor: NSColor = isSearch ? .secondaryLabelColor : .labelColor
        setAccessibilityLabel(itemTitle)
        titleLabelView.stringValue = itemTitle
        titleLabelView.font = .systemFont(ofSize: 13, weight: isSelected ? .semibold : .medium)
        titleLabelView.textColor = fgColor

        if let img = NSImage(systemSymbolName: sfSymbol, accessibilityDescription: itemTitle) {
            let conf = NSImage.SymbolConfiguration(pointSize: 13, weight: isSelected ? .semibold : .medium)
            iconImageView.image = img.withSymbolConfiguration(conf)
            iconImageView.contentTintColor = isSelected ? .controlAccentColor : fgColor
        }
        needsDisplay = true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if bounds.contains(point) { return self }
        return super.hitTest(point)
    }

    override func layout() {
        super.layout()
        let iconSize: CGFloat = 16
        iconImageView.frame = NSRect(x: 14, y: (bounds.height - iconSize) / 2, width: iconSize, height: iconSize)
        titleLabelView.frame = NSRect(x: 38, y: (bounds.height - 18) / 2, width: max(40, bounds.width - 46), height: 18)
    }

    override func draw(_ dirtyRect: NSRect) {
        let radius: CGFloat = 7
        let pillBounds = bounds.insetBy(dx: 4, dy: 1)
        let path = NSBezierPath(roundedRect: pillBounds, xRadius: radius, yRadius: radius)
        if isSelected {
            // Apple TV Active Blue Pill
            NSColor.labelColor.withAlphaComponent(0.13).setFill()
            path.fill()
        } else if isHovered {
            LiquidGlass.hoverFill(isDark: LiquidGlass.isDark(for: self)).setFill()
            path.fill()
        }
    }
}

final class AppleTVProfileView: NSView {
    override var isFlipped: Bool { true }

    private let avatarCircle = NSView()
    private let initialsLabel = NSTextField(labelWithString: "CR")
    private let nameLabel = NSTextField(labelWithString: "Casper Ryou")
    private let roleLabel = NSTextField(labelWithString: "Writing Studio")
    let settingsButton = NSButton()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true

        avatarCircle.wantsLayer = true
        if let layer = avatarCircle.layer { LiquidGlass.configureLayer(layer, radius: 14, shadow: false) }
        avatarCircle.layer?.masksToBounds = true
        avatarCircle.layer?.backgroundColor = NSColor(red: 0.16, green: 0.20, blue: 0.28, alpha: 1.0).cgColor

        initialsLabel.font = .systemFont(ofSize: 11, weight: .bold)
        initialsLabel.textColor = .white
        initialsLabel.alignment = .center
        avatarCircle.addSubview(initialsLabel)

        nameLabel.font = .systemFont(ofSize: 12.5, weight: .semibold)
        nameLabel.textColor = .labelColor

        roleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        roleLabel.textColor = .secondaryLabelColor

        settingsButton.bezelStyle = .regularSquare
        settingsButton.isBordered = false
        if let img = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings") {
            let conf = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            settingsButton.image = img.withSymbolConfiguration(conf)
        }
        settingsButton.contentTintColor = .secondaryLabelColor
        settingsButton.target = self
        settingsButton.action = #selector(openDirectSettings(_:))

        addSubview(avatarCircle)
        addSubview(nameLabel)
        addSubview(roleLabel)
        addSubview(settingsButton)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("This view is created programmatically") }

    @objc func openDirectSettings(_ sender: NSButton) {
        (NSApp.delegate as? Passage)?.showSettings(sender)
    }

    @objc func showProfileMenu(_ sender: NSButton) {
        let app = NSApp.delegate as? Passage
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(Passage.showSettings), keyEquivalent: ",")
        settingsItem.target = app
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(title: "About Pass Passage By!…", action: #selector(Passage.showAbout), keyEquivalent: "")
        aboutItem.target = app
        menu.addItem(aboutItem)

        let setupItem = NSMenuItem(title: "Quick Setup Guide…", action: #selector(Passage.showOnboarding), keyEquivalent: "")
        setupItem.target = app
        menu.addItem(setupItem)

        menu.addItem(NSMenuItem.separator())

        let privItem = NSMenuItem(title: "Privacy Policy…", action: #selector(Passage.showPrivacy), keyEquivalent: "")
        privItem.target = app
        menu.addItem(privItem)

        let termsItem = NSMenuItem(title: "Terms of Service…", action: #selector(Passage.showTerms), keyEquivalent: "")
        termsItem.target = app
        menu.addItem(termsItem)

        let point = NSPoint(x: sender.bounds.minX, y: sender.bounds.maxY + 4)
        menu.popUp(positioning: nil, at: point, in: sender)
    }

    override func layout() {
        super.layout()
        avatarCircle.frame = NSRect(x: 6, y: (bounds.height - 28) / 2, width: 28, height: 28)
        initialsLabel.frame = NSRect(x: 0, y: 6, width: 28, height: 16)

        let textX: CGFloat = 42
        let textW: CGFloat = max(40, bounds.width - textX - 32)
        nameLabel.frame = NSRect(x: textX, y: 3, width: textW, height: 16)
        roleLabel.frame = NSRect(x: textX, y: 19, width: textW, height: 14)

        settingsButton.frame = NSRect(x: bounds.width - 28, y: (bounds.height - 22) / 2, width: 22, height: 22)
    }
}

final class AppleTVPrimaryCTA: NSButton {
    override var isFlipped: Bool { true }
    private var trackingArea: NSTrackingArea?
    private var isHovered = false { didSet { needsDisplay = true } }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea { removeTrackingArea(area) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isHovered = false
    }

    override func draw(_ dirtyRect: NSRect) {
        let radius = bounds.height / 2
        let path = NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius)
        let bg = isHovered ? NSColor(white: 0.92, alpha: 1.0) : NSColor.white
        bg.setFill()
        path.fill()

        LiquidGlass.drawSpecularRim(in: bounds, isDark: LiquidGlass.isDark(for: self), radius: radius)

        super.draw(dirtyRect)
    }
}

final class AppleTVCircleButton: NSButton {
    override var isFlipped: Bool { true }
    private var trackingArea: NSTrackingArea?
    private var isHovered = false { didSet { needsDisplay = true } }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea { removeTrackingArea(area) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isHovered = false
    }

    override func draw(_ dirtyRect: NSRect) {
        let radius = bounds.height / 2
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius)
        let alpha: CGFloat = isHovered ? 0.35 : 0.20
        NSColor(white: 1.0, alpha: alpha).setFill()
        path.fill()

        LiquidGlass.drawSpecularRim(in: bounds, isDark: LiquidGlass.isDark(for: self), radius: radius)

        super.draw(dirtyRect)
    }
}

struct PartnerSlide {
    let partnerName: String
    let educator: String
    let badgeText: String
    let title: String
    let excerpt: String
    let pedagogyHighlight: String
    let tags: [String]
    let path: String
    let isResearch: Bool
    let accentColor: NSColor
}

enum HomeScrollAxis { case undecided, horizontal, vertical }

struct HomeSwipeGesture {
    var axis: HomeScrollAxis = .undecided
    var horizontal: Bool { axis == .horizontal }
    var advanced = false
    var distance: CGFloat = 0
    var lastTime: TimeInterval = 0
    mutating func consume(x:CGFloat,y:CGFloat,time:TimeInterval,began:Bool,unphased:Bool,momentum:Bool) -> Int {
        if began || (unphased && !momentum && time - lastTime > 0.3) {axis = .undecided;advanced = false;distance = 0}
        lastTime = time
        if axis == .undecided && max(abs(x),abs(y)) > 0 {axis = abs(x) > abs(y) ? .horizontal : .vertical}
        guard horizontal == true, !momentum, !advanced else{return 0}
        distance += x
        guard abs(distance) > 20 else{return 0}
        advanced = true
        return distance < 0 ? 1 : -1
    }
}

final class PartnerShowcaseCarousel: NSView {
    override var isFlipped: Bool { true }

    var coverImage: NSImage?
    var slides: [PartnerSlide] = []
    var currentIndex: Int = 0 { didSet { updateContent() } }

    weak var openTarget: AnyObject?
    var openAction: Selector?

    private let partnerBadge = NSTextField(wrappingLabelWithString: "")
    private let titleLabel = NSTextField(wrappingLabelWithString: "")
    private let appleMetaLabel = NSTextField(wrappingLabelWithString: "")
    private let excerptLabel = NSTextField(wrappingLabelWithString: "")
    private let pedagogyLabel = NSTextField(wrappingLabelWithString: "")
    private let tagsStack = NSStackView()
    private let actionButton = AppleTVPrimaryCTA(title: "", target: nil, action: nil)
    private let bookmarkButton = AppleTVCircleButton(title: "+", target: nil, action: nil)
    private let ctaSubtitle = NSTextField(wrappingLabelWithString: "")
    private let laurelLabel = NSTextField(wrappingLabelWithString: "")

    private let prevButton = GlassPillButton(title: "‹", target: nil, action: nil)
    private let nextButton = GlassPillButton(title: "›", target: nil, action: nil)
    private var dotButtons: [NSButton] = []
    private let dotsContainer = NSStackView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        if let l = layer { LiquidGlass.configureLayer(l) }

        partnerBadge.font = .systemFont(ofSize: 11, weight: .bold)

        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white

        appleMetaLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        appleMetaLabel.textColor = NSColor(white: 0.90, alpha: 0.90)

        excerptLabel.font = NSFont(name: "Georgia", size: 13.5) ?? .systemFont(ofSize: 13.5)
        excerptLabel.textColor = NSColor(white: 0.95, alpha: 0.95)

        pedagogyLabel.font = .systemFont(ofSize: 12, weight: .medium)
        pedagogyLabel.textColor = NSColor(white: 0.85, alpha: 0.85)

        laurelLabel.font = .systemFont(ofSize: 10.5, weight: .bold)
        laurelLabel.textColor = NSColor(white: 0.82, alpha: 0.70)
        laurelLabel.alignment = .right

        ctaSubtitle.font = .systemFont(ofSize: 11, weight: .regular)
        ctaSubtitle.textColor = NSColor(white: 0.75, alpha: 0.65)

        actionButton.target = self
        actionButton.action = #selector(actionClicked)

        bookmarkButton.target = self
        bookmarkButton.action = #selector(bookmarkClicked)
        bookmarkButton.toolTip = "Save to My writing"
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        bookmarkButton.attributedTitle = NSAttributedString(
            string: "+",
            attributes: [
                .foregroundColor: NSColor.white,
                .font: NSFont.systemFont(ofSize: 16, weight: .bold),
                .paragraphStyle: pStyle
            ]
        )

        prevButton.target = self
        prevButton.action = #selector(prevClicked)
        nextButton.target = self
        nextButton.action = #selector(nextClicked)

        dotsContainer.orientation = .horizontal
        dotsContainer.spacing = 6
        dotsContainer.alignment = .centerY

        tagsStack.orientation = .horizontal
        tagsStack.spacing = 8
        tagsStack.alignment = .centerY

        for v in [partnerBadge, titleLabel, appleMetaLabel, excerptLabel, pedagogyLabel, tagsStack, actionButton, bookmarkButton, ctaSubtitle, laurelLabel, prevButton, nextButton, dotsContainer] {
            addSubview(v)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("This view is created programmatically") }

    func setupSlides(_ list: [PartnerSlide]) {
        slides = list
        setupDots()
        currentIndex = 0
        updateContent()
    }

    private func setupDots() {
        for b in dotButtons { b.removeFromSuperview() }
        dotButtons.removeAll()
        for i in 0..<slides.count {
            let b = NSButton(title: "●", target: self, action: #selector(dotClicked(_:)))
            b.isBordered = false
            b.tag = i
            b.font = .systemFont(ofSize: 11)
            dotsContainer.addArrangedSubview(b)
            dotButtons.append(b)
        }
    }

    @objc private func dotClicked(_ sender: NSButton) {
        guard sender.tag >= 0 && sender.tag < slides.count else { return }
        currentIndex = sender.tag
    }

    @objc private func prevClicked() {
        guard !slides.isEmpty else { return }
        currentIndex = (currentIndex - 1 + slides.count) % slides.count
    }

    @objc private func nextClicked() {
        guard !slides.isEmpty else { return }
        currentIndex = (currentIndex + 1) % slides.count
    }

    private var swipe = HomeSwipeGesture()
    override var acceptsFirstResponder: Bool { true }
    override func scrollWheel(with event:NSEvent) {
        let step = swipe.consume(x:event.scrollingDeltaX,y:event.scrollingDeltaY,time:event.timestamp,began:event.phase == .began,unphased:event.phase.isEmpty,momentum:!event.momentumPhase.isEmpty)
        if swipe.horizontal != true {super.scrollWheel(with:event);return}
        if step > 0 {nextClicked()} else if step < 0 {prevClicked()}
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 123 {
            prevClicked()
        } else if event.keyCode == 124 {
            nextClicked()
        } else {
            super.keyDown(with: event)
        }
    }

    @objc private func actionClicked() {
        guard currentIndex >= 0 && currentIndex < slides.count else { return }
        let slide = slides[currentIndex]
        actionButton.identifier = .init(slide.path)
        if let target = openTarget, let action = openAction {
            _ = target.perform(action, with: actionButton)
        }
    }

    @objc private func bookmarkClicked() {
        guard currentIndex >= 0 && currentIndex < slides.count else { return }
        let slide = slides[currentIndex]
        do {
            let bytes = try Data(contentsOf:URL(fileURLWithPath:slide.path))
            let doc = try JSONDecoder().decode(Breakdown.self,from:bytes)
            if let passage = openTarget as? Passage {
                try LibraryStore.save(doc,to:passage.saveURL.deletingLastPathComponent().appendingPathComponent("Library"))
                bookmarkButton.toolTip = "Saved to My writing";bookmarkButton.title = "✓"
            }
        } catch {(openTarget as? Passage)?.showAlert(error.localizedDescription)}
    }

    func updateContent() {
        guard currentIndex >= 0 && currentIndex < slides.count else { return }
        let slide = slides[currentIndex]

        partnerBadge.stringValue = slide.badgeText
        partnerBadge.textColor = slide.accentColor

        titleLabel.stringValue = slide.title
        appleMetaLabel.stringValue = slide.tags.prefix(3).joined(separator:"  ·  ")
        excerptLabel.stringValue = "“" + slide.excerpt + "”"
        pedagogyLabel.stringValue = slide.pedagogyHighlight
        laurelLabel.stringValue = ""
        ctaSubtitle.stringValue = "Read, annotate, and make it your own."

        for v in tagsStack.arrangedSubviews { tagsStack.removeArrangedSubview(v); v.removeFromSuperview() }
        for t in slide.tags {
            let pill = NSTextField(labelWithString: t)
            pill.font = .systemFont(ofSize: 11, weight: .medium)
            pill.textColor = NSColor(white: 0.85, alpha: 0.8)
            tagsStack.addArrangedSubview(pill)
        }

        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        let btnTitle = "Read annotated writing"
        actionButton.attributedTitle = NSAttributedString(
            string: btnTitle,
            attributes: [
                .foregroundColor: NSColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0),
                .font: NSFont.systemFont(ofSize: 13, weight: .bold),
                .paragraphStyle: pStyle
            ]
        )

        for (i, b) in dotButtons.enumerated() {
            b.contentTintColor = (i == currentIndex) ? NSColor.white : NSColor(white: 1.0, alpha: 0.3)
        }

        needsLayout = true
        needsDisplay = true
    }

    override func layout() {
        super.layout()
        let pad:CGFloat = 42,w = max(230,bounds.width - pad * 2),textWidth = min(470,w)
        let bottom = bounds.height - 62
        partnerBadge.frame = NSRect(x:pad,y:bottom - 224,width:textWidth,height:20)
        titleLabel.font = NSFont(name:"Georgia-Bold",size:bounds.width < 600 ? 25 : 32)
        titleLabel.maximumNumberOfLines = 3;titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.frame = NSRect(x:pad,y:bottom - 196,width:textWidth,height:88)
        appleMetaLabel.frame = NSRect(x:pad,y:bottom - 104,width:textWidth,height:20)
        excerptLabel.frame = NSRect(x:pad,y:bottom - 78,width:textWidth,height:44)
        pedagogyLabel.isHidden = true;laurelLabel.isHidden = true;tagsStack.isHidden = true;ctaSubtitle.isHidden = true
        actionButton.frame = NSRect(x:pad,y:bottom - 16,width:214,height:38)
        bookmarkButton.frame = NSRect(x:pad + 226,y:bottom - 16,width:38,height:38)
        let dotW = CGFloat(dotButtons.count) * 16
        dotsContainer.frame = NSRect(x:(bounds.width - dotW) / 2,y:bounds.height - 25,width:dotW,height:16)
        prevButton.frame = NSRect(x:7,y:bounds.height / 2 - 14,width:28,height:28)
        nextButton.frame = NSRect(x:bounds.width - 35,y:bounds.height / 2 - 14,width:28,height:28)
    }

    override func draw(_ dirtyRect: NSRect) {
        let isDark = LiquidGlass.isDark(for: self)
        let radius: CGFloat = 16
        let path = NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius)
        path.addClip()

        let grad = NSGradient(colors: [
            NSColor(red: 0.08, green: 0.11, blue: 0.18, alpha: 1.0),
            NSColor(red: 0.04, green: 0.06, blue: 0.10, alpha: 1.0)
        ])
        grad?.draw(in: bounds, angle: -45)

        if let image = coverImage {
            let scale = max(bounds.width / image.size.width,bounds.height / image.size.height)
            let dest = NSRect(x:(bounds.width - image.size.width * scale) / 2,y:(bounds.height - image.size.height * scale) / 2,width:image.size.width * scale,height:image.size.height * scale)
            image.draw(in:dest,from:.zero,operation:.sourceOver,fraction:1,respectFlipped:true,hints:nil)
            NSColor.black.withAlphaComponent(0.30).setFill();bounds.fill()
        }
        LiquidGlass.drawSpecularRim(in: bounds.insetBy(dx: 0.5, dy: 0.5), isDark: isDark, radius: radius)
    }
}

final class WritingCategoryBar: NSView {
    override var isFlipped: Bool { true }

    var onSelectCategory: ((Int) -> Void)?
    var selectedIndex: Int = 0 { didSet { updatePills() } }

    private let titleLabel = NSTextField(labelWithString: "CATEGORIES")
    private var pillButtons: [GlassPillButton] = []
    private let categories = [
        "All Writing",
        "IELTS Writing",
        "Research & Academic",
        "Essays & Composition"
    ]

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        titleLabel.font = .systemFont(ofSize: 11, weight: .bold)
        titleLabel.textColor = .secondaryLabelColor
        addSubview(titleLabel)

        for (i, cat) in categories.enumerated() {
            let btn = GlassPillButton(title: cat, target: self, action: #selector(categoryClicked(_:)))
            btn.tag = i
            btn.font = .systemFont(ofSize: 12, weight: .medium)
            addSubview(btn)
            pillButtons.append(btn)
        }
        updatePills()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("This view is created programmatically") }

    private func updatePills() {
        for (i, btn) in pillButtons.enumerated() {
            btn.isActive = (i == selectedIndex)
            btn.attributedTitle = NSAttributedString(
                string: categories[i],
                attributes: [
                    .foregroundColor: (i == selectedIndex) ? NSColor.labelColor : NSColor.secondaryLabelColor,
                    .font: NSFont.systemFont(ofSize: 12, weight: (i == selectedIndex) ? .semibold : .medium)
                ]
            )
        }
    }

    @objc private func categoryClicked(_ sender: NSButton) {
        selectedIndex = sender.tag
        onSelectCategory?(selectedIndex)
    }

    override func layout() {
        super.layout()
        titleLabel.isHidden = bounds.width < 700
        titleLabel.frame = NSRect(x:4,y:8,width:85,height:20)
        var curX:CGFloat = titleLabel.isHidden ? 0 : 95
        var y:CGFloat = 4
        for btn in pillButtons {
            let btnW = min(bounds.width,(btn.title as NSString).size(withAttributes:[.font:btn.font ?? NSFont.systemFont(ofSize:12)]).width + 24)
            if curX + btnW > bounds.width {curX = 0;y += 34}
            btn.frame = NSRect(x:curX,y:y,width:btnW,height:28);curX += btnW + 8
        }
    }
}

struct ReadingCardCredit: Decodable {
    let title: String
    let authors: String
    let tags: [String]?
}

final class HomeCard: NSView {
    let categoryBadge = NSTextField(wrappingLabelWithString: "")
    let heading = NSTextField(wrappingLabelWithString: "")
    let detail = NSTextField(wrappingLabelWithString: "")
    let badge = NSTextField(wrappingLabelWithString: "")
    let note = NSTextField(wrappingLabelWithString: "")
    let open = CardActionPill(title: "", target: nil, action: nil)
    var doiButton: GlassPillButton?
    var searchableText = ""
    var categoryType: String = "ielts"
    var rankNumber: Int? {
        didSet {
            if let r = rankNumber {
                rankLabel.stringValue = "\(r)"
                rankLabel.isHidden = false
            } else {
                rankLabel.isHidden = true
            }
        }
    }
    private let rankLabel = NSTextField(labelWithString: "")
    private var trackingArea: NSTrackingArea?
    private var isHovered = false { didSet { needsDisplay = true } }

    override var isFlipped: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea { removeTrackingArea(area) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isHovered = false
    }

    init(title: String, excerpt: String, annotation: String, categoryTag: String = "PRACTICE ESSAY", categoryType: String = "ielts", target: AnyObject, action: Selector, path: String) {
        super.init(frame: .zero)
        self.categoryType = categoryType
        searchableText = title + " " + excerpt + " " + annotation + " " + categoryTag
        wantsLayer = true
        if let l = layer { LiquidGlass.configureLayer(l) }

        let parts = annotation.split(separator: "\n", maxSplits: 1).map(String.init)
        let bText = parts.first ?? "Margin notes · PPB! practice"
        let nText = parts.count > 1 ? parts[1] : ""

        categoryBadge.stringValue = categoryTag.uppercased()
        categoryBadge.font = .systemFont(ofSize: 10, weight: .bold)

        heading.stringValue = title
        heading.font = .systemFont(ofSize: 16, weight: .semibold)
        heading.textColor = .labelColor
        heading.maximumNumberOfLines = 0
        heading.lineBreakMode = .byWordWrapping

        detail.stringValue = excerpt
        detail.font = NSFont(name: "Georgia", size: 13) ?? .systemFont(ofSize: 13)
        detail.textColor = .secondaryLabelColor
        detail.maximumNumberOfLines = 3
        detail.lineBreakMode = .byWordWrapping

        badge.stringValue = bText
        badge.font = .systemFont(ofSize: 12, weight: .regular)

        note.stringValue = nText
        note.font = .systemFont(ofSize: 11.5, weight: .medium)
        note.textColor = .secondaryLabelColor
        note.lineBreakMode = .byWordWrapping

        open.target = target
        open.action = action
        open.identifier = .init(path)
        open.bezelStyle = .regularSquare
        open.isBordered = false

        rankLabel.font = .systemFont(ofSize: 42, weight: .black)
        rankLabel.textColor = NSColor.labelColor.withAlphaComponent(0.12)
        rankLabel.alignment = .right
        rankLabel.isHidden = true

        var cardViews: [NSView] = [categoryBadge, heading, detail, badge, note, open, rankLabel]

        // Parse DOI for research cards if present
        let doiRegex = try? NSRegularExpression(pattern: #"(?:doi(?::|\.org\/)|\b)(10\.\d{4,9}/[-._;()/:A-Za-z0-9]+)"#, options: .caseInsensitive)
        if let match = doiRegex?.firstMatch(in: annotation, range: NSRange(location: 0, length: (annotation as NSString).length)), match.numberOfRanges > 1 {
            let doi = (annotation as NSString).substring(with: match.range(at: 1))
            let doiBtn = GlassPillButton(title: "DOI ↗", target: self, action: #selector(handleDOIClick))
            doiBtn.identifier = NSUserInterfaceItemIdentifier(doi)
            doiBtn.font = .systemFont(ofSize: 11, weight: .semibold)
            doiBtn.toolTip = "Open https://doi.org/\(doi) in browser"
            doiButton = doiBtn
            cardViews.append(doiBtn)
        }

        for view in cardViews { addSubview(view) }
        setAccessibilityElement(true);setAccessibilityRole(.button)
        setAccessibilityLabel(title);setAccessibilityHelp("Open document")
        heading.isSelectable = false;detail.isSelectable = false;badge.isSelectable = false;note.isSelectable = false
    }

    @objc private func handleDOIClick() {
        guard let doi = doiButton?.identifier?.rawValue, !doi.isEmpty else { return }
        let urlStr = doi.hasPrefix("http") ? doi : "https://doi.org/" + doi
        if let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }

    convenience init(title: String, excerpt: String, annotation: String, target: AnyObject, action: Selector, path: String) {
        self.init(title: title, excerpt: excerpt, annotation: annotation, categoryTag: "PRACTICE ESSAY", categoryType: "ielts", target: target, action: action, path: path)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("This view is created programmatically") }

    private func textHeight(_ field:NSTextField,width:CGFloat) -> CGFloat {
        ceil((field.stringValue as NSString).boundingRect(with:NSSize(width:width,height:10000),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:[.font:field.font ?? NSFont.systemFont(ofSize:13)]).height) + 8
    }
    func preferredHeight(width:CGFloat) -> CGFloat {
        let w = max(80,width - 40)
        return 80 + textHeight(heading,width:w) + textHeight(badge,width:w) + textHeight(note,width:w) + 48
    }
    override var acceptsFirstResponder: Bool {true}
    override func hitTest(_ point:NSPoint) -> NSView? {super.hitTest(point) == nil ? nil : self}
    override func mouseUp(with event:NSEvent) {
        if bounds.contains(convert(event.locationInWindow,from:nil)) {activateCard()}
    }
    override func keyDown(with event:NSEvent) {
        if event.keyCode == 36 || event.keyCode == 49 {activateCard()} else {super.keyDown(with:event)}
    }
    override func accessibilityPerformPress() -> Bool {activateCard();return true}
    private func activateCard() {
        guard let action = open.action else{return}
        NSApp.sendAction(action,to:open.target,from:open)
    }
    override func layout() {
        super.layout()
        let w = max(80,bounds.width - 40)
        categoryBadge.frame = NSRect(x:20,y:18,width:w,height:16)
        let titleH = textHeight(heading,width:w)
        heading.frame = NSRect(x:20,y:44,width:w,height:titleH)
        let authorH = textHeight(badge,width:w)
        badge.frame = NSRect(x:20,y:heading.frame.maxY + 8,width:w,height:authorH)
        detail.frame = NSRect(x:20,y:badge.frame.maxY + 12,width:w,height:42)
        note.isHidden = false
        note.frame = NSRect(x:20,y:detail.frame.maxY + 12,width:w,height:textHeight(note,width:w))
        open.isHidden = true;doiButton?.isHidden = true;rankLabel.isHidden = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let isDark = LiquidGlass.isDark(for: self)

        // Liquid Glass card fill + gradient specular rim with hover elevation
        (isDark ? NSColor(white:isHovered ? 0.22 : 0.17,alpha:1) : NSColor(white:isHovered ? 0.96 : 1,alpha:1)).setFill()
        NSBezierPath(roundedRect:bounds.insetBy(dx:0.5,dy:0.5),xRadius:LiquidGlass.smallCornerRadius,yRadius:LiquidGlass.smallCornerRadius).fill()
        LiquidGlass.drawSpecularRim(in: bounds.insetBy(dx: 0.5, dy: 0.5), isDark: isDark, radius: LiquidGlass.smallCornerRadius)

        rankLabel.textColor = isDark ? NSColor(white: 1.0, alpha: 0.16) : NSColor(white: 0.0, alpha: 0.12)
        heading.textColor = .labelColor
        detail.textColor = .secondaryLabelColor

        let accent: NSColor = {
            if categoryType == "research" {
                return LiquidGlass.researchAccent(isDark: isDark)
            } else if categoryType == "essays" {
                return LiquidGlass.essayAccent(isDark: isDark)
            } else {
                return LiquidGlass.accent(isDark: isDark)
            }
        }()

        categoryBadge.textColor = accent
        badge.textColor = .secondaryLabelColor
        note.textColor = accent



    }
}

final class HomeSectionHeader: NSView {
    override var isFlipped: Bool { true }
    let tagBadge = NSTextField(wrappingLabelWithString: "")
    let titleLabel = NSTextField(wrappingLabelWithString: "")
    let subtitleLabel = NSTextField(wrappingLabelWithString: "")
    var accentColor: NSColor = .systemBlue

    init(badge: String, title: String, subtitle: String, accentColor: NSColor) {
        super.init(frame: .zero)
        self.accentColor = accentColor

        tagBadge.stringValue = badge.uppercased()
        tagBadge.font = .systemFont(ofSize: 11, weight: .bold)
        tagBadge.textColor = accentColor

        let chevronTitle = title
        titleLabel.stringValue = chevronTitle
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .labelColor

        subtitleLabel.stringValue = subtitle
        subtitleLabel.font = .systemFont(ofSize: 12.5, weight: .regular)
        subtitleLabel.textColor = .secondaryLabelColor

        for v in [tagBadge, titleLabel, subtitleLabel] { addSubview(v) }
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("This view is created programmatically") }

    override func layout() {
        super.layout()
        tagBadge.frame = NSRect(x: 0, y: 0, width: bounds.width, height: 16)
        titleLabel.frame = NSRect(x: 0, y: 18, width: bounds.width, height: 24)
        subtitleLabel.frame = NSRect(x: 0, y: 44, width: bounds.width, height: 18)
    }
}

final class HomeDashboardSection {
    let key: String
    let header: HomeSectionHeader
    var cards: [HomeCard]
    let shelf = HomeShelfScrollView()
    let strip = MarginCanvas()
    var isHidden: Bool = false {
        didSet {
            header.isHidden = isHidden
            shelf.isHidden = isHidden
            for c in cards { c.isHidden = isHidden }
        }
    }

    init(key: String, header: HomeSectionHeader, cards: [HomeCard]) {
        self.key = key
        self.header = header
        self.cards = cards
        shelf.drawsBackground = false;shelf.hasHorizontalScroller = true;shelf.autohidesScrollers = true;shelf.documentView = strip
        for card in cards {strip.addSubview(card)}
    }
}

// The page never scrolls horizontally. Shelves have independent clip views.
final class HomePageClipView: NSClipView {
    override func scroll(to point:NSPoint) {super.scroll(to:NSPoint(x:0,y:point.y))}
    override func setBoundsOrigin(_ point:NSPoint) {super.setBoundsOrigin(NSPoint(x:0,y:point.y))}
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds);rect.origin.x = 0;return rect
    }
}
// Vertical gestures over a shelf go straight to the page, not its inner clip.
final class HomeShelfScrollView: NSScrollView {
    private var axis: HomeScrollAxis = .undecided
    var horizontal: Bool { axis == .horizontal }
    private var lastEventTime: TimeInterval = 0
    override func scrollWheel(with event:NSEvent) {
        if event.phase == .began || (event.phase.isEmpty && event.momentumPhase.isEmpty && event.timestamp - lastEventTime > 0.3) {axis = .undecided}
        lastEventTime = event.timestamp
        if axis == .undecided && max(abs(event.scrollingDeltaX),abs(event.scrollingDeltaY)) > 0 {
            axis = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) ? .horizontal : .vertical
        }
        if horizontal == true {super.scrollWheel(with:event)}
        else {
            var ancestor = superview
            while let view = ancestor {
                if let page = view as? HomePageScrollView {page.scrollWheel(with:event);return}
                ancestor = view.superview
            }
        }
    }
}
final class HomePageScrollView: NSScrollView {
    override func scrollWheel(with event:NSEvent) {
        guard abs(event.scrollingDeltaY) >= abs(event.scrollingDeltaX) else{return}
        super.scrollWheel(with:event)
    }
}
final class HomeDashboard: NSView, NSSearchFieldDelegate {
    override var isFlipped: Bool { true }
    var sidebar = MarginCanvas(), main = MarginCanvas()
    var header: [NSView] = [], cards: [HomeCard] = [], footer: [NSView] = []
    var carousel: PartnerShowcaseCarousel?
    var categoryBar: WritingCategoryBar?
    let searchField = NSSearchField()
    let emptyResults = NSTextField(wrappingLabelWithString:"No matching writing. Import a document or send one from your agent to start a collection.")
    var allCards: [(card: HomeCard, category: String)] = []
    var sections: [HomeDashboardSection] = []
    var selectedCategoryIndex: Int = 0

    // Apple TV Sidebar elements
    var sidebarSearch: AppleTVSidebarItem?
    var sidebarNavItems: [AppleTVSidebarItem] = []
    var sidebarLibraryHeader: NSView?
    var sidebarLibraryItems: [AppleTVSidebarItem] = []
    var sidebarProfile: AppleTVProfileView?

    // Sidebar elements for responsive layout & backwards compatibility
    var sidebarIcon: NSView?
    var sidebarBrand: NSView?
    var sidebarSubtitle: NSView?
    var sidebarActions: [NSButton] = []
    var sidebarRecentHeader: NSView?
    var sidebarRecentButtons: [NSButton] = []
    var sidebarRecentEmpty: NSView?
    var sidebarAbout: NSButton?
    var sidebarSetup: NSButton?
    var sidebarPrivacy: NSButton?
    var sidebarTerms: NSButton?
    var sidebarVersionLabel: NSView?

    func controlTextDidChange(_ notification:Notification) {searchTextChanged(searchField)}
    @objc func searchTextChanged(_ sender: NSSearchField) {
        let query = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        applyFilter(query: query)
        enclosingScrollView?.contentView.scroll(to:.zero)
        if let parent = enclosingScrollView {parent.reflectScrolledClipView(parent.contentView)}
    }

    func applyFilter(query: String) {
        if query.isEmpty {
            sidebarSearch?.isSelected = false
            carousel?.isHidden = false
            categoryBar?.isHidden = false
            filterCards(categoryIndex: selectedCategoryIndex)
            return
        }

        sidebarSearch?.isSelected = true
        for item in sidebarNavItems { item.isSelected = false }

        carousel?.isHidden = true
        categoryBar?.isHidden = true

        let terms = query.split(whereSeparator:{$0.isWhitespace}).map(String.init)
        let matches = allCards.filter { item in
            terms.allSatisfy{item.card.searchableText.localizedStandardContains($0)}
        }
        for sec in sections {
            sec.isHidden = false
            for card in sec.cards {card.isHidden = !matches.contains(where:{$0.card === card})}
            let visibleCount = sec.cards.filter{!$0.isHidden}.count
            sec.header.tagBadge.stringValue = "\(visibleCount) " + (visibleCount == 1 ? "DOCUMENT" : "DOCUMENTS")
            let empty = visibleCount == 0
            sec.header.isHidden = empty;sec.shelf.isHidden = empty
            sec.shelf.contentView.scroll(to:.zero)
        }
        header.first.flatMap{$0 as? NSTextField}?.stringValue = "Search results"
        (header.count > 1 ? header[1] as? NSTextField : nil)?.stringValue = "\(matches.count) " + (matches.count == 1 ? "document" : "documents") + " matching “\(query)”"
        footer.forEach{$0.isHidden = true}

        cards = matches.map { $0.card }
        needsLayout = true
    }

    func filterCards(categoryIndex: Int) {
        selectedCategoryIndex = categoryIndex
        header.first.flatMap{$0 as? NSTextField}?.stringValue = categoryIndex == 0 ? "Discover" : ["Discover","IELTS Writing","Research","Essays"][categoryIndex]
        (header.count > 1 ? header[1] as? NSTextField : nil)?.stringValue = "Read closely. Find your next perspective."
        footer.forEach{$0.isHidden = false}
        searchField.stringValue = ""
        sidebarSearch?.isSelected = false
        carousel?.isHidden = categoryIndex != 0
        categoryBar?.isHidden = false
        for (i, item) in sidebarNavItems.enumerated() {
            item.isSelected = (i == categoryIndex)
        }
        categoryBar?.selectedIndex = categoryIndex

        let catFilter: String? = {
            switch categoryIndex {
            case 1: return "ielts"
            case 2: return "research"
            case 3: return "essays"
            default: return nil
            }
        }()

        if sections.isEmpty {
            if catFilter == nil {
                cards = Array(allCards.prefix(4).map { $0.card })
                for (i, item) in allCards.enumerated() {
                    item.card.isHidden = (i >= 4)
                }
            } else {
                cards = allCards.filter { $0.category == catFilter }.map { $0.card }
                for item in allCards {
                    item.card.isHidden = (item.category != catFilter)
                }
            }
        } else {
            for sec in sections {
                sec.header.tagBadge.stringValue = "\(sec.cards.count) DOCUMENTS"
                if let filter = catFilter {
                    sec.isHidden = (sec.key != filter)
                } else {
                    sec.isHidden = false
                }
            }
            cards = sections.filter { !$0.isHidden }.flatMap { $0.cards }
        }
        needsLayout = true
    }

    private var clipObserver: Any?
    var lastSidebarContentY: CGFloat = 400

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let clip = superview as? NSClipView {
            clip.postsBoundsChangedNotifications = true
            if let obs = clipObserver { NotificationCenter.default.removeObserver(obs) }
            clipObserver = NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: clip,
                queue: .main
            ) { [weak self] _ in
                self?.repositionStickySidebar()
            }
        }
    }

    deinit {
        if let obs = clipObserver { NotificationCenter.default.removeObserver(obs) }
    }

    func repositionStickySidebar() {
        guard let clip = superview else { return }
        let compact = max(600, clip.bounds.width) < 960
        let side: CGFloat = compact ? 200 : 240
        let sideW = side - 16
        let sideH = max(400, clip.bounds.height - 40)
        sidebar.wantsLayer = true;sidebar.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.94).cgColor;if let layer = sidebar.layer { LiquidGlass.configureLayer(layer, radius: 12, shadow: false) }
        sidebar.frame = NSRect(x: 12, y: clip.bounds.minY + 20, width: sideW + 8, height: sideH)

        let profileHeight: CGFloat = 42
        let profileY = sideH - profileHeight - 6
        sidebarProfile?.frame = NSRect(x: 2, y: profileY, width: sideW - 4, height: profileHeight)
    }

    override func layout() {
        super.layout()
        guard let clip = superview else { return }
        let width = max(600, clip.bounds.width)
        if frame.width != width {frame.size.width = width}
        let compact = width < 960
        let side: CGFloat = compact ? 200 : 240
        let contentWidth = width - side - 56

        let sideW = side - 16
        var curY: CGFloat = 4

        searchField.frame = NSRect(x: 4, y: curY, width: sideW - 8, height: 28)
        curY += 34

        for item in sidebarNavItems {
            item.frame = NSRect(x: 0, y: curY, width: sideW, height: 32)
            curY += 34
        }

        if let libHeader = sidebarLibraryHeader {
            curY += 12
            libHeader.frame = NSRect(x: 14, y: curY, width: sideW - 20, height: 16)
            curY += 22
        }

        for item in sidebarLibraryItems {
            item.frame = NSRect(x: 0, y: curY, width: sideW, height: 30)
            curY += 32
        }

        if sidebarLibraryItems.isEmpty && !sidebarActions.isEmpty {
            curY = 64
            for b in sidebarActions {
                b.frame = NSRect(x: 0, y: curY, width: sideW, height: 32)
                curY += 36
            }
        }

        if let recHeader = sidebarRecentHeader {
            curY += 12
            recHeader.frame = NSRect(x: 14, y: curY, width: max(80, sideW - 20), height: 16)
            curY += 22
        }

        for b in sidebarRecentButtons {
            b.isHidden = curY + 28 > clip.bounds.height - 120
            if b.isHidden {continue}
            b.frame = NSRect(x: 0, y: curY, width: sideW, height: 26)
            curY += 28
        }
        if let empty = sidebarRecentEmpty {
            empty.frame = NSRect(x: 14, y: curY, width: max(80, sideW - 20), height: 32)
            curY += 34
        }

        lastSidebarContentY = curY
        repositionStickySidebar()

        // Main content layout (tidy and neat, starting right under header)
        header[0].frame = NSRect(x: 0, y: 0, width: contentWidth, height: 34)
        if header.count > 1 { header[1].frame = NSRect(x: 0, y: 36, width: contentWidth, height: 22) }

        var curMainY: CGFloat = 68
        if let carousel = carousel, !carousel.isHidden {
            carousel.frame = NSRect(x: 0, y: curMainY, width: contentWidth, height: max(340,min(440,contentWidth * 0.52)))
            curMainY += carousel.frame.height + 20
        }

        if let categoryBar = categoryBar, !categoryBar.isHidden {
            let height:CGFloat = contentWidth < 700 ? 72 : 36
            categoryBar.frame = NSRect(x: 0, y: curMainY, width: contentWidth, height: height)
            curMainY += height + 24
        }

        let columns = compact ? 1 : 2
        let gap: CGFloat = 20
        let cardWidth = (contentWidth - CGFloat(columns - 1) * gap) / CGFloat(columns)
        let cardHeight: CGFloat = 276

        if sections.isEmpty {
            for (i, card) in cards.enumerated() {
                card.frame = NSRect(
                    x: CGFloat(i % columns) * (cardWidth + gap),
                    y: curMainY + CGFloat(i / columns) * (cardHeight + 20),
                    width: cardWidth,
                    height: cardHeight
                )
            }
            let bottom = curMainY + CGFloat((cards.count + columns - 1) / columns) * (cardHeight + 20) + 20
            curMainY = bottom
        } else {
            for sec in sections {
                let visibleCards = sec.cards.filter{!$0.isHidden}
                guard !sec.isHidden,!visibleCards.isEmpty else {sec.shelf.isHidden = true;continue}
                sec.shelf.isHidden = false
                sec.header.frame = NSRect(x:0,y:curMainY,width:contentWidth,height:68);curMainY += 76
                let searching = !searchField.stringValue.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty
                let tileWidth = min(370,contentWidth - 12)
                let columns = searching ? max(1,Int(contentWidth / (tileWidth + 16))) : visibleCards.count
                let cellWidth = searching ? (contentWidth - CGFloat(columns - 1) * 16) / CGFloat(columns) : tileWidth
                let rows = searching ? (visibleCards.count + columns - 1) / columns : 1
                let rowHeight = (visibleCards.map{$0.preferredHeight(width:cellWidth)}.max() ?? 260) + 16
                let height = CGFloat(rows) * rowHeight
                sec.shelf.frame = NSRect(x:0,y:curMainY,width:contentWidth,height:height)
                for (i,card) in visibleCards.enumerated(){card.frame = NSRect(x:CGFloat(i % columns) * (cellWidth + 16),y:CGFloat(i / columns) * rowHeight,width:cellWidth,height:rowHeight - 16)}
                sec.strip.frame = NSRect(x:0,y:0,width:searching ? contentWidth : max(contentWidth,CGFloat(visibleCards.count) * (tileWidth + 16) - 16),height:height - 4)
                curMainY += height + 28
            }
        }

        emptyResults.isHidden = !cards.filter{!$0.isHidden}.isEmpty
        emptyResults.frame = NSRect(x:0,y:curMainY,width:contentWidth,height:50)
        if !emptyResults.isHidden {curMainY += 70}
        let bottom = curMainY + 10
        if !footer.isEmpty {
            let btnW = min(300, contentWidth)
            footer[0].frame = NSRect(x: (contentWidth - btnW) / 2, y: bottom, width: btnW, height: 42)
        }
        if footer.count > 1 {
            footer[1].frame = NSRect(x: 0, y: bottom + 52, width: contentWidth, height: 22)
        }

        let totalH = max(clip.bounds.height - 40, curMainY + 120)
        main.frame = NSRect(x: side + 24, y: 20, width: contentWidth, height: totalH)
        frame.size.height = totalH + 40
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        main.addSubview(emptyResults);emptyResults.font = .systemFont(ofSize:15);emptyResults.textColor = .secondaryLabelColor
        searchField.placeholderString = "Search writing..."
        searchField.font = .systemFont(ofSize: 13)
        searchField.delegate = self
        searchField.sendsWholeSearchString = false
        searchField.sendsSearchStringImmediately = true
        searchField.target = self
        searchField.action = #selector(searchTextChanged(_:))
        sidebar.addSubview(searchField)
        addSubview(main)
        addSubview(sidebar)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("This view is created programmatically") }
}

extension Passage {
    @objc func showHome() {
        if opened { saveDraft() }
        opened = false
        lookupWork?.cancel()
        base()
        (root as? PaperBackdrop)?.decorated = false

        let dashboard = HomeDashboard(frame: root.bounds)
        let scroll = HomePageScrollView()
        scroll.contentView = HomePageClipView()
        scroll.horizontalScrollElasticity = .none
        scroll.hasHorizontalScroller = false
        scroll.drawsBackground = false
        scroll.contentView.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.documentView = dashboard
        attach(scroll, to: root)
        dashboard.autoresizingMask = [.width]

        // Keep the workspace quiet; imagery belongs to document covers only.
        (root as? PaperBackdrop)?.backgroundImage = nil

        func label(_ text: String, _ size: CGFloat, _ bold: Bool = false) -> NSTextField {
            let v = NSTextField(wrappingLabelWithString: text)
            v.font = .systemFont(ofSize: size, weight: bold ? .semibold : .regular)
            v.textColor = .labelColor
            return v
        }

        func truncateWords(_ text: String, maxChars: Int) -> String {
            let clean = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard clean.count > maxChars else { return clean }
            let prefix = String(clean.prefix(maxChars))
            if let lastSpace = prefix.lastIndex(of: " ") {
                return String(prefix[..<lastSpace]) + "…"
            }
            return prefix + "…"
        }

        // Apple TV Search item reference
        let searchItem = AppleTVSidebarItem(title: "", target: self, action: #selector(focusSearchOrFilter))
        dashboard.sidebarSearch = searchItem

        // Apple TV Primary Navigation Items
        let navConfigs: [(title: String, symbol: String, tag: Int)] = [
            ("Home", "sparkles.tv", 0),
            ("IELTS Prep", "graduationcap", 1),
            ("Research", "doc.text.magnifyingglass", 2),
            ("Essays", "text.quote", 3)
        ]

        var navButtons: [AppleTVSidebarItem] = []
        for conf in navConfigs {
            let item = AppleTVSidebarItem(title: "", target: self, action: #selector(selectHomeCategoryItem(_:)))
            item.tag = conf.tag
            item.itemTitle = conf.title
            item.sfSymbol = conf.symbol
            item.isSelected = (conf.tag == 0)
            dashboard.sidebar.addSubview(item)
            navButtons.append(item)
        }
        dashboard.sidebarNavItems = navButtons

        // Library Section
        let libHeader = label("LIBRARY", 10, true)
        libHeader.textColor = .secondaryLabelColor
        dashboard.sidebar.addSubview(libHeader)
        dashboard.sidebarLibraryHeader = libHeader

        let libActions: [(String, Selector, String)] = [
            ("New document…", #selector(showNewDocumentMenu(_:)), "square.and.pencil"),
            ("Writing library", #selector(showWritingLibrary), "folder"),
            ("Scanned texts", #selector(captureDocument), "doc.viewfinder"),
            ("Connect your agent", #selector(showAgentTools), "sparkles"),
            ("Continue draft", #selector(resumeDraft), "clock.arrow.circlepath")
        ]

        var libButtons: [AppleTVSidebarItem] = []
        for (i, a) in libActions.enumerated() {
            let item = AppleTVSidebarItem(title: "", target: self, action: a.1)
            item.itemTitle = a.0;item.setAccessibilityLabel(a.0)
            item.sfSymbol = a.2
            if i == 4 { // Continue draft
                item.isEnabled = FileManager.default.fileExists(atPath: saveURL.path)
                if !item.isEnabled { item.alphaValue = 0.4 }
            }
            dashboard.sidebar.addSubview(item)
            libButtons.append(item)
        }
        dashboard.sidebarLibraryItems = libButtons
        dashboard.sidebarActions = libButtons

        // Recent Section
        let recent = label("RECENTLY OPENED", 10, true)
        recent.textColor = .secondaryLabelColor
        dashboard.sidebar.addSubview(recent)
        dashboard.sidebarRecentHeader = recent

        let saved = LibraryStore.records(in: saveURL.deletingLastPathComponent().appendingPathComponent("Library"))
        let urls = (saved.map { $0.url } + NSDocumentController.shared.recentDocumentURLs.filter { FileManager.default.fileExists(atPath: $0.path) }).prefix(5)
        for url in urls {
            let title = saved.first(where: { $0.url == url })?.document.document.title ?? url.deletingPathExtension().lastPathComponent
            let low = (title + " " + url.lastPathComponent).lowercased()
            let icon: String = {
                if low.contains("doi") || low.contains("research") || low.contains("study") || low.contains("paper") {
                    return "🔬 "
                } else if low.contains("ielts") || low.contains("task") || low.contains("band") {
                    return "🎓 "
                } else if low.contains("essay") || low.contains("discursive") || low.contains("argument") {
                    return "✍️ "
                } else {
                    return "📄 "
                }
            }()
            let b = SidebarItemButton(title: "", target: self, action: #selector(openRecent))
            b.bezelStyle = .regularSquare
            b.isBordered = false
            b.wantsLayer = true
            if let layer = b.layer { LiquidGlass.configureLayer(layer, radius: 6, shadow: false) }
            let pStyle = NSMutableParagraphStyle()
            pStyle.alignment = .left
            pStyle.lineBreakMode = .byTruncatingTail
            b.attributedTitle = NSAttributedString(
                string: "  " + icon + title,
                attributes: [
                    .foregroundColor: NSColor.labelColor,
                    .font: NSFont.systemFont(ofSize: 12, weight: .regular),
                    .paragraphStyle: pStyle
                ]
            )
            b.identifier = .init(url.path)
            b.toolTip = url.path
            dashboard.sidebar.addSubview(b)
            dashboard.sidebarRecentButtons.append(b)
        }
        if urls.isEmpty {
            let empty = label("Opened documents appear here.", 12)
            empty.textColor = .secondaryLabelColor
            dashboard.sidebar.addSubview(empty)
            dashboard.sidebarRecentEmpty = empty
        }

        // Apple TV User Profile View
        let profile = AppleTVProfileView(frame: .zero)
        dashboard.sidebar.addSubview(profile)
        dashboard.sidebarProfile = profile

        // Secondary Footer Links (kept in dashboard for property references, accessed via profile menu)
        let about = GlassPillButton(title: "About", target: self, action: #selector(showAbout))
        dashboard.sidebarAbout = about

        let setup = GlassPillButton(title: "Quick setup", target: self, action: #selector(showOnboarding))
        dashboard.sidebarSetup = setup

        let priv = button("Privacy", #selector(showPrivacy))
        dashboard.sidebarPrivacy = priv

        let terms = button("Terms", #selector(showTerms))
        dashboard.sidebarTerms = terms

        let verLabel = label("Pass Passage By!", 10)
        verLabel.textColor = .tertiaryLabelColor
        dashboard.sidebarVersionLabel = verLabel

        // Main Content Header
        let head0 = label("Discover", 28, true)
        let head1 = label("Read closely. Find your next perspective.", 14)
        head1.textColor = .secondaryLabelColor
        head1.toolTip = "A curated showcase of annotated writing."
        dashboard.header = [head0, head1]
        for view in dashboard.header { dashboard.main.addSubview(view) }

        // Partner Showcase Carousel (Top Advertisement for Centers/Teachers)
        let carousel = PartnerShowcaseCarousel(frame: .zero)
        carousel.openTarget = self
        carousel.openAction = #selector(loadExample(_:))

        let p1Path = resourceDirectory.appendingPathComponent("Reading/workplace.json").path
        let p2Path = resourceDirectory.appendingPathComponent("Reading/structure.json").path
        let p3Path = resourceDirectory.appendingPathComponent("Samples/000-task2-1.json").path

        let pinned = showcaseDocuments()
        let defaults = [p1Path,p2Path,p3Path].compactMap {path -> (Breakdown,String)? in
            guard let bytes = try? Data(contentsOf:URL(fileURLWithPath:path)),let doc = try? JSONDecoder().decode(Breakdown.self,from:bytes) else{return nil};return (doc,path)
        }
        let slides = (pinned.isEmpty ? defaults : pinned).map {doc,path in
            PartnerSlide(partnerName:"",educator:"",badgeText:pinned.isEmpty ? "FEATURED READING" : "PINNED TO YOUR SHOWCASE",title:featuredTitle(doc),excerpt:truncateWords(readingPreview(doc.document.text),maxChars:150),pedagogyHighlight:"",tags:[readingType(doc.document.taskType),"\(doc.annotations.count) margin notes"],path:path,isResearch:doc.document.taskType == "research",accentColor:NSColor(calibratedRed:0.80,green:0.89,blue:0.76,alpha:1))
        }
        carousel.coverImage = NSImage(contentsOf:resourceDirectory.appendingPathComponent("Assets/reading-cover.png"))
        carousel.setupSlides(slides)
        dashboard.carousel = carousel
        dashboard.main.addSubview(carousel)

        // Writing Category Filter Bar
        let categoryBar = WritingCategoryBar(frame: .zero)
        categoryBar.onSelectCategory = { [weak dashboard] catIndex in
            dashboard?.filterCards(categoryIndex: catIndex)
        }
        dashboard.categoryBar = categoryBar
        dashboard.main.addSubview(categoryBar)

        // Shelves always describe the document they open.
        let sampleURLs = ((try? FileManager.default.contentsOfDirectory(at:resourceDirectory.appendingPathComponent("Samples"),includingPropertiesForKeys:nil)) ?? []).filter{$0.pathExtension == "json"}.sorted{$0.lastPathComponent < $1.lastPathComponent}
        let sampleDocs = sampleURLs.compactMap {url -> (Breakdown,URL)? in guard let bytes = try? Data(contentsOf:url),let doc = try? JSONDecoder().decode(Breakdown.self,from:bytes) else{return nil};return (doc,url)}
        let localDocs = LibraryStore.records(in:saveURL.deletingLastPathComponent().appendingPathComponent("Library")).map{($0.document,$0.url)}
        let readingURLs = ((try? FileManager.default.contentsOfDirectory(at:resourceDirectory.appendingPathComponent("Reading"),includingPropertiesForKeys:nil)) ?? []).filter{$0.pathExtension == "json" && $0.lastPathComponent != "manifest.json"}.sorted{$0.lastPathComponent < $1.lastPathComponent}
        let readings = readingURLs.compactMap {url -> (Breakdown,URL)? in guard let bytes = try? Data(contentsOf:url),let doc = try? JSONDecoder().decode(Breakdown.self,from:bytes) else{return nil};return (doc,url)}
        let agentURLs = ((try? FileManager.default.contentsOfDirectory(at:resourceDirectory.appendingPathComponent("AgentKit"),includingPropertiesForKeys:nil)) ?? []).filter{$0.lastPathComponent.hasSuffix("_sample.json")}.sorted{$0.lastPathComponent < $1.lastPathComponent}
        let agentDocs = agentURLs.compactMap {url -> (Breakdown,URL)? in guard let bytes = try? Data(contentsOf:url),let doc = try? JSONDecoder().decode(Breakdown.self,from:bytes) else{return nil};return (doc,url)}
        let studioDocs = agentDocs + localDocs.filter{$0.0.document.taskType == "administrative" || $0.0.document.taskType == "onboarding" || $0.0.document.taskType == "speech"}
        let groups:[(String,String,String,[(Breakdown,URL)])] = [
            ("essays","Structured Documents & SOP Studio","Nghị định 30/2020/NĐ-CP · Quy chế doanh nghiệp & Loom Onboarding",studioDocs),
            ("research","Research, close up","Open-access selections · credited authors · CC BY",readings.filter{$0.0.document.taskType == "research"} + localDocs.filter{$0.0.document.taskType == "research"}),
            ("essays","The craft of writing","Read the original advice, explore the margin notes",readings.filter{$0.0.document.taskType == "discursive"}),
            ("ielts","IELTS Writing","20 original practice essays · Task 1 and Task 2",sampleDocs),
            ("essays","Your writing","Continue reading and revising",localDocs.filter{$0.0.document.taskType != "research" && $0.0.document.taskType != "administrative" && $0.0.document.taskType != "onboarding" && $0.0.document.taskType != "speech"})]
        for (key,title,subtitle,documents) in groups where !documents.isEmpty {
            let header = HomeSectionHeader(badge:"\(documents.count) DOCUMENTS",title:title,subtitle:subtitle,accentColor:.controlAccentColor)
            dashboard.main.addSubview(header)
            var cards:[HomeCard] = []
            for (doc,url) in documents {
                let creditsURL = resourceDirectory.appendingPathComponent("Reading/manifest.json")
                let credits = (try? Data(contentsOf: creditsURL)).flatMap { try? JSONDecoder().decode([ReadingCardCredit].self, from: $0) } ?? []
                let credit = credits.first { $0.title == doc.document.title }
                let topic = doc.document.title.components(separatedBy: "·").last?.components(separatedBy: "—").first?.trimmingCharacters(in: .whitespaces) ?? "Writing"
                let author: String = {
                    if let a = credit?.authors { return a }
                    if doc.document.taskType == "administrative" { return "Nghị định 30/2020/NĐ-CP · Thể thức chuẩn" }
                    if doc.document.taskType == "onboarding" { return "SOP Hướng dẫn · Onboarding nhân sự mới" }
                    if key == "ielts" { return "Pass Passage By! · Original practice" }
                    return "Personal document"
                }()
                let tags = credit?.tags ?? (doc.document.taskType == "administrative" ? ["Văn bản hành chính", "Nghị định 30"] : (doc.document.taskType == "onboarding" ? ["SOP Quy trình", "Onboarding"] : (key == "ielts" ? [topic, readingType(doc.document.taskType)] : [readingType(doc.document.taskType)])))
                let card = HomeCard(title:doc.document.title,excerpt:truncateWords(readingPreview(doc.document.text),maxChars:140),annotation:author + "\n" + tags.joined(separator: "  ·  "),categoryTag:readingType(doc.document.taskType),categoryType:key,target:self,action:#selector(loadExample(_:)),path:url.path)
                card.searchableText = doc.document.title + " " + doc.document.text + " " + (doc.document.prompt ?? "") + " " + doc.annotations.map{$0.label + " " + $0.body}.joined(separator:" ")
                cards.append(card);dashboard.allCards.append((card:card,category:key))
            }
            let section = HomeDashboardSection(key:key,header:header,cards:cards)
            dashboard.main.addSubview(section.shelf);dashboard.sections.append(section)
        }
        dashboard.cards = dashboard.allCards.map{$0.card}
        let exploreBtn = GlassPillButton(title: "", target: self, action: #selector(showExampleLibrary))
        exploreBtn.bezelStyle = .regularSquare
        exploreBtn.isBordered = false
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        let expAttr = NSAttributedString(
            string: "Explore all 20 practice essays  →",
            attributes: [
                .foregroundColor: NSColor.labelColor,
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                .paragraphStyle: pStyle
            ]
        )
        exploreBtn.attributedTitle = expAttr

        let curLabel = label("Original practice material, curated by Pass Passage By!", 12)
        curLabel.alignment = .center
        curLabel.textColor = .secondaryLabelColor
        dashboard.footer = [exploreBtn, curLabel]
        for view in dashboard.footer { dashboard.main.addSubview(view) }

        root.layoutSubtreeIfNeeded()
        dashboard.needsLayout = true
    }

    @objc func selectHomeCategoryItem(_ sender: NSButton) {
        guard let scroll = root.subviews.first as? NSScrollView,
              let dashboard = scroll.documentView as? HomeDashboard else { return }
        dashboard.sidebarSearch?.isSelected = false
        dashboard.filterCards(categoryIndex: sender.tag)
    }

    @objc func focusSearchOrFilter() {
        guard let scroll = root.subviews.first as? NSScrollView,
              let dashboard = scroll.documentView as? HomeDashboard else {
            showExampleLibrary()
            return
        }
        for item in dashboard.sidebarNavItems { item.isSelected = false }
        dashboard.sidebarSearch?.isSelected = true
        window.makeFirstResponder(dashboard.searchField)
    }
    @objc func showAgentTools(){let panel = makeAgentWindow();infoWindow = panel;panel.center();panel.makeKeyAndOrderFront(nil)}
    func makeAgentWindow()->NSWindow {
        let panel = NSWindow(contentRect:NSRect(x:0,y:0,width:720,height:650),styleMask:[.titled,.closable],backing:.buffered,defer:false);panel.title = "Connect your agent";panel.isReleasedWhenClosed = false
        let page = MarginCanvas(frame:NSRect(x:0,y:0,width:720,height:650));panel.contentView = page
        func label(_ text:String,_ y:CGFloat,_ size:CGFloat = 13){let v = NSTextField(wrappingLabelWithString:text);v.font = .systemFont(ofSize:size);v.frame = NSRect(x:28,y:y,width:664,height:40);page.addSubview(v)}
        func action(_ title:String,_ selector:Selector,_ x:CGFloat,_ y:CGFloat,_ w:CGFloat){let b = button(title,selector);b.frame = NSRect(x:x,y:y,width:w,height:32);page.addSubview(b)}
        label("Your agent. Your documents.",22,25)
        label("Connect an MCP-capable agent, or exchange files with the AI app you already use.",64)
        label("CONNECTION",114,11)
        action("Copy MCP setup",#selector(copyMCPSetup),28,144,174)
        action("Export skill kit…",#selector(exportAgentKit),218,144,174)
        action("Add skill…",#selector(addSkill),408,144,132)
        label("DOCUMENT CONTEXT",198,11)
        action("Share current writing",#selector(shareAgentContext),28,224,192)
        action("Clear shared context",#selector(clearAgentContext),232,224,190)
        label("REQUEST",278,11)
        let topic = NSTextView(frame:NSRect(x:0,y:0,width:640,height:86));topic.isRichText = false;topic.font = .systemFont(ofSize:15);topic.textContainerInset = NSSize(width:10,height:10);topic.string = prefs.string(forKey:"agentBrief") ?? "Explain the argument and annotate useful vocabulary in Vietnamese. Preserve the original writing.";agentBrief = topic
        let scroll = NSScrollView(frame:NSRect(x:28,y:304,width:664,height:94));scroll.hasVerticalScroller = true;scroll.wantsLayer = true;if let layer = scroll.layer { LiquidGlass.configureLayer(layer, radius: 8, shadow: false) };topic.isVerticallyResizable = true;topic.autoresizingMask = [.width];topic.textContainer?.widthTracksTextView = true;scroll.documentView = topic;page.addSubview(scroll)
        let task = NSPopUpButton(frame:NSRect(x:28,y:412,width:200,height:28));task.addItems(withTitles:["IELTS Task 2","IELTS Task 1","Research & Academic Paper","Discursive Essay","Other writing"]);agentTask = task;page.addSubview(task)
        let skills = NSPopUpButton(frame:NSRect(x:244,y:412,width:448,height:28));agentSkills = skills;page.addSubview(skills);reloadAgentSkills()
        let context = NSButton(checkboxWithTitle:"Include current writing in copied brief",target:nil,action:nil);context.frame = NSRect(x:28,y:450,width:390,height:24);context.isEnabled = opened;agentContext = context;page.addSubview(context)
        action("Copy brief",#selector(copyAgentBrief),28,496,150)
        action("Open Inbox",#selector(openAgentInbox),194,496,150)
        action("Import result…",#selector(importAgentResult),360,496,160)
        let status = NSTextField(wrappingLabelWithString:"Only explicitly shared snapshots are available through MCP. The agent uses its own account; subscription support depends on the agent app. No API key or model download in PPB.");status.font = .systemFont(ofSize:12);status.textColor = .secondaryLabelColor;status.frame = NSRect(x:28,y:552,width:664,height:68);agentStatus = status;page.addSubview(status)
        return panel
    }
    func reloadAgentSkills(){
        guard let popup = agentSkills else{return};popup.removeAllItems();popup.addItem(withTitle:"PPB! annotated writing (built in)")
        let folder = saveURL.deletingLastPathComponent().appendingPathComponent("Skills")
        for url in ((try? FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil)) ?? []).sorted(by:{$0.lastPathComponent < $1.lastPathComponent}) where url.pathExtension.lowercased() == "md" {
            let filename = url.deletingPathExtension().lastPathComponent
            let title = filename.count > 37 && UUID(uuidString:String(filename.prefix(36))) != nil ? String(filename.dropFirst(37)) : filename
            popup.addItem(withTitle:title);popup.lastItem?.representedObject = url
        }
    }
    func agentInstruction()->String {
        let taskIndex = agentTask?.indexOfSelectedItem ?? 0
        let kind: String = {
            switch taskIndex {
            case 0: return "task2"
            case 1: return "task1"
            case 2: return "research"
            case 3: return "discursive"
            default: return "unknown"
            }
        }()
        var text = "Create an annotated writing document for Pass Passage By!. Task type: \(kind).\n\nREQUEST\n" + (agentBrief?.string ?? "")
        if kind == "research" {
            text += "\n\nACADEMIC RESEARCH & DOI GUIDELINES: Include structured DOI references (e.g. doi:10.1016/... or https://doi.org/...) and academic source annotations with abstract summaries."
        } else if kind == "discursive" {
            text += "\n\nARGUMENT FLOW GUIDELINES: Explicitly annotate thesis statement, concessions, counter-arguments, and dialectical synthesis."
        }
        if agentContext?.state == .on,opened {text += "\n\nCURRENT ESSAY (preserve unless revision is requested)\n" + data.document.text}
        if let url = agentSkills?.selectedItem?.representedObject as? URL,let skill = try? String(contentsOf:url,encoding:.utf8){text += "\n\nUSER-SELECTED FEEDBACK SKILL\n" + skill}
        for name in ["SKILL.md","schema.json"] {let url = resourceDirectory.appendingPathComponent("AgentKit/" + name);if let contract = try? String(contentsOf:url,encoding:.utf8){text += "\n\nPPB IMPORT CONTRACT — \(name)\n" + contract}}
        text += "\n\nReturn essay.md and annotations.json. For bridge.py and example.json, use the exported skill kit if available; otherwise follow the schema exactly and compute offsets in UTF-16 code units. Validate every quote. Do not claim to have imported the result."
        return text
    }
    @objc func copyAgentBrief(){
        prefs.set(agentBrief?.string,forKey:"agentBrief");NSPasteboard.general.clearContents();NSPasteboard.general.setString(agentInstruction(),forType:.string)
        agentStatus?.stringValue = "Copied request, selected skill and import schema. Paste into your agent."
    }
    @objc func importAgentResult(){
        let panel = NSOpenPanel();panel.allowedContentTypes = [.json];panel.begin { [weak self] result in
            guard let self = self,result == .OK,let url = panel.url else{return}
            do {if self.opened {self.saveDraft()};try self.loadJSON(Data(contentsOf:url));self.infoWindow?.close();self.openWorkspace()}catch{self.showAlert("Invalid annotated result: " + error.localizedDescription)}
        }
    }
}
