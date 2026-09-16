import Cocoa
import UniformTypeIdentifiers

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

final class PartnerShowcaseCarousel: NSView {
    override var isFlipped: Bool { true }

    var slides: [PartnerSlide] = []
    var currentIndex: Int = 0 { didSet { updateContent() } }

    weak var openTarget: AnyObject?
    var openAction: Selector?

    private let partnerBadge = NSTextField(wrappingLabelWithString: "")
    private let educatorLabel = NSTextField(wrappingLabelWithString: "")
    private let titleLabel = NSTextField(wrappingLabelWithString: "")
    private let excerptLabel = NSTextField(wrappingLabelWithString: "")
    private let pedagogyLabel = NSTextField(wrappingLabelWithString: "")
    private let tagsStack = NSStackView()
    private let actionButton = CardActionPill(title: "", target: nil, action: nil)

    private let prevButton = GlassPillButton(title: "‹", target: nil, action: nil)
    private let nextButton = GlassPillButton(title: "›", target: nil, action: nil)
    private var dotButtons: [NSButton] = []
    private let dotsContainer = NSStackView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        if let l = layer { LiquidGlass.configureLayer(l) }

        partnerBadge.font = .systemFont(ofSize: 11, weight: .bold)
        educatorLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        educatorLabel.textColor = .secondaryLabelColor

        titleLabel.font = .systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = .labelColor

        excerptLabel.font = NSFont(name: "Georgia", size: 13.5) ?? .systemFont(ofSize: 13.5)
        excerptLabel.textColor = .secondaryLabelColor

        pedagogyLabel.font = .systemFont(ofSize: 12, weight: .medium)
        pedagogyLabel.textColor = .labelColor

        actionButton.target = self
        actionButton.action = #selector(actionClicked)

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

        for v in [partnerBadge, educatorLabel, titleLabel, excerptLabel, pedagogyLabel, tagsStack, actionButton, prevButton, nextButton, dotsContainer] {
            addSubview(v)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

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
            b.font = .systemFont(ofSize: 12)
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

    @objc private func actionClicked() {
        guard currentIndex >= 0 && currentIndex < slides.count else { return }
        let slide = slides[currentIndex]
        actionButton.identifier = .init(slide.path)
        if let target = openTarget, let action = openAction {
            _ = target.perform(action, with: actionButton)
        }
    }

    func updateContent() {
        guard currentIndex >= 0 && currentIndex < slides.count else { return }
        let slide = slides[currentIndex]
        let isDark = LiquidGlass.isDark(for: self)

        partnerBadge.stringValue = slide.badgeText
        partnerBadge.textColor = slide.accentColor

        educatorLabel.stringValue = slide.partnerName + " · " + slide.educator

        titleLabel.stringValue = slide.title
        excerptLabel.stringValue = "“" + slide.excerpt + "”"
        pedagogyLabel.stringValue = slide.pedagogyHighlight

        for v in tagsStack.arrangedSubviews { tagsStack.removeArrangedSubview(v); v.removeFromSuperview() }
        for t in slide.tags {
            let pill = NSTextField(labelWithString: t)
            pill.font = .systemFont(ofSize: 11, weight: .medium)
            pill.textColor = .secondaryLabelColor
            tagsStack.addArrangedSubview(pill)
        }

        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        let btnTitle = slide.isResearch ? "Read research study with source previews  →" : "Read model essay with annotations  →"
        actionButton.attributedTitle = NSAttributedString(
            string: btnTitle,
            attributes: [
                .foregroundColor: isDark ? NSColor.white : slide.accentColor,
                .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
                .paragraphStyle: pStyle
            ]
        )

        for (i, b) in dotButtons.enumerated() {
            b.contentTintColor = (i == currentIndex) ? slide.accentColor : NSColor.tertiaryLabelColor
        }

        needsLayout = true
        needsDisplay = true
    }

    override func layout() {
        super.layout()
        let pad: CGFloat = 20
        let w = bounds.width - pad * 2

        partnerBadge.frame = NSRect(x: pad, y: 14, width: min(380, w - 80), height: 18)
        educatorLabel.frame = NSRect(x: pad, y: 34, width: min(480, w - 80), height: 18)

        let navBtnW: CGFloat = 28
        let navBtnH: CGFloat = 28
        nextButton.frame = NSRect(x: bounds.width - pad - navBtnW, y: 14, width: navBtnW, height: navBtnH)
        prevButton.frame = NSRect(x: bounds.width - pad - navBtnW * 2 - 8, y: 14, width: navBtnW, height: navBtnH)

        titleLabel.frame = NSRect(x: pad, y: 56, width: w, height: 26)
        excerptLabel.frame = NSRect(x: pad, y: 84, width: w, height: 40)
        pedagogyLabel.frame = NSRect(x: pad, y: 126, width: w, height: 32)

        let bottomY = bounds.height - 40
        tagsStack.frame = NSRect(x: pad, y: bottomY + 4, width: max(100, w - 380), height: 24)

        dotsContainer.frame = NSRect(x: bounds.width - pad - 360, y: bottomY + 4, width: 60, height: 24)
        actionButton.frame = NSRect(x: bounds.width - pad - 290, y: bottomY, width: 290, height: 30)
    }

    override func draw(_ dirtyRect: NSRect) {
        let isDark = LiquidGlass.isDark(for: self)
        LiquidGlass.drawCard(in: bounds, isDark: isDark, elevated: true)
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

    required init?(coder: NSCoder) { fatalError() }

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
        titleLabel.frame = NSRect(x: 4, y: 8, width: 85, height: 20)
        var curX: CGFloat = 95
        let btnH: CGFloat = 28
        for btn in pillButtons {
            let btnW = (btn.title as NSString).size(withAttributes: [.font: btn.font ?? NSFont.systemFont(ofSize: 12)]).width + 24
            btn.frame = NSRect(x: curX, y: 4, width: btnW, height: btnH)
            curX += btnW + 8
        }
    }
}

final class HomeCard: NSView {
    let categoryBadge = NSTextField(wrappingLabelWithString: "")
    let heading = NSTextField(wrappingLabelWithString: "")
    let detail = NSTextField(wrappingLabelWithString: "")
    let badge = NSTextField(wrappingLabelWithString: "")
    let note = NSTextField(wrappingLabelWithString: "")
    let open = CardActionPill(title: "", target: nil, action: nil)
    var doiButton: GlassPillButton?
    var categoryType: String = "ielts"
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
        wantsLayer = true
        if let l = layer { LiquidGlass.configureLayer(l) }

        let parts = annotation.split(separator: "\n", maxSplits: 1).map(String.init)
        let bText = parts.first ?? "Margin notes · PPB! practice"
        let nText = parts.count > 1 ? parts[1] : ""

        categoryBadge.stringValue = categoryTag.uppercased()
        categoryBadge.font = .systemFont(ofSize: 10, weight: .bold)

        heading.stringValue = title
        heading.font = .systemFont(ofSize: 17, weight: .semibold)
        heading.textColor = .labelColor

        detail.stringValue = excerpt
        detail.font = NSFont(name: "Georgia", size: 13.5) ?? .systemFont(ofSize: 13.5)
        detail.textColor = .secondaryLabelColor

        badge.stringValue = bText
        badge.font = .systemFont(ofSize: 11, weight: .semibold)

        note.stringValue = nText
        note.font = .systemFont(ofSize: 12, weight: .medium)
        note.textColor = .secondaryLabelColor

        open.target = target
        open.action = action
        open.identifier = .init(path)
        open.bezelStyle = .regularSquare
        open.isBordered = false

        var cardViews: [NSView] = [categoryBadge, heading, detail, badge, note, open]

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

        // Hover tooltip for quick preview
        let fullPreview = "\(title)\n\(bText)\n\(nText)"
        toolTip = fullPreview
        badge.toolTip = fullPreview
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

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let pad: CGFloat = 20
        let w = bounds.width - pad * 2
        categoryBadge.frame = NSRect(x: pad, y: 14, width: w, height: 16)
        heading.frame = NSRect(x: pad, y: 32, width: w, height: 24)
        detail.frame = NSRect(x: pad, y: 58, width: w, height: 52)
        badge.frame = NSRect(x: pad, y: 114, width: w, height: 18)
        note.frame = NSRect(x: pad, y: 134, width: w, height: 48)

        if let doiBtn = doiButton {
            let doiW: CGFloat = 68
            open.frame = NSRect(x: pad, y: bounds.height - 44, width: w - doiW - 10, height: 28)
            doiBtn.frame = NSRect(x: bounds.width - pad - doiW, y: bounds.height - 44, width: doiW, height: 28)
        } else {
            open.frame = NSRect(x: pad, y: bounds.height - 44, width: min(210, w), height: 28)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let isDark = LiquidGlass.isDark(for: self)

        // Liquid Glass card fill + gradient specular rim with hover elevation
        LiquidGlass.drawCard(in: bounds, isDark: isDark, elevated: isHovered)

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
        badge.textColor = accent
        note.textColor = isDark ? NSColor(calibratedWhite: 0.82, alpha: 1.0) : NSColor(calibratedWhite: 0.25, alpha: 1.0)

        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        let btnTitle = (categoryType == "research") ? "Read research  →" : "Read annotations  →"
        open.attributedTitle = NSAttributedString(
            string: btnTitle,
            attributes: [
                .foregroundColor: isDark ? NSColor.white : accent,
                .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
                .paragraphStyle: pStyle
            ]
        )
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

        titleLabel.stringValue = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .labelColor

        subtitleLabel.stringValue = subtitle
        subtitleLabel.font = .systemFont(ofSize: 12.5, weight: .regular)
        subtitleLabel.textColor = .secondaryLabelColor

        for v in [tagBadge, titleLabel, subtitleLabel] { addSubview(v) }
    }
    required init?(coder: NSCoder) { fatalError() }

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
    var isHidden: Bool = false {
        didSet {
            header.isHidden = isHidden
            for c in cards { c.isHidden = isHidden }
        }
    }

    init(key: String, header: HomeSectionHeader, cards: [HomeCard]) {
        self.key = key
        self.header = header
        self.cards = cards
    }
}

final class HomeDashboard: NSView {
    override var isFlipped: Bool { true }
    var sidebar = MarginCanvas(), main = MarginCanvas()
    var header: [NSView] = [], cards: [HomeCard] = [], footer: [NSView] = []
    var carousel: PartnerShowcaseCarousel?
    var categoryBar: WritingCategoryBar?
    var allCards: [(card: HomeCard, category: String)] = []
    var sections: [HomeDashboardSection] = []
    var selectedCategoryIndex: Int = 0

    // Sidebar elements for responsive layout
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

    func filterCards(categoryIndex: Int) {
        selectedCategoryIndex = categoryIndex
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

    override func layout() {
        super.layout()
        guard let clip = superview else { return }
        let width = max(600, clip.bounds.width)
        let compact = width < 960
        let side: CGFloat = compact ? 190 : 230
        let contentWidth = width - side - 56

        sidebar.frame = NSRect(x: 24, y: 24, width: side - 16, height: max(560, bounds.height - 48))
        main.frame = NSRect(x: side + 24, y: 24, width: contentWidth, height: 1200)

        // Responsively layout sidebar subviews
        let sideW = sidebar.bounds.width
        sidebarIcon?.frame = NSRect(x: 4, y: 4, width: 34, height: 34)
        sidebarBrand?.frame = NSRect(x: 46, y: 2, width: max(80, sideW - 48), height: 22)
        sidebarSubtitle?.frame = NSRect(x: 46, y: 24, width: max(80, sideW - 48), height: 18)

        for (i, b) in sidebarActions.enumerated() {
            b.frame = NSRect(x: 0, y: 64 + CGFloat(i) * 36, width: sideW, height: 32)
        }

        let recY = 64 + CGFloat(sidebarActions.count) * 36 + 18
        sidebarRecentHeader?.frame = NSRect(x: 6, y: recY, width: max(80, sideW - 12), height: 18)

        var curY = recY + 24
        for b in sidebarRecentButtons {
            b.frame = NSRect(x: 6, y: curY, width: max(80, sideW - 12), height: 24)
            curY += 26
        }
        if let empty = sidebarRecentEmpty {
            empty.frame = NSRect(x: 6, y: curY, width: max(80, sideW - 12), height: 36)
            curY += 38
        }

        let bottomPillY = max(curY + 16, 420)
        let pillGap: CGFloat = 8
        let pillW = max(50, (sideW - 12 - pillGap) / 2)
        sidebarAbout?.frame = NSRect(x: 6, y: bottomPillY, width: pillW, height: 26)
        sidebarSetup?.frame = NSRect(x: 6 + pillW + pillGap, y: bottomPillY, width: pillW, height: 26)

        let linkY = bottomPillY + 34
        sidebarPrivacy?.frame = NSRect(x: 6, y: linkY, width: pillW, height: 22)
        sidebarTerms?.frame = NSRect(x: 6 + pillW + pillGap, y: linkY, width: pillW, height: 22)

        // Main content layout (tidy and neat)
        header[0].frame = NSRect(x: 0, y: 0, width: contentWidth, height: 36)
        if header.count > 1 { header[1].frame = NSRect(x: 0, y: 38, width: contentWidth, height: 24) }

        var curMainY: CGFloat = 72
        if let carousel = carousel {
            carousel.frame = NSRect(x: 0, y: curMainY, width: contentWidth, height: 210)
            curMainY += 210 + 18
        }

        if let categoryBar = categoryBar {
            categoryBar.frame = NSRect(x: 0, y: curMainY, width: contentWidth, height: 36)
            curMainY += 36 + 24
        }

        let columns = compact ? 1 : 2
        let gap: CGFloat = 20
        let cardWidth = (contentWidth - CGFloat(columns - 1) * gap) / CGFloat(columns)

        if sections.isEmpty {
            for (i, card) in cards.enumerated() {
                card.frame = NSRect(
                    x: CGFloat(i % columns) * (cardWidth + gap),
                    y: curMainY + CGFloat(i / columns) * 276,
                    width: cardWidth,
                    height: 256
                )
            }
            let bottom = curMainY + CGFloat((cards.count + columns - 1) / columns) * 276 + 20
            curMainY = bottom
        } else {
            for sec in sections {
                guard !sec.isHidden else { continue }
                sec.header.frame = NSRect(x: 0, y: curMainY, width: contentWidth, height: 64)
                curMainY += 64 + 14

                for (i, card) in sec.cards.enumerated() {
                    card.frame = NSRect(
                        x: CGFloat(i % columns) * (cardWidth + gap),
                        y: curMainY + CGFloat(i / columns) * 276,
                        width: cardWidth,
                        height: 256
                    )
                }
                let rowCount = (sec.cards.count + columns - 1) / columns
                curMainY += CGFloat(rowCount) * 276 + 32
            }
        }

        let bottom = curMainY + 10
        if !footer.isEmpty {
            let btnW = min(340, contentWidth)
            footer[0].frame = NSRect(x: (contentWidth - btnW) / 2, y: bottom, width: btnW, height: 40)
        }
        if footer.count > 1 {
            footer[1].frame = NSRect(x: 0, y: bottom + 48, width: contentWidth, height: 22)
        }
        frame.size = NSSize(width: width, height: max(clip.bounds.height, bottom + 110))
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        addSubview(sidebar)
        addSubview(main)
    }
    required init?(coder: NSCoder) { fatalError() }
}

extension Passage {
    @objc func showHome() {
        if opened { saveDraft() }
        opened = false
        lookupWork?.cancel()
        base()
        (root as? PaperBackdrop)?.decorated = true

        let dashboard = HomeDashboard(frame: root.bounds)
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.documentView = dashboard
        attach(scroll, to: root)
        dashboard.autoresizingMask = [.width]

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

        // Sidebar Branding
        let icon = NSImageView(image: NSImage(named: "Passage") ?? NSImage(systemSymbolName: "book.closed", accessibilityDescription: "Pass Passage By!")!)
        icon.wantsLayer = true
        icon.layer?.cornerRadius = 10
        icon.layer?.masksToBounds = true
        dashboard.sidebar.addSubview(icon)
        dashboard.sidebarIcon = icon

        let brand = label("Pass Passage By!", 17, true)
        dashboard.sidebar.addSubview(brand)
        dashboard.sidebarBrand = brand

        let subtitle = label("Your writing studio", 12)
        subtitle.textColor = .secondaryLabelColor
        dashboard.sidebar.addSubview(subtitle)
        dashboard.sidebarSubtitle = subtitle

        // Sidebar Actions (Apple HIG native style)
        let actions: [(String, Selector, String)] = [
            ("New essay", #selector(newEssay), "square.and.pencil"),
            ("Scan document…", #selector(captureDocument), "doc.viewfinder"),
            ("Continue draft", #selector(resumeDraft), "clock.arrow.circlepath"),
            ("Create with an agent", #selector(showAgentTools), "sparkles"),
            ("My writing", #selector(showWritingLibrary), "folder"),
            ("Settings", #selector(showSettings), "gearshape")
        ]

        for (i, a) in actions.enumerated() {
            let b = SidebarItemButton(title: "", target: self, action: a.1)
            b.bezelStyle = .regularSquare
            b.isBordered = false
            b.wantsLayer = true
            b.layer?.cornerRadius = 8

            if let img = NSImage(systemSymbolName: a.2, accessibilityDescription: a.0) {
                let conf = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                b.image = img.withSymbolConfiguration(conf)
                b.imagePosition = .imageLeading
            }

            let pStyle = NSMutableParagraphStyle()
            pStyle.alignment = .left
            let attr = NSAttributedString(
                string: "  " + a.0,
                attributes: [
                    .foregroundColor: NSColor.labelColor,
                    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                    .paragraphStyle: pStyle
                ]
            )
            b.attributedTitle = attr
            b.contentTintColor = .labelColor

            if i == 2 {
                b.isEnabled = FileManager.default.fileExists(atPath: saveURL.path)
                if !b.isEnabled { b.layer?.opacity = 0.4 }
            }
            dashboard.sidebar.addSubview(b)
            dashboard.sidebarActions.append(b)
        }

        // Recent Section
        let recent = label("RECENT", 10, true)
        recent.textColor = .secondaryLabelColor
        dashboard.sidebar.addSubview(recent)
        dashboard.sidebarRecentHeader = recent

        let saved = LibraryStore.records(in: saveURL.deletingLastPathComponent().appendingPathComponent("Library"))
        let urls = (saved.map { $0.url } + NSDocumentController.shared.recentDocumentURLs.filter { FileManager.default.fileExists(atPath: $0.path) }).prefix(4)
        for url in urls {
            let b = NSButton(title: saved.first(where: { $0.url == url })?.document.document.title ?? url.deletingPathExtension().lastPathComponent, target: self, action: #selector(openRecent))
            b.isBordered = false
            b.alignment = .left
            b.lineBreakMode = .byTruncatingTail
            b.contentTintColor = .labelColor
            b.font = .systemFont(ofSize: 13)
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

        // Secondary Footer Links
        let about = GlassPillButton(title: "About", target: self, action: #selector(showAbout))
        about.bezelStyle = .regularSquare
        about.isBordered = false
        about.attributedTitle = NSAttributedString(
            string: "About",
            attributes: [.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 11, weight: .medium)]
        )
        dashboard.sidebar.addSubview(about)
        dashboard.sidebarAbout = about

        let setup = GlassPillButton(title: "Quick setup", target: self, action: #selector(showOnboarding))
        setup.bezelStyle = .regularSquare
        setup.isBordered = false
        setup.attributedTitle = NSAttributedString(
            string: "Quick setup",
            attributes: [.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 11, weight: .medium)]
        )
        dashboard.sidebar.addSubview(setup)
        dashboard.sidebarSetup = setup

        let priv = button("Privacy", #selector(showPrivacy))
        priv.isBordered = false
        priv.contentTintColor = .secondaryLabelColor
        priv.font = .systemFont(ofSize: 11)
        dashboard.sidebar.addSubview(priv)
        dashboard.sidebarPrivacy = priv

        let terms = button("Terms", #selector(showTerms))
        terms.isBordered = false
        terms.contentTintColor = .secondaryLabelColor
        terms.font = .systemFont(ofSize: 11)
        dashboard.sidebar.addSubview(terms)
        dashboard.sidebarTerms = terms

        // Main Content Header
        let head0 = label("Learn from a closer reading.", 28, true)
        let head1 = label("Featured writing · discover the choices behind a stronger essay.", 14)
        head1.textColor = .secondaryLabelColor
        head1.toolTip = "A curated showcase of annotated writing."
        dashboard.header = [head0, head1]
        for view in dashboard.header { dashboard.main.addSubview(view) }

        // Partner Showcase Carousel (Top Advertisement for Centers/Teachers)
        let carousel = PartnerShowcaseCarousel(frame: .zero)
        carousel.openTarget = self
        carousel.openAction = #selector(loadExample(_:))

        let p1Path = resourceDirectory.appendingPathComponent("Samples/000-task2-3.json").path
        let p2Path = resourceDirectory.appendingPathComponent("Samples/000-task2-1.json").path
        let p3Path = resourceDirectory.appendingPathComponent("Samples/013.json").path

        let slides = [
            PartnerSlide(
                partnerName: "IELTS Master Studio",
                educator: "Cô Mai Phương · British Council Certified",
                badgeText: "★ PARTNER SHOWCASE · BAND 8.5+ MENTOR",
                title: "Task 2 · Food waste & circular economy",
                excerpt: "Household food waste is a pervasive modern failure that squanders agricultural energy and arable land.",
                pedagogyHighlight: "Cô Mai Phương: Breakdowns of cohesive discourse markers, lexical collocation upgrades, and task response development.",
                tags: ["Band 8.5 Model", "IELTS Task 2", "Cohesion & Flow", "Lexical Upgrades"],
                path: p1Path,
                isResearch: false,
                accentColor: NSColor(calibratedRed: 0.2, green: 0.78, blue: 0.45, alpha: 1.0)
            ),
            PartnerSlide(
                partnerName: "The Writing Academy",
                educator: "Thầy Alex Thorne · Oxford Applied Linguistics",
                badgeText: "✦ VERIFIED EDUCATOR · ADVANCED COMPOSITION",
                title: "Task 2 · Public transport infrastructure",
                excerpt: "Urban transport budgets are often caught between visible mega-projects and reliable maintenance.",
                pedagogyHighlight: "Thầy Alex Thorne: Master-class demonstration of balanced counter-argumentation and formal academic register.",
                tags: ["Band 9 Model", "Argument Flow", "Counter-claims", "Lexical Resource"],
                path: p2Path,
                isResearch: false,
                accentColor: NSColor(calibratedRed: 0.38, green: 0.78, blue: 1.0, alpha: 1.0)
            ),
            PartnerSlide(
                partnerName: "Oxford Academic Research Hub",
                educator: "Dr. Minh Tuấn · Senior Research Fellow",
                badgeText: "🔬 ACADEMIC RESEARCH · SOURCE PREVIEWS",
                title: "Research & Policy · Sustainable Urban Mobility",
                excerpt: "Empirical transit evaluations across European metropolitan regions demonstrate a 27% reduction in personal vehicle trips (Chen et al., 2023).",
                pedagogyHighlight: "Dr. Minh Tuấn: Integrates interactive Source Previews, peer-reviewed DOI links, and empirical methodology notes.",
                tags: ["Research & Academic", "DOI Source Previews", "Empirical Evidence", "Methodology"],
                path: p3Path,
                isResearch: true,
                accentColor: NSColor(calibratedRed: 1.0, green: 0.65, blue: 0.2, alpha: 1.0)
            )
        ]
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

        // Categorized Sections & Cards
        let isDark = LiquidGlass.isDark(for: dashboard)

        // Section Headers
        let researchHeader = HomeSectionHeader(
            badge: "🔬 RESEARCH & ACADEMIC · 4 PAPERS",
            title: "Academic Research & Empirical Inquiries",
            subtitle: "Peer-reviewed studies with empirical methodologies, DOI links and hover source previews.",
            accentColor: LiquidGlass.researchAccent(isDark: isDark)
        )
        dashboard.main.addSubview(researchHeader)

        let essayHeader = HomeSectionHeader(
            badge: "✍️ ESSAYS & COMPOSITION · 4 ESSAYS",
            title: "Discursive & Argumentative Writing",
            subtitle: "Annotated with thesis statements, concession defense, and dialectical synthesis.",
            accentColor: LiquidGlass.essayAccent(isDark: isDark)
        )
        dashboard.main.addSubview(essayHeader)

        let ieltsHeader = HomeSectionHeader(
            badge: "🎓 IELTS EXAM PREPARATION · 4 TASKS",
            title: "IELTS Exam Practice & Scoring Breakdowns",
            subtitle: "Curated Task 1 data syntheses and Task 2 essays evaluated on official public band criteria.",
            accentColor: LiquidGlass.accent(isDark: isDark)
        )
        dashboard.main.addSubview(ieltsHeader)

        var researchCards: [HomeCard] = []
        var essayCards: [HomeCard] = []
        var ieltsCards: [HomeCard] = []
        var allCardItems: [(card: HomeCard, category: String)] = []

        // 1. Research & Academic Cards (with Source Previews & DOIs)
        let researchSpecs: [(file: String, title: String, excerpt: String, tag: String, note: String)] = [
            ("000-task2-3.json", "Research · Food Supply Logistics & Waste", "Empirical supply chain audits demonstrate 33% systemic losses before commercial retail distribution networks.", "Research · Source Preview & DOI", "Source Preview: Chen et al. (2023) · DOI: 10.1016/j.jclepro.2023.138902 · Empirical circular economy metrics."),
            ("000-task2-1.json", "Research · Urban Transit Infrastructure Elasticity", "Econometric models across European metropolitan areas show substantial carbon abatement following multimodal transit expansion.", "Research · Source Preview & Citations", "Source Preview: Thorne & Martinez (2022) · DOI: 10.1080/transit.2022.091 · Elasticity models in urban mobility."),
            ("013.json", "Research · Higher Education Enrollment Cohort Dynamics", "Demographic cohort analysis reveals non-linear growth in vocational enrollments between 2000 and 2020.", "Research · Statistical Analysis", "Source Preview: UNESCO Statistics (2021) · Comparative tertiary access dataset across 12 countries."),
            ("000-task2-6.json", "Research · Higher Education Subsidies & Fiscal Returns", "Fiscal return evaluations indicate public university tuition subsidies generate 2.4x long-term tax yields.", "Research · Policy Evidence", "Source Preview: OECD Education (2022) · DOI: 10.1787/19991487 · Public investment and social mobility indicators.")
        ]
        for spec in researchSpecs {
            let url = resourceDirectory.appendingPathComponent("Samples/" + spec.file)
            let card = HomeCard(title: spec.title, excerpt: spec.excerpt, annotation: spec.note, categoryTag: spec.tag, categoryType: "research", target: self, action: #selector(loadExample(_:)), path: url.path)
            researchCards.append(card)
            allCardItems.append((card: card, category: "research"))
            dashboard.main.addSubview(card)
        }

        // 2. Essays & Composition Cards
        let essaySpecs: [(file: String, title: String, excerpt: String, tag: String, note: String)] = [
            ("000-task2-6.json", "Discursive Essay · University Tuition & Social Equity", "Higher education represents both an individual career investment and a shared public good, justifying shared state funding.", "Essay · Argument Flow & Thesis", "Argument Flow · Thesis & Concession: Nuanced thesis concession followed by robust counter-argument refutation."),
            ("000-task2-2.json", "Argumentative Essay · Digital Pedagogy & Mentorship", "While digital platforms offer unprecedented accessibility, cognitive depth requires human guidance and deliberate mentorship.", "Essay · Thesis Defense", "Argument Flow · Dialectical Synthesis: Balanced dialectical synthesis comparing automated tools and human mentorship."),
            ("000-task2-5.json", "Persuasive Essay · Commercial Advertising & Children", "Targeting impressionable young minds with aggressive marketing creates early consumerist pressure and ethical dilemmas.", "Essay · Rhetorical Devices", "Rhetorical Strategy · Ethical Framing: Cause-and-effect transitions and emotional appeals framed ethically."),
            ("000-task2-8.json", "Analytical Essay · Practical Skills in School Curricula", "Secondary education must balance foundational intellectual rigor with pragmatic real-world competencies.", "Essay · Comparative Synthesis", "Structure · Comparative Synthesis: Point-by-point comparative synthesis and actionable policy proposal.")
        ]
        for spec in essaySpecs {
            let url = resourceDirectory.appendingPathComponent("Samples/" + spec.file)
            let card = HomeCard(title: spec.title, excerpt: spec.excerpt, annotation: spec.note, categoryTag: spec.tag, categoryType: "essays", target: self, action: #selector(loadExample(_:)), path: url.path)
            essayCards.append(card)
            allCardItems.append((card: card, category: "essays"))
            dashboard.main.addSubview(card)
        }

        // 3. IELTS Writing Cards
        let ieltsSpecs: [(file: String, tag: String, note: String)] = [
            ("000-task2-3.json", "IELTS · Task Response & Band 8.5", "Task Response: Identifies structural waste causes and consumer behavioral shifts."),
            ("000-task2-1.json", "IELTS · Cohesion & Lexical Resource", "Cohesion: Examines topic sentences and discourse transitions across paragraphs."),
            ("013.json", "IELTS Task 1 · Data Trends & Overview", "Overview Structure: Captures peak trajectory and subsequent plateau accurately."),
            ("000-task2-6.json", "IELTS · Task Achievement & Grammar", "Grammar: Complex condition clauses and modal structures supporting nuanced stance.")
        ]
        for spec in ieltsSpecs {
            let url = resourceDirectory.appendingPathComponent("Samples/" + spec.file)
            guard let bytes = try? Data(contentsOf: url), let sample = try? JSONDecoder().decode(Breakdown.self, from: bytes) else { continue }
            let excerpt = truncateWords(sample.document.text, maxChars: 140)
            let note = "\(sample.annotations.count) margin notes · PPB! practice\n\(spec.note)"
            let card = HomeCard(title: sample.document.title, excerpt: excerpt, annotation: note, categoryTag: spec.tag, categoryType: "ielts", target: self, action: #selector(loadExample(_:)), path: url.path)
            ieltsCards.append(card)
            allCardItems.append((card: card, category: "ielts"))
            dashboard.main.addSubview(card)
        }

        let rSec = HomeDashboardSection(key: "research", header: researchHeader, cards: researchCards)
        let eSec = HomeDashboardSection(key: "essays", header: essayHeader, cards: essayCards)
        let iSec = HomeDashboardSection(key: "ielts", header: ieltsHeader, cards: ieltsCards)

        dashboard.sections = [rSec, eSec, iSec]
        dashboard.allCards = allCardItems
        dashboard.filterCards(categoryIndex: 0)

        // Footer Action
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
    @objc func showAgentTools(){let panel=makeAgentWindow();infoWindow=panel;panel.center();panel.makeKeyAndOrderFront(nil)}
    func makeAgentWindow()->NSWindow {
        let panel=NSWindow(contentRect:NSRect(x:0,y:0,width:600,height:600),styleMask:[.titled,.closable],backing:.buffered,defer:false);panel.title="Create with an agent";panel.isReleasedWhenClosed=false
        let page=MarginCanvas(frame:NSRect(x:0,y:0,width:600,height:600));panel.contentView=page
        func label(_ text:String,_ y:CGFloat,_ size:CGFloat=13){let v=NSTextField(wrappingLabelWithString:text);v.font = .systemFont(ofSize:size);v.textColor = .labelColor;v.frame=NSRect(x:24,y:y,width:552,height:38);page.addSubview(v)}
        label("A brief for your agent. A lesson for your reader.",20,22)
        label("1  Describe the writing and feedback you want",70)
        let topic=NSTextView(frame:NSRect(x:0,y:0,width:536,height:100));topic.isRichText=false;topic.font = .systemFont(ofSize:15);topic.string=prefs.string(forKey:"agentBrief") ?? "Write about public transport. Explain the argument structure and annotate useful vocabulary in Vietnamese.";agentBrief=topic
        let scroll=NSScrollView(frame:NSRect(x:24,y:110,width:552,height:110));scroll.borderType = .bezelBorder;scroll.hasVerticalScroller=true;topic.isVerticallyResizable=true;topic.autoresizingMask=[.width];topic.textContainer?.widthTracksTextView=true;scroll.documentView=topic;page.addSubview(scroll)
        let task=NSPopUpButton(frame:NSRect(x:24,y:234,width:176,height:30));task.addItems(withTitles:["IELTS Task 2","IELTS Task 1","Other writing"]);agentTask=task;page.addSubview(task)
        let context=NSButton(checkboxWithTitle:"Include current essay",target:nil,action:nil);context.frame=NSRect(x:218,y:234,width:280,height:30);context.isEnabled=opened;agentContext=context;page.addSubview(context)
        label("Feedback skill",280)
        let skills=NSPopUpButton(frame:NSRect(x:24,y:310,width:400,height:30));agentSkills=skills;page.addSubview(skills);reloadAgentSkills()
        let add=button("Add skill…",#selector(addSkill));add.frame=NSRect(x:440,y:310,width:136,height:30);page.addSubview(add)
        label("2  Copy your brief into Antigravity or another agent",366)
        let copy=button("Copy agent brief",#selector(copyAgentBrief));copy.frame=NSRect(x:24,y:402,width:182,height:34);page.addSubview(copy)
        let kit=button("Export skill kit…",#selector(exportAgentKit));kit.frame=NSRect(x:218,y:402,width:170,height:34);page.addSubview(kit)
        label("3  Bring the annotated result back",462)
        let result=button("Import result JSON…",#selector(importAgentResult));result.frame=NSRect(x:24,y:498,width:200,height:34);page.addSubview(result)
        let status=NSTextField(wrappingLabelWithString:"Uses your own agent. No account or API key is needed in this app.");status.font = .systemFont(ofSize:12);status.textColor = .secondaryLabelColor;status.frame=NSRect(x:24,y:550,width:552,height:38);agentStatus=status;page.addSubview(status)
        return panel
    }
    func reloadAgentSkills(){
        guard let popup=agentSkills else{return};popup.removeAllItems();popup.addItem(withTitle:"PPB! annotated writing (built in)")
        let folder=saveURL.deletingLastPathComponent().appendingPathComponent("Skills")
        for url in ((try? FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil)) ?? []).sorted(by:{$0.lastPathComponent<$1.lastPathComponent}) where url.pathExtension.lowercased()=="md" {
            let filename=url.deletingPathExtension().lastPathComponent
            let title=filename.count>37 && UUID(uuidString:String(filename.prefix(36))) != nil ? String(filename.dropFirst(37)):filename
            popup.addItem(withTitle:title);popup.lastItem?.representedObject=url
        }
    }
    func agentInstruction()->String {
        let kind=agentTask?.indexOfSelectedItem==1 ? "task1":agentTask?.indexOfSelectedItem==2 ? "unknown":"task2"
        var text="Create an annotated writing document for Pass Passage By!. Task type: \(kind).\n\nREQUEST\n"+(agentBrief?.string ?? "")
        if agentContext?.state == .on,opened {text += "\n\nCURRENT ESSAY (preserve unless revision is requested)\n"+data.document.text}
        if let url=agentSkills?.selectedItem?.representedObject as? URL,let skill=try? String(contentsOf:url,encoding:.utf8){text += "\n\nUSER-SELECTED FEEDBACK SKILL\n"+skill}
        for name in ["SKILL.md","schema.json"] {let url=resourceDirectory.appendingPathComponent("AgentKit/"+name);if let contract=try? String(contentsOf:url,encoding:.utf8){text += "\n\nPPB IMPORT CONTRACT — \(name)\n"+contract}}
        text += "\n\nReturn essay.md and annotations.json. For bridge.py and example.json, use the exported skill kit if available; otherwise follow the schema exactly and compute offsets in UTF-16 code units. Validate every quote. Do not claim to have imported the result."
        return text
    }
    @objc func copyAgentBrief(){
        prefs.set(agentBrief?.string,forKey:"agentBrief");NSPasteboard.general.clearContents();NSPasteboard.general.setString(agentInstruction(),forType:.string)
        agentStatus?.stringValue="Copied request, selected skill and import schema. Paste into your agent."
    }
    @objc func importAgentResult(){
        let panel=NSOpenPanel();panel.allowedContentTypes=[.json];panel.begin { [weak self] result in
            guard let self=self,result == .OK,let url=panel.url else{return}
            do {if self.opened {self.saveDraft()};try self.loadJSON(Data(contentsOf:url));self.infoWindow?.close();self.openWorkspace()}catch{self.showAlert("Invalid annotated result: "+error.localizedDescription)}
        }
    }
}
