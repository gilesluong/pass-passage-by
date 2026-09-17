import Cocoa
import CoreServices
import UniformTypeIdentifiers
import QuartzCore

// Apple Dictionary Services Integration & HIG Components
final class DictionaryCatalog {
    var entries: [(String, DCSDictionary)] = []
    private(set) var lacViet: DCSDictionary?
    private(set) var oxford: DCSDictionary?
    private(set) var thesaurus: DCSDictionary?
    private(set) var tiengViet: DCSDictionary?

    init() {
        guard let h = dlopen("/System/Library/Frameworks/CoreServices.framework/Frameworks/DictionaryServices.framework/DictionaryServices", RTLD_LAZY),
              let a = dlsym(h, "DCSCopyAvailableDictionaries"),
              let n = dlsym(h, "DCSDictionaryGetName") else { return }
        typealias Available = @convention(c) () -> Unmanaged<AnyObject>?
        typealias Name = @convention(c) (AnyObject) -> Unmanaged<CFString>?
        guard let obj = unsafeBitCast(a, to: Available.self)()?.takeRetainedValue(),
              let set = obj as? NSSet else { return }
        let getName = unsafeBitCast(n, to: Name.self)
        for item in set {
            if let title = getName(item as AnyObject)?.takeUnretainedValue() as String? {
                let dict = unsafeBitCast(item as AnyObject, to: DCSDictionary.self)
                entries.append((title, dict))
                if title.contains("Lạc Việt") { lacViet = dict }
                else if title.contains("Oxford Dictionary of English") || (oxford == nil && title.contains("New Oxford")) { oxford = dict }
                else if title.contains("Thesaurus") && (thesaurus == nil || title.contains("Writer’s Thesaurus")) { thesaurus = dict }
                else if title.contains("Từ Điển Tiếng Việt") { tiengViet = dict }
            }
        }
        entries.sort { $0.0 < $1.0 }
    }

    func lookup(word: String, dictionary: DCSDictionary?) -> String? {
        let clean = word.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
        guard !clean.isEmpty else { return nil }
        let cf = clean.lowercased() as CFString
        let r = CFRange(location: 0, length: (clean as NSString).length)
        if let d = dictionary {
            return DCSCopyTextDefinition(d, cf, r)?.takeRetainedValue() as String?
        }
        return DCSCopyTextDefinition(nil, cf, r)?.takeRetainedValue() as String?
    }
}

final class DictionaryTabButton: NSButton {
    override var isFlipped: Bool { true }
    var isSelectedTab = false { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        let isDark = LiquidGlass.isDark(for: self)
        if isSelectedTab {
            let fill = isDark ? NSColor.white.withAlphaComponent(0.20) : NSColor.black.withAlphaComponent(0.12)
            fill.setFill()
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 6, yRadius: 6)
            path.fill()
        }
        super.draw(dirtyRect)
    }
}

final class AppleDictionaryToolbar: NSView {
    override var isFlipped: Bool { true }
    let backButton = NSButton()
    let forwardButton = NSButton()
    let countLabel = NSTextField(labelWithString: "")
    var tabButtons: [DictionaryTabButton] = []
    var onSelectTab: ((Int) -> Void)?
    var selectedIndex: Int = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        backButton.bezelStyle = .regularSquare
        backButton.isBordered = false
        backButton.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Back")

        forwardButton.bezelStyle = .regularSquare
        forwardButton.isBordered = false
        forwardButton.image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: "Forward")

        countLabel.font = .systemFont(ofSize: 11, weight: .medium)
        countLabel.textColor = .secondaryLabelColor

        let titles = ["All", "Lạc Việt", "Oxford", "Thesaurus", "Tiếng Việt"]
        for (i, t) in titles.enumerated() {
            let b = DictionaryTabButton(title: t, target: self, action: #selector(tabClicked(_:)))
            b.isBordered = false
            b.bezelStyle = .regularSquare
            b.tag = i
            b.font = .systemFont(ofSize: 12, weight: i == 0 ? .semibold : .regular)
            b.isSelectedTab = (i == 0)
            b.contentTintColor = i == 0 ? .labelColor : .secondaryLabelColor
            tabButtons.append(b)
            addSubview(b)
        }

        for v in [backButton, forwardButton, countLabel] { addSubview(v) }
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("This view is created programmatically") }

    @objc func tabClicked(_ sender: DictionaryTabButton) {
        setSelectedIndex(sender.tag)
        onSelectTab?(sender.tag)
    }

    func setSelectedIndex(_ index: Int) {
        selectedIndex = index
        for (i, b) in tabButtons.enumerated() {
            b.isSelectedTab = (i == index)
            b.font = .systemFont(ofSize: 12, weight: i == index ? .semibold : .regular)
            b.contentTintColor = i == index ? .labelColor : .secondaryLabelColor
        }
    }

    override func layout() {
        super.layout()
        backButton.frame = NSRect(x: 10, y: 7, width: 28, height: 24)
        forwardButton.frame = NSRect(x: 40, y: 7, width: 28, height: 24)
        countLabel.frame = NSRect(x: 74, y: 9, width: 66, height: 20)

        var tabX: CGFloat = 145
        let widths: [CGFloat] = [46, 76, 68, 86, 84]
        for (i, b) in tabButtons.enumerated() {
            let bw = widths[i]
            b.frame = NSRect(x: tabX, y: 7, width: bw, height: 24)
            tabX += bw + 6
        }
    }
}

final class AppleDictionaryPaneView: NSView {
    override var isFlipped: Bool { true }
    var toolbar: AppleDictionaryToolbar!
    var wordListScroll: NSScrollView?
    var divider = NSBox()
    var definitionScroll: NSScrollView!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        if let l = layer { LiquidGlass.configureLayer(l, radius: LiquidGlass.smallCornerRadius, shadow: true) }
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("This view is created programmatically") }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height
        if let tb = toolbar { tb.frame = NSRect(x: 0, y: 0, width: w, height: 38) }
        let contentH = max(100, h - 38)
        if let ds = definitionScroll { ds.frame = NSRect(x: 0, y: 39, width: w, height: contentH) }
    }

    override func draw(_ dirtyRect: NSRect) {
        let isDark = LiquidGlass.isDark(for: self)
        LiquidGlass.drawCard(in: bounds, isDark: isDark, radius: LiquidGlass.smallCornerRadius, elevated: true)

        let stroke = isDark ? NSColor.white.withAlphaComponent(0.12) : NSColor.black.withAlphaComponent(0.08)
        let linePath = NSBezierPath()
        linePath.move(to: NSPoint(x: 0, y: 38))
        linePath.line(to: NSPoint(x: bounds.width, y: 38))
        stroke.setStroke()
        linePath.lineWidth = 1
        linePath.stroke()
        super.draw(dirtyRect)
    }
}

final class FloatingCommentPill: NSButton {
    override var isFlipped: Bool { true }
    private var trackingArea: NSTrackingArea?
    private var isHovered = false { didSet { needsDisplay = true } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        bezelStyle = .regularSquare
        isBordered = false
        wantsLayer = true
        if let l = layer { LiquidGlass.configureLayer(l) }
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

    override func draw(_ dirtyRect: NSRect) {
        let isDark = LiquidGlass.isDark(for: self)
        let radius: CGFloat = bounds.height / 2
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius)

        let bg = isHovered 
            ? (isDark ? NSColor(white: 0.28, alpha: 0.96) : NSColor(white: 0.98, alpha: 0.98))
            : (isDark ? NSColor(white: 0.16, alpha: 0.92) : NSColor(white: 0.92, alpha: 0.95))
        bg.setFill()
        path.fill()

        LiquidGlass.drawSpecularRim(in: bounds.insetBy(dx: 0.5, dy: 0.5), isDark: isDark, radius: radius)
        super.draw(dirtyRect)
    }
}

// MARK: - Writing View with Semantic Zoom & Point Focus
class WritingView: NSTextView {
    var receiveScan:((NSPasteboard)->Bool)?
    override func validRequestor(forSendType sendType:NSPasteboard.PasteboardType?,returnType:NSPasteboard.PasteboardType?)->Any? {
        if let type = returnType,NSImage.imageTypes.contains(type.rawValue) || type == .pdf {return self}
        return super.validRequestor(forSendType:sendType,returnType:returnType)
    }
    override func readSelection(from board:NSPasteboard)->Bool {
        if board.canReadItem(withDataConformingToTypes:NSImage.imageTypes + ["com.adobe.pdf"]),receiveScan?(board) == true {return true}
        return super.readSelection(from:board)
    }
    override func paste(_ sender:Any?) {
        if NSPasteboard.general.canReadItem(withDataConformingToTypes:NSImage.imageTypes + ["com.adobe.pdf"]),receiveScan?(.general) == true {return}
        super.paste(sender)
    }
    var receiveFiles: (([URL]) -> Void)?
    override func draggingEntered(_ sender:NSDraggingInfo)->NSDragOperation {
        sender.draggingPasteboard.canReadObject(forClasses:[NSURL.self],options:[.urlReadingFileURLsOnly:true]) ? .copy : super.draggingEntered(sender)
    }
    override func performDragOperation(_ sender:NSDraggingInfo)->Bool {
        if let urls = sender.draggingPasteboard.readObjects(forClasses:[NSURL.self],options:[.urlReadingFileURLsOnly:true]) as? [URL],!urls.isEmpty {receiveFiles?(urls);return true}
        return super.performDragOperation(sender)
    }
    var zoom: ((Int) -> Void)?
    var point: ((Int) -> Void)?
    var hoverRange: ((Int) -> NSRange)?
    var editAnnotation: ((Int, NSPoint) -> Bool)?
    var onHoverIndex: ((Int?, NSPoint) -> Void)?
    var pointerMode: () -> String = { UserDefaults.standard.string(forKey:"pointerMode") ?? "Hold Option" }
    var showsPointerHighlight: Bool {
        PointerPolicy.isModifierActive(mode: pointerMode(), flags: NSEvent.modifierFlags)
    }
    private var hover: NSRange?
    var pointerIndex: Int?
    private var hoverTimer: Timer?
    deinit { hoverTimer?.invalidate() }
    private var tracking: NSTrackingArea?
    private var accumulated: CGFloat = 0

    override func mouseDown(with event:NSEvent) {
        let point = convert(event.locationInWindow,from:nil)
        if event.clickCount == 2, editAnnotation?(characterIndexForInsertion(at:point),point) == true {clearPointer();return}
        super.mouseDown(with:event)
    }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = tracking { removeTrackingArea(t) }
        let t = NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(t)
        tracking = t
    }

    func updatePointer(at point: NSPoint) {
        guard visibleRect.contains(point), !string.isEmpty else { return }
        let index = min(characterIndexForInsertion(at: point), (string as NSString).length - 1)
        pointerIndex = index
        hover = showsPointerHighlight ? hoverRange?(index) : nil
        if !showsPointerHighlight {hoverTimer?.invalidate();hoverTimer = nil}
        onHoverIndex?(index, point)
        if showsPointerHighlight && hoverTimer == nil && UserDefaults.standard.string(forKey: "hoverStyle") == "Stardust" && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in self?.needsDisplay = true }
        }
        needsDisplay = true
    }

    func clearPointer() {
        hoverTimer?.invalidate(); hoverTimer = nil
        pointerIndex = nil; hover = nil; needsDisplay = true
        onHoverIndex?(nil, .zero)
    }

    override func mouseMoved(with event: NSEvent) {
        updatePointer(at: convert(event.locationInWindow, from: nil))
        super.mouseMoved(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        // Keep the last pointer target for a subsequent click on the zoom dock.
        hoverTimer?.invalidate(); hoverTimer = nil
        hover = nil; needsDisplay = true
        onHoverIndex?(nil, .zero)
        super.mouseExited(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        if let range = hover, range.length > 0, NSMaxRange(range) <= (string as NSString).length,
           let manager = layoutManager, let container = textContainer {
            let style = UserDefaults.standard.string(forKey: "hoverStyle") ?? "Solid"
            let glyphs = manager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            manager.enumerateEnclosingRects(forGlyphRange: glyphs, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: container) { rect, _ in
                let box = rect.offsetBy(dx: self.textContainerOrigin.x, dy: self.textContainerOrigin.y).insetBy(dx: -2, dy: -1)
                let path = NSBezierPath(roundedRect: box, xRadius: 5, yRadius: 5)
                if style == "Solid" {
                    NSColor.systemTeal.withAlphaComponent(UserDefaults.standard.bool(forKey:"dark") ? 0.38 : 0.22).setFill(); path.fill()
                } else {
                    NSGradient(starting: .systemCyan.withAlphaComponent(UserDefaults.standard.bool(forKey:"dark") ? 0.36 : 0.20), ending: .systemPurple.withAlphaComponent(UserDefaults.standard.bool(forKey:"dark") ? 0.38 : 0.24))?.draw(in: path, angle: 0)
                }
                if style == "Stardust" {
                    let time = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : Date.timeIntervalSinceReferenceDate
                    NSColor.systemPurple.withAlphaComponent(0.35).setFill()
                    for i in 0..<min(18, max(3, Int(box.width / 25))) {
                        let x = box.minX + (Double(i) * 37 + time * 9).truncatingRemainder(dividingBy: max(1,box.width))
                        let y = box.minY + 3 + (sin(time * 1.4 + Double(i) * 2) + 1) * max(1,box.height - 6) / 2
                        NSBezierPath(ovalIn: NSRect(x:x,y:y,width:2,height:2)).fill()
                    }
                }
            }
        }
        super.draw(dirtyRect)
        if string.isEmpty {
            ("Start writing…" as NSString).draw(at: textContainerOrigin, withAttributes: [
                .font: font ?? NSFont.systemFont(ofSize: 22),
                .foregroundColor: NSColor.placeholderTextColor
            ])
        }
    }

    override func magnify(with event: NSEvent) {
        if event.phase == .began {
            accumulated = 0
            let p = convert(event.locationInWindow, from: nil)
            point?(characterIndexForInsertion(at: p))
        }
        accumulated += event.magnification
        if abs(accumulated) > 0.22 {
            zoom?(accumulated > 0 ? 1 : -1)
            accumulated = 0
        }
    }

    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            if event.phase == .began {
                accumulated = 0
                point?(characterIndexForInsertion(at: convert(event.locationInWindow, from: nil)))
            }
            accumulated += event.scrollingDeltaY / 250
            if abs(accumulated) > 0.22 {
                zoom?(accumulated < 0 ? 1 : -1)
                accumulated = 0
            }
        } else {
            super.scrollWheel(with: event)
        }
    }
}

class MarginCanvas: NSView {
    override var isFlipped: Bool { true }
    var arrangedSubviews: [NSView] { subviews }
    func addArrangedSubview(_ view: NSView) { addSubview(view) }
    func removeArrangedSubview(_ view: NSView) { view.removeFromSuperview() }
}

final class MarginNoteCard: NSView {
    override var isFlipped: Bool { true }
    private let content: [NSView]
    var activate: (() -> Void)?
    init(content: [NSView], identifier: String) {
        self.content = content
        super.init(frame: .zero)
        self.identifier = NSUserInterfaceItemIdentifier(identifier)
        for view in content { addSubview(view) }
        setAccessibilityRole(.button)
        setAccessibilityLabel("Edit margin annotation")
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(content:identifier:)") }
    override func hitTest(_ point: NSPoint) -> NSView? { super.hitTest(point) == nil ? nil : self }
    override func mouseDown(with event: NSEvent) { activate?() }
    override func accessibilityPerformPress() -> Bool { activate?(); return activate != nil }
    func desiredHeight(width: CGFloat) -> CGFloat { 100 }
    override func layout() {
        super.layout()
        let width = max(60, bounds.width - 24)
        let rects = [NSRect(x: 12, y: 8, width: width, height: 14),
                     NSRect(x: 12, y: 26, width: width, height: 20),
                     NSRect(x: 12, y: 50, width: width, height: 38),
                     NSRect(x: 12, y: 88, width: width, height: 0)]
        for (view, rect) in zip(content, rects) { view.frame = rect }
    }
}

// MARK: - Annotation Connector Lines View (Requirement 3)
class ConnectorOverlayView: NSView {
    var geometryChanged:(()->Void)?
    private var lastFrame = NSRect.null
    override func layout(){
        super.layout()
        if frame != lastFrame {lastFrame = frame;geometryChanged?()}
    }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    struct Connection {
        var startPoint: NSPoint // On note card edge
        var endPoint: NSPoint   // On text glyph
        var color: NSColor
    }
    var connections: [Connection] = [] {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard !connections.isEmpty else { return }
        for conn in connections {
            let path = NSBezierPath()
            path.lineWidth = 1.4
            path.lineCapStyle = .round
            conn.color.withAlphaComponent(0.45).setStroke()
            conn.color.withAlphaComponent(0.65).setFill()

            // Smooth cubic bezier connector
            path.move(to: conn.startPoint)
            let midX = (conn.startPoint.x + conn.endPoint.x) / 2.0
            path.curve(to: conn.endPoint, controlPoint1: NSPoint(x: midX, y: conn.startPoint.y), controlPoint2: NSPoint(x: midX, y: conn.endPoint.y))
            path.stroke()

            // Draw small terminal dot at text anchor
            let dotRect = NSRect(x: conn.endPoint.x - 2.5, y: conn.endPoint.y - 2.5, width: 5, height: 5)
            NSBezierPath(ovalIn: dotRect).fill()
        }
    }
}

// MARK: - Main Application
@main
class Passage: NSObject, NSApplicationDelegate, NSTextViewDelegate, NSWindowDelegate, NSPopoverDelegate, NSTextFieldDelegate {
    var window: NSWindow!
    var root: NSView!
    var layoutRefresh:DispatchWorkItem?
    var briefEditButton:NSButton?
    var briefToggleButton:NSButton?
    var taskToggleRow:NSView?
    var preferencesTabs:NSTabView?
    var preferencesNavigation:[NSButton] = []
    var briefHidden = false
    var promptEditor:NSTextView?
    var taskPromptField:NSTextField?
    var taskBrief = ClipScrollView()
    var taskBriefHeight:NSLayoutConstraint?
    var briefTransition = 0
    var briefAnimating = false
    var annotationSave:DispatchWorkItem?
    var appearanceToggle:NSButton?
    var shareController:ShareController?
    var editor = WritingView()
    var scroll = NSScrollView()
    
    // Two-sided margin notes
    var leftNotes = MarginCanvas()
    var leftScroll = NSScrollView()
    var rightNotes = MarginCanvas()
    var rightScroll = NSScrollView()
    var connectorView = ConnectorOverlayView()
    var editorContainer = NSView()

    // Dictionary pane (Apple Dictionary HIG layout)
    var dictionaryPane = AppleDictionaryPaneView()
    var dictToolbar = AppleDictionaryToolbar()
    var dictWordListScroll = NSScrollView()
    var dictWordListView = MarginCanvas()
    var dictionaryScroll = NSScrollView()
    var definition = NSTextView()
    var definitionButton = NSButton()
    var currentDefinition = ""
    var currentWord = ""
    var currentDefinitionEntries: [(title: String, content: String)] = []
    var dictHistory: [String] = []
    var dictHistoryIndex: Int = -1
    var selectedDictTab: Int = 0
    var fullDefinition = false

    var header = NSTextField(labelWithString: "")
    var titleField = NSTextField()
    var levels = NSSegmentedControl()

    var data = Breakdown.plain("", title: "Untitled Essay")
    var level = 0
    var visible = NSRange(location: 0, length: 0)
    var focus = 0
    var updating = false
    var opened = false
    var past = [Breakdown]()
    var future = [Breakdown]()
    var lookupWork: DispatchWorkItem?
    var cache = [String: String]()
    var lastZoom = Date.distantPast
    let dictionaries = DictionaryCatalog()
    var zoomMonitor: Any?
    var pointerMonitor: Any?
    var floatingCommentButton: NSButton?
    var zoomPathPicker: ZoomPathPicker?
    var gestureDelta: CGFloat = 0

    // Settings & Comment Popovers
    var zoomPresetControl: NSPopUpButton?
    var zoomRouteLabel: NSTextField?
    var scanReview:ScanReview?
    var writingLibrary:WritingLibrary?
    var agentBrief:NSTextView?
    var agentTask:NSPopUpButton?
    var agentContext:NSButton?
    var agentSkills:NSPopUpButton?
    var agentStatus:NSTextField?
    var infoWindow: NSWindow?
    let appUpdates = AppUpdates()
    var preferencesWindow: NSWindow?
    var settings: NSPopover?
    var commentsPane = InspectorSurface()
    var commentsWidth: NSLayoutConstraint?
    var commentsVisible = false
    var commentsEditing = false
    var editingSurface = NoteSurface.annotation
    var commentPopover: NSPopover?
    var hoverSourcePopover: NSPopover?
    var lastHoverNoteId: String?
    var commentField = NSTextView()
    var commentKind = NSPopUpButton()
    var commentTag = NSPopUpButton()
    var commentLabel = NSTextField()
    var editingInline = false
    var textRefresh: DispatchWorkItem?
    var imageWindow: NSWindow?
    var editingNoteId: String?
    var targetRange = NSRange(location: 0, length: 0)

    var centerStack: NSStackView?
    var topBar: NSStackView?
    var paneHeightConstraints: [NSLayoutConstraint] = []
    var dock: NSView?
    var presentation = false
    var exitPresentation = NSButton()
    var scrollObserver: NSObjectProtocol?


    var wordHeight: NSLayoutConstraint?
    var leftWidth: NSLayoutConstraint?
    var rightWidth: NSLayoutConstraint?
    var dictWidth: NSLayoutConstraint?

    var resourceDirectory:URL {(Bundle.main.resourceURL ?? Bundle.main.bundleURL)}
    var prefs = UserDefaults.standard
    var saveURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Passage/native-draft.json")
    }

    static func main() {
        let app = NSApplication.shared
        let d = Passage()
        app.delegate = d
        app.setActivationPolicy(.regular)
        withExtendedLifetime(d) { app.run() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        prefs.register(defaults: [
            "pointerMode": "Hold fn",
            "font": "Georgia",
            "size": 22,
            "spacing": 1.65,
            "dark": false,
            "canvas": "Plain paper",
            "notes": true,
            "theme": "Paper", "briefSize": 21.0,
            "onboarded": false, "zoomPreset": "Student", "zoomParagraph": false, "zoomSentence": false, "paragraphSpacing": 36.0, "lineWidth": 820.0, "indent": 0.0
        ])
        // Restore the approved paper/serif direction once, without touching drafts.
        if prefs.integer(forKey: "referenceDesignRevision") < 1 {
            prefs.set("Plain paper", forKey: "canvas"); prefs.set("Georgia", forKey: "font"); prefs.set("Paper", forKey: "theme")
            prefs.set(false, forKey: "dark"); prefs.set(22, forKey: "size")
            prefs.set(1, forKey: "referenceDesignRevision")
        }
        zoomMonitor = NSEvent.addLocalMonitorForEvents(matching: [.magnify, .scrollWheel]) { [weak self] event in
            guard let self = self, self.opened, event.window === self.window, self.window.attachedSheet == nil,
                  self.settings?.isShown != true, self.commentPopover?.isShown != true,
                  event.type == .magnify || event.modifierFlags.contains(.command) else { return event }
            if event.phase == .began { self.gestureDelta = 0 }
            // Wheel mice may have no began phase. Resolve the pointer on every event.
            self.editor.updatePointer(at: self.editor.convert(event.locationInWindow, from: nil))
            self.gestureDelta += event.type == .magnify ? event.magnification : -event.scrollingDeltaY / 250
            if abs(self.gestureDelta) > 0.22 {
                self.changeLevel(self.gestureDelta > 0 ? 1 : -1); self.gestureDelta = 0
            }
            return nil
        }
        pointerMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            guard let self = self,self.opened,self.window?.isKeyWindow == true else {return event}
            self.editor.updatePointer(at:self.editor.convert(self.window.mouseLocationOutsideOfEventStream,from:nil))
            return event
        }
        appUpdates.startIfConfigured()
        buildMenu()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 840),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pass Passage By!"
        window.minSize = NSSize(width: 700, height: 540)
        window.delegate = self
        window.collectionBehavior = [.fullScreenPrimary]
        window.acceptsMouseMovedEvents = true
        window.setFrameAutosaveName("PassageNative")
        window.center()
        applyAppearance()
        showHome()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)


    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationWillTerminate(_ notification: Notification) { if opened { saveDraft() } }

    // MARK: - Helpers
    func button(_ title: String, _ action: Selector, symbol: String? = nil, keyEquivalent: String = "") -> NSButton {
        let b: NSButton
        if let s = symbol, #available(macOS 11.0, *), let img = NSImage(systemSymbolName: s, accessibilityDescription: title) {
            b = NSButton(image: img, target: self, action: action)
            b.toolTip = title + (keyEquivalent.isEmpty ? "" : " (⌘\(keyEquivalent))")
        } else {
            b = NSButton(title: title, target: self, action: action)
        }
        b.bezelStyle = .rounded
        b.keyEquivalent = keyEquivalent
        return b
    }

    func stack(_ views: [NSView], vertical: Bool = false) -> NSStackView {
        let s = NSStackView(views: views)
        s.orientation = vertical ? .vertical : .horizontal
        s.spacing = 10
        s.alignment = vertical ? .leading : .centerY
        return s
    }

    func attach(_ view: NSView, to parent: NSView, inset: CGFloat = 0) {
        view.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: inset),
            view.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -inset),
            view.topAnchor.constraint(equalTo: parent.topAnchor, constant: inset),
            view.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -inset)
        ])
    }

    func base() {
        root = PaperBackdrop()
        (root as? PaperBackdrop)?.receiveFiles = { [weak self] urls in
            guard let self = self else{return}
            self.receiveDroppedFiles(urls)
        }
        window.contentView = root
        root.wantsLayer = true
        updateRootBackground()
    }

    // MARK: - Menu Bar & Shortcuts (Requirement 6)
    func buildMenu() {
        let m = NSMenu()
        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu()
        appMenu.submenu?.addItem(withTitle: "About Pass Passage By!", action: #selector(showAbout), keyEquivalent: "")
        appMenu.submenu?.addItem(withTitle: "Quick Tour / Onboarding", action: #selector(showOnboarding), keyEquivalent: "")
        appMenu.submenu?.addItem(withTitle:"Check for Updates…",action:#selector(AppUpdates.check(_:)),keyEquivalent:"").target = appUpdates
        appMenu.submenu?.addItem(.separator())
        appMenu.submenu?.addItem(withTitle: "Preferences…", action: #selector(showSettings), keyEquivalent: ",")
        appMenu.submenu?.addItem(.separator())
        appMenu.submenu?.addItem(withTitle: "Quit Pass Passage By!", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        m.addItem(appMenu)

        // File Menu
        let fileItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "New Essay", action: #selector(newEssay), keyEquivalent: "n").target = self
        fileMenu.addItem(withTitle: "New Administrative Document…", action: #selector(newAdministrativeDocument), keyEquivalent: "").target = self
        fileMenu.addItem(withTitle: "New SOP Onboarding Document…", action: #selector(newOnboardingDocument), keyEquivalent: "").target = self
        fileMenu.addItem(withTitle: "Open…", action: #selector(importFile), keyEquivalent: "o").target = self
        fileMenu.addItem(withTitle: "Save Draft", action: #selector(saveVersion), keyEquivalent: "s").target = self
        let scanItem = fileMenu.addItem(withTitle:"Scan Photo or PDF…",action:#selector(captureDocument),keyEquivalent:"C");scanItem.target = self
        fileMenu.addItem(withTitle:"Paste Scan",action:#selector(pasteScan),keyEquivalent:"").target = self
        let libItem = fileMenu.addItem(withTitle:"My Writing…",action:#selector(showWritingLibrary),keyEquivalent:"N");libItem.target = self
        let camera = NSMenuItem(title:"Import from iPhone",action:nil,keyEquivalent:"");camera.identifier = NSMenuItem.importFromDeviceIdentifier;fileMenu.addItem(camera)
        fileMenu.addItem(withTitle:"Add Task Image…",action:#selector(addImage),keyEquivalent:"").target = self
        fileMenu.addItem(withTitle:"Show Task Images",action:#selector(showImages),keyEquivalent:"").target = self
        fileItem.submenu = fileMenu
        m.addItem(fileItem)

        // Edit Menu
        let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: #selector(undoEdit), keyEquivalent: "z").target = self
        editMenu.addItem(withTitle: "Redo", action: #selector(redoEdit), keyEquivalent: "Z").target = self
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(.separator())
        let noteItem = editMenu.addItem(withTitle:"Comment on Selection…",action:#selector(comment),keyEquivalent:"m");noteItem.target = self;noteItem.keyEquivalentModifierMask = [.option,.command]
        editMenu.addItem(withTitle: "Bold", action: #selector(bold), keyEquivalent: "b").target = self
        editMenu.addItem(withTitle: "Italic", action: #selector(italic), keyEquivalent: "i").target = self
        editMenu.addItem(withTitle: "Underline", action: #selector(underline), keyEquivalent: "u").target = self
        editMenu.addItem(withTitle: "Toggle Highlight", action: #selector(highlight), keyEquivalent: "").target = self
        editMenu.addItem(withTitle: "Link", action: #selector(insertLink), keyEquivalent: "k").target = self
        editMenu.addItem(withTitle:"Heading",action:#selector(insertHeading),keyEquivalent:"\\").target = self
        editMenu.addItem(withTitle:"Clear Markup",action:#selector(clearMarkup),keyEquivalent:"l").target = self
        editMenu.addItem(withTitle:"Markup…",action:#selector(showMarkup),keyEquivalent:"9").target = self
        editMenu.addItem(withTitle:"Annotation {…}",action:#selector(insertAnnotation),keyEquivalent:"").target = self
        for (title,tag,key) in [("Find…",1,"f"),("Find Next",2,"g"),("Find Previous",3,"G")] {
            let item = editMenu.addItem(withTitle:title,action:#selector(NSTextView.performFindPanelAction(_:)),keyEquivalent:key);item.tag = tag
        }
        editItem.submenu = editMenu
        m.addItem(editItem)

        // View Menu (Zoom levels with Cmd+1..4)
        let viewItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Zoom: Essay Level", action: #selector(zoomEssay), keyEquivalent: "").target = self
        viewMenu.addItem(withTitle: "Zoom: Paragraph Level", action: #selector(zoomParagraph), keyEquivalent: "").target = self
        viewMenu.addItem(withTitle: "Zoom: Sentence Level", action: #selector(zoomSentence), keyEquivalent: "").target = self
        viewMenu.addItem(withTitle: "Zoom: Word Level", action: #selector(zoomWord), keyEquivalent: "").target = self
        viewMenu.addItem(.separator())
        viewMenu.addItem(withTitle: "Increase Text Size", action: #selector(fontLarger), keyEquivalent: "=").target = self
        viewMenu.addItem(withTitle: "Decrease Text Size", action: #selector(fontSmaller), keyEquivalent: "-").target = self
        viewMenu.addItem(.separator())
        let fullscreen = viewMenu.addItem(withTitle:"Toggle Full Screen",action:#selector(toggleFullScreen),keyEquivalent:"f");fullscreen.target = self;fullscreen.keyEquivalentModifierMask = [.control,.command]
        viewMenu.addItem(withTitle:"Reset Text Size",action:#selector(fontReset),keyEquivalent:"0").target = self
        viewMenu.addItem(withTitle:"Hide Interface / Present",action:#selector(togglePresentation),keyEquivalent:".").target = self
        viewMenu.addItem(withTitle:"Focus Editor",action:#selector(focusEditor),keyEquivalent:"3").target = self
        viewMenu.addItem(withTitle:"Pin / Unpin Current Writing on Home",action:#selector(toggleShowcasePin),keyEquivalent:"").target = self
        viewMenu.addItem(withTitle:"Margin Annotations",action:#selector(toggleNotes),keyEquivalent:"4").target = self
        viewMenu.addItem(withTitle:"Quick Export…",action:#selector(exportFile),keyEquivalent:"6").target = self
        for (title,action,key) in [("Semantic Zoom In",#selector(zoomIn),"="),("Semantic Zoom Out",#selector(zoomOut),"-"),("Dark Theme",#selector(toggleDark),"l")] {
            let item = viewMenu.addItem(withTitle:title,action:action,keyEquivalent:key);item.target = self;item.keyEquivalentModifierMask = [.option,.command]
        }
        let pointer = viewMenu.addItem(withTitle:"Toggle Pointer Highlight",action:#selector(togglePointerHighlight),keyEquivalent:"h")
        pointer.target = self;pointer.keyEquivalentModifierMask = [.option]
        viewItem.submenu = viewMenu
        m.addItem(viewItem)

        NSApp.mainMenu = m
    }

    // MARK: - Home View
    @objc func exportAgentKit(){
        let panel = NSOpenPanel();panel.canChooseDirectories = true;panel.canChooseFiles = false;panel.prompt = "Save skill kit here"
        panel.begin {response in guard response == .OK,let folder = panel.url,let source = Bundle.main.resourceURL?.appendingPathComponent("AgentKit") else{return}
            do {let target = folder.appendingPathComponent("pass-passage-by-skill-" + String(UUID().uuidString.prefix(6)));try FileManager.default.copyItem(at:source,to:target)}catch{self.showAlert(error.localizedDescription)}
        }
    }
    @objc func addSkill(){
        let panel = NSOpenPanel();panel.allowedContentTypes = [.plainText,UTType(filenameExtension:"md") ?? .text]
        panel.begin {response in guard response == .OK,let url = panel.url else{return}
            do {let bytes = try Data(contentsOf:url);guard bytes.count < 1_000_000,String(data:bytes,encoding:.utf8) != nil else{throw ModelError.invalid}
                let folder = self.saveURL.deletingLastPathComponent().appendingPathComponent("Skills");try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true);let target = folder.appendingPathComponent(UUID().uuidString + "-" + url.deletingPathExtension().lastPathComponent + ".md");try bytes.write(to:target,options:.atomic)
                self.reloadAgentSkills();if let item = self.agentSkills?.itemArray.first(where:{$0.representedObject as? URL == target}) {self.agentSkills?.select(item)};self.agentStatus?.stringValue = "Skill added. Select it before copying your brief."
            }catch{self.showAlert(error.localizedDescription)}
        }
    }
    func application(_ sender:NSApplication,openFiles filenames:[String]) {
        for filename in filenames {let url = URL(fileURLWithPath:filename);if url.pathExtension.lowercased() == "json" {do {if opened {saveDraft()};try loadJSON(Data(contentsOf:url));openWorkspace()}catch{showAlert(error.localizedDescription)}}}
        sender.reply(toOpenOrPrint:.success)
    }
    @objc func showExampleLibrary(){
        let panel = NSWindow(contentRect:NSRect(x:0,y:0,width:620,height:620),styleMask:[.titled,.closable,.resizable],backing:.buffered,defer:false)
        panel.title = "Practice library · Task 1 & Task 2";panel.isReleasedWhenClosed = false
        let list = MarginCanvas(frame:NSRect(x:0,y:0,width:580,height:980))
        let notice = NSTextField(wrappingLabelWithString:"20 practice documents · 10 Task 1 charts and 10 Task 2 essays. Original learning materials with teaching notes.")
        notice.frame = NSRect(x:20,y:15,width:540,height:50);list.addSubview(notice)
        let urls = (try? FileManager.default.contentsOfDirectory(at:(Bundle.main.resourceURL ?? Bundle.main.bundleURL).appendingPathComponent("Samples"),includingPropertiesForKeys:nil))?.sorted{$0.lastPathComponent < $1.lastPathComponent} ?? []
        for (index,url) in urls.enumerated(){
            guard let bytes = try? Data(contentsOf:url),let sample = try? JSONDecoder().decode(Breakdown.self,from:bytes) else{continue}
            let item = button(sample.document.title,#selector(loadExample(_:)));item.identifier = .init(url.path);item.frame = NSRect(x:20,y:70 + index * 44,width:540,height:34);list.addSubview(item)
        }
        let scroll = NSScrollView();scroll.hasVerticalScroller = true;scroll.documentView = list;panel.contentView = scroll;infoWindow = panel;panel.center();panel.makeKeyAndOrderFront(nil)
    }
    @objc func loadExample(_ sender:NSButton){
        guard let path = sender.identifier?.rawValue else{return}
        do{if opened {saveDraft()};try loadJSON(Data(contentsOf:URL(fileURLWithPath:path)));infoWindow?.close();openWorkspace()}catch{showAlert(error.localizedDescription)}
    }
    @objc func openExample() {
        do {
            guard let url = Bundle.main.url(forResource: "example.breakdown", withExtension: "json") else {return}
            try loadJSON(Data(contentsOf: url))
            openWorkspace()
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    @objc func showNewDocumentMenu(_ sender: Any?) {
        guard let view = sender as? NSView else {
            newEssay()
            return
        }
        let menu = NSMenu(title: "New Document")

        let adminItem = NSMenuItem(title: "Văn bản hành chính (NĐ 30)", action: #selector(newAdministrativeDocument), keyEquivalent: "")
        adminItem.target = self
        adminItem.image = NSImage(systemSymbolName: "building.columns", accessibilityDescription: "Administrative")
        menu.addItem(adminItem)

        let onboardingItem = NSMenuItem(title: "Quy chế & SOP Onboarding", action: #selector(newOnboardingDocument), keyEquivalent: "")
        onboardingItem.target = self
        onboardingItem.image = NSImage(systemSymbolName: "person.badge.shield.checkmark", accessibilityDescription: "Onboarding")
        menu.addItem(onboardingItem)

        menu.addItem(NSMenuItem.separator())

        let ieltsItem = NSMenuItem(title: "IELTS Essay", action: #selector(newIELTSEssay), keyEquivalent: "")
        ieltsItem.target = self
        ieltsItem.image = NSImage(systemSymbolName: "graduationcap", accessibilityDescription: "IELTS")
        menu.addItem(ieltsItem)

        let researchItem = NSMenuItem(title: "Research Document", action: #selector(newResearchPaper), keyEquivalent: "")
        researchItem.target = self
        researchItem.image = NSImage(systemSymbolName: "atom", accessibilityDescription: "Research")
        menu.addItem(researchItem)

        let discursiveItem = NSMenuItem(title: "Discursive Essay", action: #selector(newDiscursiveEssay), keyEquivalent: "")
        discursiveItem.target = self
        discursiveItem.image = NSImage(systemSymbolName: "text.quote", accessibilityDescription: "Essay")
        menu.addItem(discursiveItem)

        menu.addItem(NSMenuItem.separator())

        let blankItem = NSMenuItem(title: "Blank Writing Canvas", action: #selector(newEssay), keyEquivalent: "n")
        blankItem.target = self
        blankItem.image = NSImage(systemSymbolName: "doc", accessibilityDescription: "Blank")
        menu.addItem(blankItem)

        let point = NSPoint(x: view.bounds.maxX + 4, y: view.bounds.minY)
        menu.popUp(positioning: nil, at: point, in: view)
    }

    private func createBlankDocument(title:String, type:String) {
        if opened {saveDraft()}; writingLibrary?.close()
        data = .plain("", title:title)
        data.document.taskType = type
        past = [];future = []
        openWorkspace()
    }
    private func loadTemplateOrBlank(filename: String, fallbackTitle: String, type: String) {
        if opened { saveDraft() }; writingLibrary?.close()
        let kitURL = Bundle.main.resourceURL?.appendingPathComponent("AgentKit/" + filename) ?? URL(fileURLWithPath: "AgentKit/" + filename)
        if let dataBytes = try? Data(contentsOf: kitURL),
           let sample = try? JSONDecoder().decode(Breakdown.self, from: dataBytes) {
            data = sample
            data.document.id = "\(type)-" + UUID().uuidString.prefix(8).lowercased()
        } else {
            createBlankDocument(title: fallbackTitle, type: type)
        }
        past = []; future = []
        openWorkspace()
    }
    @objc func newAdministrativeDocument() {
        loadTemplateOrBlank(filename: "administrative_sample.json", fallbackTitle: "Quyết định hành chính mới", type: "administrative")
    }
    @objc func newOnboardingDocument() {
        loadTemplateOrBlank(filename: "onboarding_sample.json", fallbackTitle: "Quy chế & SOP Onboarding", type: "onboarding")
    }
    @objc func newIELTSEssay() {createBlankDocument(title:"Untitled IELTS Essay",type:"task2")}
    @objc func newResearchPaper() {createBlankDocument(title:"Untitled Research",type:"research")}
    @objc func newDiscursiveEssay() {createBlankDocument(title:"Untitled Essay",type:"discursive")}

    @objc func newEssay() {
        if opened {saveDraft()};writingLibrary?.close()
        data = .plain("", title: "Untitled Essay")
        past = []
        future = []
        openWorkspace()
    }

    @objc func resumeDraft() {
        do {
            try loadJSON(Data(contentsOf: saveURL))
            openWorkspace()
        } catch {
            openExample()
        }
    }

    func loadJSON(_ bytes: Data) throws {
        guard bytes.count <= 100_000_000 else { throw ModelError.invalid }
        let d = try JSONDecoder().decode(Breakdown.self, from: bytes)
        try d.validate()
        data = d
        past = []
        future = []
        focus = 0
        level = 0
    }

    // MARK: - Workspace Layout (Requirements 1, 3, 4)
    func openWorkspace() {
        opened = true
        level = 0
        focus = 0
        base()

        // 1. Unified Clean Top Bar (Requirement 4)
        titleField = NSTextField(string: data.document.title)
        titleField.placeholderString = "Essay title"
        titleField.isBordered = false
        titleField.drawsBackground = false
        titleField.font = .systemFont(ofSize: 16, weight: .semibold)
        titleField.target = self
        titleField.action = #selector(renameTitle)

        let homeBtn = button("Home", #selector(showHome), symbol: "house")
        let importBtn = button("Import", #selector(importFile), symbol: "square.and.arrow.down")
        let exportBtn = button("Share", #selector(showSharePreview), symbol: "square.and.arrow.up")

        levels = NSSegmentedControl(labels: ["Essay", "Paragraph", "Sentence", "Word"], trackingMode: .selectOne, target: self, action: #selector(levelChanged))
        levels.selectedSegment = 0

        // Apple-style clean formatting capsule (Requirement 2 & 4)
        let topLeading = stack([homeBtn, titleField])
        topLeading.spacing = 10
        let briefEdit = button("Add task",#selector(editTaskBrief));briefEditButton = briefEdit
        let briefToggle = button("Task Prompt", #selector(toggleTaskBrief), symbol: briefHidden ? "chevron.down" : "chevron.up")
        briefToggleButton = briefToggle
        let scanBtn = button("Scan",#selector(captureDocument),symbol:"camera")
        let noteBtn = button("Comments",#selector(toggleComments),symbol:"bubble.left.and.bubble.right")
        let notesBtn = button("Library",#selector(showWritingLibrary),symbol:"folder")
        let moreBtn = button("More actions", #selector(editorActions(_:)), symbol: "ellipsis")
        let topTrailing = stack([briefEdit, noteBtn, button("Attachments", #selector(attachmentMenu(_:)), symbol: "paperclip"), exportBtn, moreBtn])
        _ = [scanBtn, notesBtn, importBtn]
        for control in topTrailing.arrangedSubviews.compactMap({ $0 as? NSButton }) + [homeBtn, briefToggle] {
            control.isBordered = false
            control.contentTintColor = .secondaryLabelColor
            control.heightAnchor.constraint(equalToConstant: 30).isActive = true
        }
        let taskControl = NSView()
        taskControl.heightAnchor.constraint(equalToConstant: 32).isActive = true
        briefToggle.translatesAutoresizingMaskIntoConstraints = false
        taskControl.addSubview(briefToggle)
        NSLayoutConstraint.activate([
            briefToggle.centerXAnchor.constraint(equalTo: taskControl.centerXAnchor),
            briefToggle.centerYAnchor.constraint(equalTo: taskControl.centerYAnchor),
            briefToggle.widthAnchor.constraint(equalToConstant: 48),
            briefToggle.heightAnchor.constraint(equalToConstant: 30)
        ])
        taskToggleRow = taskControl
        topTrailing.spacing = 10

        let top = NSStackView(views: [topLeading, topTrailing])
        top.orientation = .horizontal
        top.distribution = .equalSpacing
        top.alignment = .centerY
        topBar = top

        // Header level badge
        header = NSTextField(labelWithString: "ESSAY LEVEL")
        header.font = .systemFont(ofSize: 11, weight: .medium); header.alignment = .center
        header.textColor = .secondaryLabelColor

        // 2. Editor & Sidebars (Requirement 3: Left & Right Notes)
        editor = WritingView(frame: NSRect(x: 0, y: 0, width: 680, height: 600))
        editor.registerForDraggedTypes([.fileURL]);editor.receiveFiles = { [weak self] urls in self?.receiveDroppedFiles(urls) };editor.receiveScan = { [weak self] board in self?.scanPasteboard(board) ?? false }
        editor.delegate = self
        editor.isRichText = false
        editor.usesFindBar = true
        editor.allowsUndo = false
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.isAutomaticDashSubstitutionEnabled = false
        editor.isVerticallyResizable = true
        editor.isHorizontallyResizable = false
        editor.autoresizingMask = [.width]
        editor.textContainer?.widthTracksTextView = true
        editor.textContainerInset = NSSize(width: 28, height: 64)

        editor.pointerMode = { [weak self] in self?.prefs.string(forKey:"pointerMode") ?? "Hold Option" }
        editor.hoverRange = { [weak self] index in
            guard let self = self else { return NSRange(location: 0, length: 0) }
            let r = self.data.range(level: 2, offset: self.visible.location + index)
            let overlap = NSIntersectionRange(r, self.visible)
            return NSRange(location: max(0, overlap.location - self.visible.location), length: overlap.length)
        }
        editor.zoom = { [weak self] dir in self?.changeLevel(dir) }
        editor.editAnnotation = { [weak self] index, point in
            guard let self = self, let note = self.displayedNotes.first(where:{NSLocationInRange(self.visible.location + index,NSRange(location:$0.start,length:$0.end - $0.start))}) else{return false}
            self.openCommentPopover(existing:note,targetRect:NSRect(origin:point,size:NSSize(width:1,height:20)),view:self.editor);return true
        }
        editor.onHoverIndex = { [weak self] index, point in
            self?.handleTextHover(index: index, point: point)
        }
        editor.point = { [weak self] pos in guard let self = self else { return }; self.focus = self.visible.location + pos }

        scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.documentView = editor
        scroll.drawsBackground = false

        // Left Margin Notes
        leftNotes = MarginCanvas()
        leftScroll = NSScrollView()
        leftScroll.hasVerticalScroller = true
        leftScroll.documentView = leftNotes
        leftScroll.drawsBackground = false
        leftNotes.autoresizingMask = [.width, .height]

        // Right Margin Notes
        rightNotes = MarginCanvas()
        rightScroll = NSScrollView()
        rightScroll.hasVerticalScroller = true
        rightScroll.documentView = rightNotes
        rightScroll.drawsBackground = false
        rightNotes.autoresizingMask = [.width, .height]

        // Dictionary Pane (Word level - Apple Dictionary HIG layout)
        definition = NSTextView(frame: NSRect(x: 0, y: 0, width: 340, height: 600))
        definition.isEditable = false
        definition.isSelectable = true
        definition.font = .systemFont(ofSize: 15)
        definition.textContainerInset = NSSize(width: 20, height: 18)
        definition.autoresizingMask = [.width]
        definition.isVerticallyResizable = true
        definition.textContainer?.widthTracksTextView = true
        definition.drawsBackground = false

        dictionaryScroll = NSScrollView()
        dictionaryScroll.hasVerticalScroller = true
        dictionaryScroll.documentView = definition
        dictionaryScroll.drawsBackground = false

        dictWordListView = MarginCanvas(frame: NSRect(x: 0, y: 0, width: 170, height: 400))
        dictWordListScroll = NSScrollView()
        dictWordListScroll.hasVerticalScroller = true
        dictWordListScroll.drawsBackground = false
        dictWordListScroll.documentView = dictWordListView

        dictToolbar = AppleDictionaryToolbar()
        dictToolbar.backButton.target = self
        dictToolbar.backButton.action = #selector(dictNavBackAction)
        dictToolbar.forwardButton.target = self
        dictToolbar.forwardButton.action = #selector(dictNavForwardAction)
        dictToolbar.onSelectTab = { [weak self] tab in
            self?.selectedDictTab = tab
            if let word = self?.currentWord, !word.isEmpty {
                self?.lookupWord(word, addToHistory: false)
            }
        }

        dictionaryPane = AppleDictionaryPaneView()
        dictionaryPane.toolbar = dictToolbar
        dictionaryPane.definitionScroll = dictionaryScroll
        dictionaryPane.addSubview(dictToolbar)
        dictionaryPane.addSubview(dictionaryScroll)
        dictionaryPane.isHidden = true

        definitionButton = button("Show full dictionary entry", #selector(toggleDefinition))
        definitionButton.isHidden = true

        // Editor Container with Connector Overlay View (Requirement 3)
        editorContainer = NSView()
        editorContainer.translatesAutoresizingMaskIntoConstraints = false
        attach(scroll, to: editorContainer)

        connectorView = ConnectorOverlayView()
        connectorView.wantsLayer = true;connectorView.layer?.masksToBounds = true
        connectorView.geometryChanged = { [weak self] in self?.scheduleAnnotationLayout() }
        connectorView.translatesAutoresizingMaskIntoConstraints = false
        editorContainer.addSubview(connectorView)
        NSLayoutConstraint.activate([
            connectorView.leadingAnchor.constraint(equalTo: editorContainer.leadingAnchor),
            connectorView.trailingAnchor.constraint(equalTo: editorContainer.trailingAnchor),
            connectorView.topAnchor.constraint(equalTo: editorContainer.topAnchor),
            connectorView.bottomAnchor.constraint(equalTo: editorContainer.bottomAnchor)
        ])

        // Main Center Stack
        commentsPane = InspectorSurface()
        commentsEditing = false
        commentsVisible = false
        commentsWidth = commentsPane.widthAnchor.constraint(equalToConstant: 300)
        let center = stack([leftScroll, editorContainer, rightScroll, dictionaryPane, commentsPane])
        centerStack = center
        center.spacing = 0
        center.distribution = .fill
        center.alignment = .top

        leftWidth = leftScroll.widthAnchor.constraint(equalToConstant: 240)
        rightWidth = rightScroll.widthAnchor.constraint(equalToConstant: 240)
        dictWidth = dictionaryPane.widthAnchor.constraint(equalToConstant: 340)
        wordHeight = editorContainer.heightAnchor.constraint(equalToConstant: 140)

        paneHeightConstraints = [commentsPane.heightAnchor.constraint(equalTo: center.heightAnchor), editorContainer.heightAnchor.constraint(equalTo: center.heightAnchor), leftScroll.heightAnchor.constraint(equalTo: center.heightAnchor), rightScroll.heightAnchor.constraint(equalTo: center.heightAnchor), dictionaryPane.heightAnchor.constraint(equalTo: center.heightAnchor)]
        NSLayoutConstraint.activate(paneHeightConstraints)

        exitPresentation = button("End presentation", #selector(togglePresentation))
        exitPresentation.isHidden = true
        taskBrief = ClipScrollView();taskBrief.hasVerticalScroller = true;taskBrief.drawsBackground = false
        taskBriefHeight = taskBrief.heightAnchor.constraint(equalToConstant:220);taskBriefHeight?.isActive = true
        refreshTaskBrief()
        let all = stack([top, taskBrief, taskControl, header, center, definitionButton, exitPresentation], vertical: true)
        all.alignment = .width; all.spacing = 6
        attach(all, to: root, inset: 24)
        header.widthAnchor.constraint(equalTo: all.widthAnchor).isActive = true
        if let token = scrollObserver { NotificationCenter.default.removeObserver(token) }
        scroll.contentView.postsBoundsChangedNotifications = true
        scrollObserver = NotificationCenter.default.addObserver(forName:NSView.boundsDidChangeNotification,object:scroll.contentView,queue:.main){[weak self] _ in self?.updateConnectors()}

        render()
        adaptLayout()
        saveDraft()
        if data.document.text.isEmpty { window.makeFirstResponder(editor) }
    }

    @objc func editorActions(_ sender: NSButton) {
        let menu = NSMenu(title: "Document")
        for (title, action) in [("Scan text…", #selector(captureDocument)), ("Import…", #selector(importFile)), ("Writing library", #selector(showWritingLibrary)), ("Presentation mode", #selector(togglePresentation)), ("Settings…", #selector(showSettings))] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.maxY), in: sender)
    }

    // MARK: - Navigation & Zoom
    @objc func renameTitle() { data.document.title = titleField.stringValue; saveDraft() }
    func selectedRangeInDocument() -> NSRange {
        let r = editor.selectedRange()
        return NSRange(location: visible.location + r.location, length: r.length)
    }

    func snapshot() {
        past.append(data)
        if past.count > 100 { past.removeFirst() }
        future = []
    }

    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        guard textView === editor, !updating, let replacement = replacementString else { return true }
        if commentsEditing { closeComment() }
        snapshot()
        let range = NSRange(location: visible.location + affectedCharRange.location, length: affectedCharRange.length)
        data.replace(range, with: replacement)
        visible.length += (replacement as NSString).length - affectedCharRange.length
        focus = range.location + (replacement as NSString).length
        return true
    }

    func textDidChange(_ notification: Notification) {
        if notification.object as? NSTextView === commentField { persistComment();return }
        guard !updating else { return }
        textRefresh?.cancel()
        let job = DispatchWorkItem { [weak self] in
            guard let self = self else{return}
            let origin = self.scroll.contentView.bounds.origin
            self.saveDraft();self.styleText();self.renderNotes()
            self.scroll.contentView.scroll(to:origin);self.scroll.reflectScrolledClipView(self.scroll.contentView)
            if self.level == 3 {self.lookupDictionary()}
        }
        textRefresh = job;DispatchQueue.main.asyncAfter(deadline:.now() + 0.12,execute:job)
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        if notification.object as? NSTextView === editor, !updating {
            focus = selectedRangeInDocument().location
            updateSelectionAction()
        }
    }

    @objc func undoEdit() { guard opened, let prev = past.popLast() else { return }; future.append(data); data = prev; render(); saveDraft() }
    @objc func redoEdit() { guard opened, let next = future.popLast() else { return }; past.append(data); data = next; render(); saveDraft() }

    @objc func zoomIn() { changeLevel(1) }
    @objc func zoomOut() { changeLevel(-1) }
    @objc func zoomEssay() { setLevel(0) }
    @objc func zoomParagraph() { setLevel(1) }
    @objc func zoomSentence() { setLevel(2) }
    @objc func zoomWord() { setLevel(3) }
    @objc func levelChanged() { setLevel(levels.selectedSegment) }

    func setLevel(_ target: Int) {
        guard opened, target != level, target >= 0, target <= 3 else { return }
        if target > level { adoptPointerTarget() }
        level = target
        render(animated: true)
    }

    func adoptPointerTarget() {
        if let index = editor.pointerIndex {
            focus = min(max(visible.location, visible.location + index), max(visible.location, NSMaxRange(visible) - 1))
        }
    }

    func zoomPathDescription() -> String {
        let names = ["Essay","Paragraph","Sentence","Word"]
        return PassageMarkup.route(prefs.string(forKey:"zoomPreset") ?? "Teacher",paragraph:prefs.bool(forKey:"zoomParagraph"),sentence:prefs.bool(forKey:"zoomSentence")).map {names[$0]}.joined(separator:" → ")
    }
    func nextZoomLevel(_ direction: Int) -> Int {
        let route = PassageMarkup.route(prefs.string(forKey: "zoomPreset") ?? "Teacher", paragraph: prefs.bool(forKey: "zoomParagraph"), sentence: prefs.bool(forKey: "zoomSentence"))
        return direction > 0 ? (route.first { $0 > level } ?? level) : (route.last { $0 < level } ?? level)
    }
    var displayedNotes: [Note] { PassageMarkup.orderedNotes(data.document.text,existing:data.annotations) }

    func changeLevel(_ direction: Int) {
        guard opened else { return }
        if Date().timeIntervalSince(lastZoom) < 0.35 { return }
        let next = nextZoomLevel(direction)
        guard next != level else { return }
        lastZoom = Date()
        if next > level { adoptPointerTarget() }
        level = next
        render(animated: true)
    }

    // MARK: - Rendering
    func render(animated: Bool = false) {
        guard opened else { return }
        updating = true
        editor.clearPointer()
        visible = data.range(level: level, offset: focus)
        editor.string = (data.document.text as NSString).substring(with: visible)
        editor.setSelectedRange(NSRange(location: min(max(0, focus - visible.location), visible.length), length: 0))
        updating = false

        levels.selectedSegment = level
        header.stringValue = ["•  E S S A Y", "•  P A R A G R A P H", "•  S E N T E N C E", "•  W O R D"][level]
        titleField.stringValue = data.document.title

        adaptLayout()
        styleText()
        renderNotes()

        let isWord = (level == 3)
        dictionaryPane.isHidden = !isWord
        definitionButton.isHidden = !isWord
        leftScroll.isHidden = isWord || !prefs.bool(forKey: "notes")
        rightScroll.isHidden = isWord || !prefs.bool(forKey: "notes")

        if isWord {
            lookupDictionary()
        } else {
            lookupWork?.cancel()
        }

        adaptLayout()
        editor.scrollRangeToVisible(editor.selectedRange())
        if focus == visible.location { scroll.contentView.scroll(to: .zero); scroll.reflectScrolledClipView(scroll.contentView) }

        if animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            editor.wantsLayer = true
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0.3
            fade.toValue = 1.0
            fade.duration = BrandMotion.textSwap
            editor.layer?.add(fade, forKey: "focus")

            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 0.98
            scale.toValue = 1.0
            scale.duration = BrandMotion.page
            scale.timingFunction = CAMediaTimingFunction(controlPoints:0.22,1,0.36,1)
            editor.layer?.add(scale, forKey: "zoom")
        }
    }

    // MARK: - Typography & Comic Theme (Requirement 5)
    func isComicTheme() -> Bool {
        false
    }

    func currentBodyFont(size: CGFloat) -> NSFont {
        if isComicTheme() {
            return NSFont(name: "Chalkboard SE", size: size) ?? NSFont(name: "Comic Sans MS", size: size) ?? .systemFont(ofSize: size)
        }
        let name = prefs.string(forKey: "font") ?? "Georgia"
        return NSFont(name: name, size: size) ?? .systemFont(ofSize: size)
    }

    func currentHeadlineFont(size: CGFloat) -> NSFont {
        if isComicTheme() {
            return NSFont(name: "ChalkboardSE-Bold", size: size) ?? NSFont(name: "Comic Sans MS Bold", size: size) ?? .systemFont(ofSize: size, weight: .bold)
        }
        return .systemFont(ofSize: size, weight: .semibold)
    }

    func isDarkMode() -> Bool {
        if let theme = prefs.string(forKey: "theme"), theme == "Midnight" { return true }
        if prefs.object(forKey: "dark") != nil { return prefs.bool(forKey: "dark") }
        return LiquidGlass.isDark(for: root ?? NSView())
    }

    func paperColor() -> NSColor {
        if isDarkMode() {
            return WorkspaceStyle.background(dark: true)
        }
        switch prefs.string(forKey: "theme") ?? "Paper" {
        case "Comic":
            return NSColor(calibratedRed: 1.0, green: 0.985, blue: 0.92, alpha: 1) // Warm pastel comic paper
        case "Sepia":
            return NSColor(calibratedRed: 0.98, green: 0.95, blue: 0.88, alpha: 1)
        case "Forest":
            return NSColor(calibratedRed: 0.92, green: 0.96, blue: 0.93, alpha: 1)
        case "Midnight":
            return WorkspaceStyle.background(dark: true)
        default:
            return prefs.string(forKey: "canvas") == "Warm paper" ? NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.91, alpha: 1) : WorkspaceStyle.background(dark: false)
        }
    }

    func updateRootBackground() {
        guard let r = root else { return }
        r.wantsLayer = true
        r.layer?.backgroundColor = paperColor().cgColor
        r.needsDisplay = true
    }

    func styleText() {
        guard opened else { return }
        let r = NSRange(location: 0, length: (editor.string as NSString).length)
        let baseSize = prefs.double(forKey: "size")
        let levelMultiplier = [1.12, 1.5, 2.1, 3.4][level] * (presentation ? 1.15 : 1)
        let font = currentBodyFont(size: baseSize * levelMultiplier)

        let para = NSMutableParagraphStyle()
        para.lineSpacing = baseSize * (prefs.double(forKey: "spacing") - 1)
        para.paragraphSpacing = prefs.double(forKey: "paragraphSpacing")
        para.firstLineHeadIndent = prefs.double(forKey: "indent")

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: para
        ]
        editor.textStorage?.beginEditing()
        editor.textStorage?.setAttributes(attrs, range: r)
        editor.typingAttributes = attrs

        let bg = paperColor()
        editor.drawsBackground = false; editor.backgroundColor = bg
        scroll.backgroundColor = bg
        definition.backgroundColor = .clear
        dictionaryScroll.backgroundColor = .clear
        dictionaryPane.needsDisplay = true
        updateRootBackground()

        for span in PassageMarkup.spans(editor.string) {
            var mark: [NSAttributedString.Key: Any] = [:]
            switch span.kind {
            case "heading": mark[.font] = NSFontManager.shared.convert(currentBodyFont(size: baseSize * levelMultiplier * 1.45), toHaveTrait: .boldFontMask)
            case "strong": mark[.font] = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
            case "emphasis": mark[.font] = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
            case "code": mark[.font] = NSFont.monospacedSystemFont(ofSize: baseSize * levelMultiplier * 0.85, weight: .regular)
            case "redact": mark[.strikethroughStyle] = NSUnderlineStyle.single.rawValue; mark[.foregroundColor] = NSColor.secondaryLabelColor
            case "highlight": mark[.backgroundColor] = NSColor.systemYellow.withAlphaComponent(0.2)
            case "comment": mark[.foregroundColor] = NSColor.secondaryLabelColor
            case "annotation": break
            case "link": mark[.foregroundColor] = NSColor.systemBlue
            case "quote", "divider": mark[.foregroundColor] = NSColor.secondaryLabelColor
            default: break
            }
            editor.textStorage?.addAttributes(mark, range: span.range)
        }
        // Apply styled annotations
        for note in displayedNotes {
            let overlap = NSIntersectionRange(visible, NSRange(location: note.start, length: note.end - note.start))
            guard overlap.length > 0 else { continue }
            let local = NSRange(location: overlap.location - visible.location, length: overlap.length)
            var mark: [NSAttributedString.Key: Any] = [:]
            switch note.kind {
            case "bold":
                mark[.font] = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
            case "italic":
                mark[.font] = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
            case "underline":
                mark[.underlineStyle] = NSUnderlineStyle.single.rawValue
            case "highlight":
                // Apple-style soft pastel highlight (Requirement 2)
                // Persistent annotation uses underline; hover owns background color.
                mark[.underlineStyle] = NSUnderlineStyle.single.rawValue
                mark[.underlineColor] = NSColor.systemOrange
            default:
                mark[.underlineStyle] = NSUnderlineStyle.single.rawValue
                mark[.underlineColor] = noteColor(note)

            }
            editor.textStorage?.addAttributes(mark, range: local)
        }
        editor.textStorage?.endEditing()
        updateConnectors()
    }

    // MARK: - Two-sided Margin Notes & Connector Lines (Requirement 3)
    func renderNotes() {
        for v in leftNotes.arrangedSubviews { leftNotes.removeArrangedSubview(v); v.removeFromSuperview() }
        for v in rightNotes.arrangedSubviews { rightNotes.removeArrangedSubview(v); v.removeFromSuperview() }

        renderComments()
        let visibleList = displayedNotes.filter {
            !isDiscussion($0) && !$0.body.isEmpty && $0.start < NSMaxRange(visible) && $0.end > visible.location
        }

        for n in visibleList.sorted(by: { $0.start < $1.start }) {
            let isLeft = (n.side == "left") && !leftScroll.isHidden
            let targetStack = isLeft ? leftNotes : rightNotes
            let titleText = n.label
            let titleBtn = button(titleText, #selector(noteClicked))
            titleBtn.identifier = NSUserInterfaceItemIdentifier(n.id)
            titleBtn.isBordered = false
            titleBtn.alignment = .left
            titleBtn.font = .systemFont(ofSize: presentation ? 18 : 15, weight: .semibold)
            titleBtn.contentTintColor = noteColor(n)
            titleBtn.cell?.wraps = true
            titleBtn.cell?.lineBreakMode = .byWordWrapping

            let kindText = n.tag.map { tagName($0) } ?? "Annotation"

            let isDark = isDarkMode()
            let kind = NSTextField(wrappingLabelWithString: kindText)
            kind.maximumNumberOfLines = 2
            kind.font = .systemFont(ofSize: 9, weight: .bold)
            kind.textColor = noteColor(n)

            let body = NSTextField(wrappingLabelWithString: n.body + (n.suggestion.map { "\n\nSuggested: " + $0 } ?? ""))
            body.font = .systemFont(ofSize: presentation ? 15 : 13)
            body.textColor = isDark ? NSColor(calibratedWhite: 0.88, alpha: 1) : NSColor(calibratedWhite: 0.2, alpha: 1)
            body.maximumNumberOfLines = 2
            body.lineBreakMode = .byWordWrapping
            body.cell?.wraps = true
            body.cell?.usesSingleLineMode = false

            let previewBtn = NSButton(title: "Read note ↗", target: self, action: #selector(openNotePreview(_:)))
            previewBtn.isHidden = true
            previewBtn.identifier = NSUserInterfaceItemIdentifier(n.id)
            previewBtn.isBordered = false
            previewBtn.bezelStyle = .regularSquare
            previewBtn.font = .systemFont(ofSize: 11, weight: .semibold)
            previewBtn.contentTintColor = noteColor(n)

            let card = MarginNoteCard(content: [kind, titleBtn, body, previewBtn], identifier: n.id)
            card.activate = { [weak self, weak titleBtn] in
                guard let titleBtn = titleBtn else { return }
                self?.noteClicked(titleBtn)
            }
            targetStack.addArrangedSubview(card)

        }
        DispatchQueue.main.async { [weak self] in
            self?.updateConnectors()
        }
    }

    func scheduleAnnotationLayout(){
        guard opened else{return}
        connectorView.connections = []
        layoutRefresh?.cancel()
        let job = DispatchWorkItem { [weak self] in
            guard let self = self,self.opened else{return}
            self.root.layoutSubtreeIfNeeded()
            if let container = self.editor.textContainer {self.editor.layoutManager?.ensureLayout(for:container)}
            self.updateConnectors()
        }
        layoutRefresh = job;DispatchQueue.main.async(execute:job)
    }
    func updateConnectors() {
        guard !briefAnimating else { return }
        guard opened, level < 3, prefs.bool(forKey: "notes") else {
            connectorView.connections = []
            return
        }

        for (canvas, pane) in [(leftNotes, leftScroll), (rightNotes, rightScroll)] {
            canvas.setFrameSize(NSSize(width: pane.contentView.bounds.width, height: max(canvas.frame.height, pane.contentView.bounds.height)))
            for card in canvas.arrangedSubviews { card.isHidden = true }
        }
        var nextY: [Bool: CGFloat] = [true: 20, false: 20]
        var list: [ConnectorOverlayView.Connection] = []
        let lm = editor.layoutManager
        let tc = editor.textContainer

        // Map notes in visible range
        for n in displayedNotes.sorted(by: { $0.start < $1.start }) where !n.body.isEmpty && !isDiscussion(n) {
            let overlap = NSIntersectionRange(visible, NSRange(location: n.start, length: n.end - n.start))
            guard overlap.length > 0, let lm = lm, let tc = tc else { continue }
            let localRange = NSRange(location: overlap.location - visible.location, length: overlap.length)
            let glyphRange = lm.glyphRange(forCharacterRange: localRange, actualCharacterRange: nil)
            let textRect = lm.boundingRect(forGlyphRange: NSRange(location: glyphRange.location, length: min(1, glyphRange.length)), in: tc)

            // Convert text position into editorContainer coordinate system
            let glyphPoint = NSPoint(x:textRect.minX + editor.textContainerOrigin.x,y:textRect.midY + editor.textContainerOrigin.y)
            let textPtInContainer = connectorView.convert(glyphPoint, from: editor)
            guard connectorView.bounds.contains(textPtInContainer) else {continue}
            let isLeft = (n.side == "left") && !leftScroll.isHidden

            // Locate note card view in left/right stack
            let targetStack = isLeft ? leftNotes : rightNotes
            guard let card = targetStack.arrangedSubviews.first(where: {
                $0.identifier?.rawValue == n.id
            }) else { continue }

            card.isHidden = false
            let anchor = targetStack.convert(glyphPoint, from: editor)
            let width = max(160, targetStack.bounds.width - 24)
            let height = (card as? MarginNoteCard)?.desiredHeight(width: width) ?? 154
            let idealY = max(nextY[isLeft] ?? 20, anchor.y - 16)
            let y = idealY
            card.frame = NSRect(x: 12, y: y, width: width, height: height)
            card.layoutSubtreeIfNeeded()
            nextY[isLeft] = y + height + 16
            let cardMidInContainer = connectorView.convert(NSPoint(x:isLeft ? card.bounds.maxX : card.bounds.minX,y:card.bounds.midY),from:card)
            let color = noteColor(n)

            let start = NSPoint(x: isLeft ? 0 : editorContainer.bounds.width, y: cardMidInContainer.y)
            let end = NSPoint(x: isLeft ? textPtInContainer.x : min(editorContainer.bounds.maxX - 20,textPtInContainer.x + textRect.width), y: textPtInContainer.y)
            list.append(ConnectorOverlayView.Connection(startPoint: start, endPoint: end, color: color))
        }
        for (canvas, pane, isL) in [(leftNotes, leftScroll, true), (rightNotes, rightScroll, false)] {
            let requiredH = max(pane.contentView.bounds.height, (nextY[isL] ?? 20) + 40)
            canvas.frame = NSRect(x: 0, y: 0, width: pane.contentView.bounds.width, height: requiredH)
        }
        connectorView.connections = list
    }

    // MARK: - Apple Dictionary Suite (Word Level)
    func lookupDictionary() {
        let raw = editor.string.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
        guard !raw.isEmpty else { return }
        lookupWord(raw)
        populateWordList()
    }

    func lookupWord(_ rawWord: String, addToHistory: Bool = true) {
        let word = rawWord.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
        guard !word.isEmpty else { return }
        currentWord = word

        if addToHistory {
            if dictHistoryIndex < dictHistory.count - 1 {
                dictHistory = Array(dictHistory.prefix(dictHistoryIndex + 1))
            }
            if dictHistory.last?.lowercased() != word.lowercased() {
                dictHistory.append(word)
            }
            dictHistoryIndex = dictHistory.count - 1
        }
        updateDictNavigation()

        definition.string = "\(word)\n\nLooking up in macOS Dictionary…"
        lookupWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let entries = self.fetchDictionaryEntries(word: word, tab: self.selectedDictTab)
            self.currentDefinitionEntries = entries
            self.displayAppleDefinition()
            self.updateWordListHighlight()
        }
        lookupWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
    }

    func updateDictNavigation() {
        dictToolbar.backButton.isEnabled = dictHistoryIndex > 0
        dictToolbar.forwardButton.isEnabled = dictHistoryIndex < dictHistory.count - 1
    }

    @objc func dictNavBackAction() {
        guard dictHistoryIndex > 0 else { return }
        dictHistoryIndex -= 1
        let prev = dictHistory[dictHistoryIndex]
        lookupWord(prev, addToHistory: false)
    }

    @objc func dictNavForwardAction() {
        guard dictHistoryIndex < dictHistory.count - 1 else { return }
        dictHistoryIndex += 1
        let next = dictHistory[dictHistoryIndex]
        lookupWord(next, addToHistory: false)
    }

    func dictTabChanged(_ tab: Int) {
        selectedDictTab = tab
        dictToolbar.setSelectedIndex(tab)
        if !currentWord.isEmpty {
            lookupWord(currentWord, addToHistory: false)
        }
    }

    @objc func performDictSearch() {}

    func fetchDictionaryEntries(word: String, tab: Int) -> [(title: String, content: String)] {
        let clean = word.lowercased()
        var results: [(String, String)] = []

        switch tab {
        case 0: // All
            if let lv = dictionaries.lookup(word: clean, dictionary: dictionaries.lacViet) {
                results.append(("Vietnamese - English (Lạc Việt)", lv))
            }
            if let ox = dictionaries.lookup(word: clean, dictionary: dictionaries.oxford) {
                results.append(("Oxford Dictionary of English", ox))
            }
            if let th = dictionaries.lookup(word: clean, dictionary: dictionaries.thesaurus) {
                results.append(("Oxford Thesaurus", th))
            }
            if let tv = dictionaries.lookup(word: clean, dictionary: dictionaries.tiengViet) {
                results.append(("Từ Điển Tiếng Việt", tv))
            }
            if results.isEmpty {
                if let def = dictionaries.lookup(word: clean, dictionary: nil) {
                    results.append(("macOS Dictionary", def))
                }
            }
        case 1: // Lạc Việt
            if let lv = dictionaries.lookup(word: clean, dictionary: dictionaries.lacViet) {
                results.append(("Vietnamese - English (Lạc Việt)", lv))
            } else if let def = dictionaries.lookup(word: clean, dictionary: nil) {
                results.append(("Vietnamese - English (Fallback)", def))
            }
        case 2: // Oxford
            if let ox = dictionaries.lookup(word: clean, dictionary: dictionaries.oxford) {
                results.append(("Oxford Dictionary of English", ox))
            } else if let def = dictionaries.lookup(word: clean, dictionary: nil) {
                results.append(("Oxford Dictionary", def))
            }
        case 3: // Thesaurus
            if let th = dictionaries.lookup(word: clean, dictionary: dictionaries.thesaurus) {
                results.append(("Oxford Thesaurus", th))
            }
        case 4: // Tiếng Việt
            if let tv = dictionaries.lookup(word: clean, dictionary: dictionaries.tiengViet) {
                results.append(("Từ Điển Tiếng Việt", tv))
            } else if let def = dictionaries.lookup(word: clean, dictionary: nil) {
                results.append(("Từ Điển Tiếng Việt (Fallback)", def))
            }
        default:
            break
        }
        return results
    }

    func populateWordList() {}
    func updateWordListHighlight() {}
    @objc func wordListItemClicked(_ sender: NSButton) {}

    @objc func toggleDefinition() {
        fullDefinition.toggle()
        displayAppleDefinition()
    }

    func displayDefinition() {
        displayAppleDefinition()
    }

    func displayAppleDefinition() {
        let isDark = isDarkMode()
        let result = NSMutableAttributedString()

        // Sentence context
        var sentenceContext: String? = nil
        if opened {
            let sentenceRange = data.range(level: 2, offset: focus)
            let rawSent = (data.document.text as NSString).substring(with: sentenceRange).trimmingCharacters(in: .whitespacesAndNewlines)
            if !rawSent.isEmpty { sentenceContext = rawSent }
        }

        if currentDefinitionEntries.isEmpty {
            result.append(NSAttributedString(
                string: "\nNo definition found for \"\(currentWord)\".\n\nTip: Select the \"All\" or \"Oxford\" tab, or check your spelling.",
                attributes: [.font: NSFont.systemFont(ofSize: 15), .foregroundColor: NSColor.secondaryLabelColor]
            ))
        } else {
            for entry in currentDefinitionEntries {
                var cleanTitle = entry.title
                if let pIdx = cleanTitle.firstIndex(of: "(") {
                    cleanTitle = String(cleanTitle[..<pIdx]).trimmingCharacters(in: .whitespaces)
                }

                // Section divider matching Apple Dictionary
                let dividerText = "▼ ───  \(cleanTitle)  " + String(repeating: "─", count: max(4, 38 - cleanTitle.count)) + "\n\n"
                result.append(NSAttributedString(
                    string: dividerText,
                    attributes: [
                        .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                        .foregroundColor: isDark ? NSColor(white: 0.52, alpha: 1) : NSColor(white: 0.48, alpha: 1)
                    ]
                ))

                var text = entry.content
                var headword = currentWord
                var phonetics = ""

                if let firstPipe = text.firstIndex(of: "|"), let secondPipe = text[text.index(after: firstPipe)...].firstIndex(of: "|") {
                    let hw = String(text[..<firstPipe]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !hw.isEmpty { headword = hw }
                    phonetics = String(text[firstPipe...secondPipe])
                    text = String(text[text.index(after: secondPipe)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                } else if text.hasPrefix(currentWord) {
                    text = String(text.dropFirst(currentWord.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                }

                // Headword + Phonetic transcript line
                let headAttr = NSMutableAttributedString()
                headAttr.append(NSAttributedString(string: headword, attributes: [
                    .font: NSFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: isDark ? NSColor.white : NSColor.black
                ]))
                if !phonetics.isEmpty {
                    headAttr.append(NSAttributedString(string: "  " + phonetics, attributes: [
                        .font: NSFont.systemFont(ofSize: 14, weight: .regular),
                        .foregroundColor: NSColor.secondaryLabelColor
                    ]))
                }
                headAttr.append(NSAttributedString(string: "\n\n"))
                result.append(headAttr)

                // Synonyms marker
                for marker in ["từ đồng nghĩa", "từ trái nghĩa", "synonyms", "antonyms", "thesaurus"] {
                    if let r = text.range(of: marker, options: .caseInsensitive) {
                        let before = String(text[..<r.lowerBound])
                        let after = String(text[r.upperBound...])
                        text = before + "\n__SYNONYMS__" + marker.uppercased() + "\n" + after.trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    }
                }

                text = text.replacingOccurrences(of: " ▸ ", with: "\n    ▸ ")
                text = text.replacingOccurrences(of: " ▹ ", with: "\n    ▹ ")
                text = text.replacingOccurrences(of: " • ", with: "\n    • ")

                if let regex = try? NSRegularExpression(pattern: "(\\s+)(\\d+)(\\s+)") {
                    let ns = text as NSString
                    text = regex.stringByReplacingMatches(in: text, range: NSRange(location: 0, length: ns.length), withTemplate: "\n__NUM__$2 ")
                }

                let lines = text.components(separatedBy: "\n")
                var isFirstContentLine = true
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty { continue }

                    if trimmed.hasPrefix("__SYNONYMS__") {
                        let label = String(trimmed.dropFirst("__SYNONYMS__".count))
                        let p = NSMutableParagraphStyle()
                        p.paragraphSpacingBefore = 10
                        p.paragraphSpacing = 4
                        result.append(NSAttributedString(string: label + "\n", attributes: [
                            .font: NSFont.systemFont(ofSize: 11, weight: .bold),
                            .foregroundColor: isDark ? NSColor(white: 0.65, alpha: 1) : NSColor(white: 0.45, alpha: 1),
                            .paragraphStyle: p
                        ]))
                    } else if trimmed.hasPrefix("__NUM__") {
                        let item = String(trimmed.dropFirst("__NUM__".count))
                        let p = NSMutableParagraphStyle()
                        p.firstLineHeadIndent = 0
                        p.headIndent = 18
                        p.lineSpacing = 3
                        p.paragraphSpacing = 6

                        let numAttr = NSMutableAttributedString()
                        if let firstSpace = item.firstIndex(of: " ") {
                            let num = String(item[..<firstSpace])
                            let rest = String(item[firstSpace...])
                            numAttr.append(NSAttributedString(string: num + " ", attributes: [
                                .font: NSFont.systemFont(ofSize: 15, weight: .bold),
                                .foregroundColor: isDark ? NSColor.white : NSColor.black
                            ]))
                            numAttr.append(NSAttributedString(string: rest.trimmingCharacters(in: .whitespaces) + "\n", attributes: [
                                .font: NSFont.systemFont(ofSize: 15, weight: .regular),
                                .foregroundColor: isDark ? NSColor.white : NSColor.black,
                                .paragraphStyle: p
                            ]))
                        } else {
                            numAttr.append(NSAttributedString(string: item + "\n", attributes: [
                                .font: NSFont.systemFont(ofSize: 15, weight: .regular),
                                .foregroundColor: isDark ? NSColor.white : NSColor.black,
                                .paragraphStyle: p
                            ]))
                        }
                        result.append(numAttr)
                        isFirstContentLine = false
                    } else if trimmed.hasPrefix("▸") || trimmed.hasPrefix("▹") || trimmed.hasPrefix("•") {
                        let p = NSMutableParagraphStyle()
                        p.firstLineHeadIndent = 16
                        p.headIndent = 26
                        p.lineSpacing = 3
                        p.paragraphSpacing = 3
                        result.append(NSAttributedString(string: "  " + trimmed + "\n", attributes: [
                            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
                            .foregroundColor: isDark ? NSColor(white: 0.80, alpha: 1) : NSColor(white: 0.30, alpha: 1),
                            .paragraphStyle: p
                        ]))
                    } else if isFirstContentLine && (trimmed.contains("danh từ") || trimmed.contains("động từ") || trimmed.contains("tính từ") || trimmed.contains("noun") || trimmed.contains("verb") || trimmed.contains("adjective")) {
                        let p = NSMutableParagraphStyle()
                        p.paragraphSpacing = 6
                        let font = NSFontManager.shared.convert(NSFont.systemFont(ofSize: 13, weight: .regular), toHaveTrait: .italicFontMask)
                        result.append(NSAttributedString(string: trimmed + "\n", attributes: [
                            .font: font,
                            .foregroundColor: isDark ? NSColor(white: 0.70, alpha: 1) : NSColor(white: 0.38, alpha: 1),
                            .paragraphStyle: p
                        ]))
                        isFirstContentLine = false
                    } else {
                        let p = NSMutableParagraphStyle()
                        p.lineSpacing = 4
                        p.paragraphSpacing = 6
                        result.append(NSAttributedString(string: trimmed + "\n", attributes: [
                            .font: NSFont.systemFont(ofSize: 15),
                            .foregroundColor: isDark ? NSColor.white : NSColor.black,
                            .paragraphStyle: p
                        ]))
                        isFirstContentLine = false
                    }
                }
                result.append(NSAttributedString(string: "\n\n"))
            }
        }

        if let ctx = sentenceContext {
            let p = NSMutableParagraphStyle()
            p.lineSpacing = 4
            result.append(NSAttributedString(string: "IN YOUR ESSAY\n", attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: isDark ? NSColor(white: 0.65, alpha: 1) : NSColor(white: 0.45, alpha: 1)
            ]))
            result.append(NSAttributedString(string: "“" + ctx + "”\n", attributes: [
                .font: NSFont(name: "Georgia-Italic", size: 15) ?? NSFont.systemFont(ofSize: 15),
                .foregroundColor: isDark ? NSColor.white : NSColor.black,
                .paragraphStyle: p
            ]))
        }

        definition.textStorage?.setAttributedString(result)
        definition.scrollRangeToVisible(NSRange(location: 0, length: 0))
        definitionButton.title = fullDefinition ? "Show concise view" : "Show full dictionary entry"
        dictToolbar.countLabel.stringValue = "\(currentDefinitionEntries.count) found"
    }

    // MARK: - Adaptive Layout
    func windowDidResize(_ notification: Notification) { if opened {refreshTaskBrief()};adaptLayout() }

    func adaptLayout() {
        guard opened, let c = centerStack else{return}
        let width = (window.contentView?.bounds.width ?? 1000)
        commentsPane.isHidden = !commentsVisible || level == 3 || presentation
        commentsWidth?.isActive = !commentsPane.isHidden
        let inspectorWidth: CGFloat = commentsPane.isHidden ? 0 : 300
        let narrow = width - inspectorWidth < 1050
        NSLayoutConstraint.deactivate(paneHeightConstraints)
        leftWidth?.isActive = false;rightWidth?.isActive = false;dictWidth?.isActive = false;wordHeight?.isActive = false
        if level == 3 {
            c.orientation = .vertical;c.alignment = .width
            leftScroll.isHidden = true;rightScroll.isHidden = true;dictionaryPane.isHidden = false
            wordHeight?.constant = 140;wordHeight?.isActive = true
            editor.textContainerInset = NSSize(width:max(40,(width - 900) / 2),height:20)
            definition.textContainerInset = NSSize(width:20,height:14)
        }else{
            c.orientation = .horizontal;c.alignment = .top
            let show = prefs.bool(forKey:"notes") && (inspectorWidth == 0 || width >= 1100)
            leftScroll.isHidden = !show || narrow;rightScroll.isHidden = !show
            dictionaryPane.isHidden = true
            leftWidth?.constant = 210;rightWidth?.constant = narrow ? 225 : 210
            if !leftScroll.isHidden{leftWidth?.isActive = true}
            if !rightScroll.isHidden{rightWidth?.isActive = true}
            NSLayoutConstraint.activate(paneHeightConstraints)
            let available = max(360,width - inspectorWidth - (show ? (narrow ? 225 : 420) : 0) - 48)
            let inset = max(28,(available - prefs.double(forKey: "lineWidth")) / 2)
            editor.textContainerInset = NSSize(width:inset,height:level == 0 ? 28 : 48)
        }
        topBar?.isHidden = presentation;dock?.isHidden = presentation;exitPresentation.isHidden = !presentation
        updateConnectors()
    }
    @objc func togglePresentation(){
        guard opened else{return};presentation.toggle();editor.isEditable = !presentation
        adaptLayout();styleText();renderNotes()
    }

    // MARK: - Apple-style Highlight & Comment (Requirement 2)
    func wrapMarkup(_ start: String, end: String? = nil) {
        guard opened, !presentation else { return }
        let edit = PassageMarkup.toggle(data.document.text,selection:selectedRangeInDocument(),start:start,end:end ?? start)
        snapshot();data.replace(edit.range,with:edit.replacement)
        focus = edit.selection.location
        // Markup belongs to the source document; ensure the whole edited span is visible.
        if level > 0 {level = 0}
        render();editor.setSelectedRange(edit.selection)
        window.makeFirstResponder(editor); saveDraft()
    }
    @objc func insertLink() { wrapMarkup("[", end: "](https://)") }
    @objc func insertAnnotation() {
        guard opened, !presentation else { return }
        let range = selectedRangeInDocument()
        guard range.length > 0 else { showAlert("Select the text to annotate first."); return }
        guard let lm = editor.layoutManager, let tc = editor.textContainer else { return }
        let local = NSRange(location: range.location - visible.location, length: range.length)
        let glyphRange = lm.glyphRange(forCharacterRange: local, actualCharacterRange: nil)
        let rect = lm.boundingRect(forGlyphRange: glyphRange, in: tc)
        openCommentPopover(existing: nil, targetRect: rect, view: editor, mode: "annotation")
    }
    @objc func insertHeading() {
        guard opened, !presentation else { return }
        let range = (data.document.text as NSString).lineRange(for: selectedRangeInDocument())
        snapshot(); data.replace(NSRange(location:range.location,length:0), with:"# ")
        focus = range.location + 2; render(); saveDraft()
    }
    @objc func clearMarkup() {
        guard opened, !presentation else { return }
        let range = selectedRangeInDocument(); let text = (data.document.text as NSString).substring(with:range)
        let cleaned = text.replacingOccurrences(of:#"(?m)^#{1,6}\s+|\*\*|__|::|\+\+|\|\||(?<!\w)_(?=\S)|(?<=\S)_(?!\w)|`"#,with:"",options:.regularExpression)
        snapshot();data.replace(range,with:cleaned);render();saveDraft()
    }
    @objc func showMarkup() {
        guard opened else { return }
        let menu = NSMenu(title:"Markup")
        for title in ["Strong", "Emphasis", "Link", "Annotation", "Highlight", "Redact", "Comment", "Code", "Heading", "Quote", "List", "Divider", "Image", "Footnote", "Raw source", "Equation", "Table of contents"] {
            let item = menu.addItem(withTitle:title,action:#selector(applyMarkupItem(_:)),keyEquivalent:"");item.target = self
        }
        menu.popUp(positioning:nil,at:NSPoint(x:root.bounds.midX,y:root.bounds.midY),in:root)
    }
    @objc func applyMarkupItem(_ sender: NSMenuItem) {
        switch sender.title {
        case "Strong":bold();case "Emphasis":italic();case "Link":insertLink();case "Annotation":insertAnnotation()
        case "Highlight":wrapMarkup("::");case "Redact":wrapMarkup("||");case "Comment":wrapMarkup("++");case "Code":wrapMarkup("`")
        case "Image":addImage();case "Footnote":wrapMarkup("[^",end:"]");case "Raw source":wrapMarkup("~");case "Equation":wrapMarkup("$$");case "Table of contents":wrapMarkup("(toc)",end:"")
        case "Heading":insertHeading();case "Quote":wrapMarkup("> ",end:"");case "List":wrapMarkup("- ",end:"");default:wrapMarkup("\n----\n",end:"")
        }
    }
    @objc func fontLarger() { prefs.set(min(48,prefs.double(forKey:"size") + 1),forKey:"size");styleText() }
    @objc func fontSmaller() { prefs.set(max(12,prefs.double(forKey:"size") - 1),forKey:"size");styleText() }
    @objc func fontReset() { prefs.set(22,forKey:"size");styleText() }
    @objc func focusEditor() { if opened {window.makeFirstResponder(editor)} }
    @objc func toggleNotes() {prefs.set(!prefs.bool(forKey:"notes"),forKey:"notes");adaptLayout();renderNotes()}
    @objc func toggleDark() {prefs.set(!prefs.bool(forKey:"dark"),forKey:"dark");applyAppearance();if opened{styleText()}}
    @objc func saveVersion() {if opened {saveDraft()}}

    @objc func bold() { wrapMarkup("**") }
    @objc func italic() { wrapMarkup("_") }
    @objc func underline() { markFormatting("underline") }

    @objc func highlight() {
        guard opened else { return }
        let r = selectedRangeInDocument()
        guard r.length > 0 else {
            showAlert("Select text to highlight.")
            return
        }
        snapshot()
        // Toggle highlight: if existing on this exact range, remove it
        if let idx = data.annotations.firstIndex(where: { $0.kind == "highlight" && $0.start == r.location && $0.end == NSMaxRange(r) }) {
            data.annotations.remove(at: idx)
        } else {
            let n = Note(
                id: UUID().uuidString,
                start: r.location,
                end: NSMaxRange(r),
                quote: (data.document.text as NSString).substring(with: r),
                kind: "highlight",
                level: ["essay", "paragraph", "sentence", "word"][level],
                label: "Highlight",
                body: ""
            )
            data.annotations.append(n)
        }
        styleText()
        saveDraft()
    }

    func markFormatting(_ kind: String) {
        guard opened else { return }
        let r = selectedRangeInDocument()
        guard r.length > 0 else { showAlert("Select text first."); return }
        snapshot()
        if let i = data.annotations.firstIndex(where: { $0.kind == kind && $0.start == r.location && $0.end == NSMaxRange(r) }) {
            data.annotations.remove(at: i)
        } else {
            data.annotations.append(Note(
                id: UUID().uuidString,
                start: r.location,
                end: NSMaxRange(r),
                quote: (data.document.text as NSString).substring(with: r),
                kind: kind,
                level: ["essay", "paragraph", "sentence", "word"][level],
                label: "Formatting",
                body: ""
            ))
        }
        styleText()
        saveDraft()
    }

    let tagColors = ["blue","orange","red","purple","green","yellow","gray"]
    func tagName(_ color:String)->String {prefs.string(forKey:"tag." + color) ?? color.capitalized}
    func noteColor(_ note:Note)->NSColor {tagColor(note.tag ?? (note.kind == "correction" ? "orange" : "blue"))}
    func tagColor(_ color:String)->NSColor {
        switch color {
        case "orange":return .systemOrange;case "red":return .systemRed;case "purple":return .systemPurple;case "green":return .systemGreen;case "yellow":return .systemYellow;case "gray":return .systemGray;default:return .systemBlue
        }
    }

    @objc func noteClicked(_ sender: NSButton) {
        guard let n = displayedNotes.first(where: { $0.id == sender.identifier?.rawValue }) else { return }
        openCommentPopover(existing:n,targetRect:sender.bounds,view:sender)
    }

    @objc func openDOI(_ sender: NSButton) {
        guard let doi = sender.identifier?.rawValue, !doi.isEmpty else { return }
        let urlStr = doi.hasPrefix("http") ? doi : "https://doi.org/" + doi
        if let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func openNotePreview(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue,
              let note = displayedNotes.first(where: { $0.id == id }) else { return }
        showHoverPreview(for: note, at: sender.convert(NSPoint(x: sender.bounds.midX, y: sender.bounds.minY), to: editor))
    }

    func handleTextHover(index: Int?, point: NSPoint) {
        guard opened, let idx = index, idx >= 0, idx < (data.document.text as NSString).length else {
            hoverSourcePopover?.close()
            lastHoverNoteId = nil
            return
        }
        let docOffset = visible.location + idx
        if let note = displayedNotes.first(where: { !isDiscussion($0) && docOffset >= $0.start && docOffset < $0.end }) {
            if lastHoverNoteId != note.id {
                lastHoverNoteId = note.id
                showHoverPreview(for: note, at: point)
            }
        } else {
            let mode = prefs.string(forKey: "pointerMode") ?? "Hold fn"
            if PointerPolicy.isModifierActive(mode: mode, flags: NSEvent.modifierFlags) {
                let sentRange = data.range(level: 2, offset: docOffset)
                let sentId = "sent-\(sentRange.location)-\(sentRange.length)"
                if lastHoverNoteId != sentId && sentRange.length > 5 {
                    lastHoverNoteId = sentId
                    let rawSent = (data.document.text as NSString).substring(with: sentRange)
                    showSentenceInsight(for: rawSent, at: point)
                }
            } else {
                hoverSourcePopover?.close()
                lastHoverNoteId = nil
            }
        }
    }

    func showSentenceInsight(for sentence: String, at point: NSPoint) {
        hoverSourcePopover?.close()
        let isDark = isDarkMode()
        let analysis = LocalFeedback.analyzeSentence(sentence)

        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        let vc = NSViewController()
        let popView = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 140))
        popView.wantsLayer = true

        let badgeLabel = NSTextField(labelWithString: analysis.isApple ? "✦ APPLE INTELLIGENCE · WRITING INSIGHT" : "✦ WRITING ANALYZER · ON-DEVICE")
        badgeLabel.font = .systemFont(ofSize: 10, weight: .bold)
        badgeLabel.textColor = LiquidGlass.accent(isDark: isDark)

        let titleLabel = NSTextField(wrappingLabelWithString: analysis.label)
        titleLabel.font = .systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = .labelColor

        let quoteLabel = NSTextField(wrappingLabelWithString: "“" + sentence.trimmingCharacters(in: .whitespacesAndNewlines) + "”")
        quoteLabel.font = NSFont(name: "Georgia-Italic", size: 12) ?? .systemFont(ofSize: 12)
        quoteLabel.textColor = .secondaryLabelColor
        quoteLabel.maximumNumberOfLines = 3
        quoteLabel.lineBreakMode = .byTruncatingTail

        let bodyLabel = NSTextField(wrappingLabelWithString: analysis.body)
        bodyLabel.font = .systemFont(ofSize: 12, weight: .medium)
        bodyLabel.textColor = .labelColor

        let containerStack = NSStackView(views: [badgeLabel, titleLabel, quoteLabel, bodyLabel])
        containerStack.orientation = .vertical
        containerStack.alignment = .width
        containerStack.spacing = 6
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        popView.addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.leadingAnchor.constraint(equalTo: popView.leadingAnchor, constant: 14),
            containerStack.trailingAnchor.constraint(equalTo: popView.trailingAnchor, constant: -14),
            containerStack.topAnchor.constraint(equalTo: popView.topAnchor, constant: 12),
            containerStack.bottomAnchor.constraint(equalTo: popView.bottomAnchor, constant: -12)
        ])

        let fittingSize = containerStack.fittingSize
        popView.frame.size = NSSize(width: max(320, fittingSize.width + 28), height: max(100, fittingSize.height + 24))

        vc.view = popView
        pop.contentViewController = vc
        hoverSourcePopover = pop

        let targetRect = NSRect(origin: point, size: NSSize(width: 1, height: 18))
        pop.show(relativeTo: targetRect, of: editor, preferredEdge: .maxY)
    }

    func showHoverPreview(for note: Note, at point: NSPoint) {
        hoverSourcePopover?.close()
        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let width: CGFloat = 360
        let content = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 360))
        let text = NSTextView(frame: NSRect(x: 0, y: 0, width: width - 24, height: 300))
        text.isEditable = false
        text.isSelectable = true
        text.drawsBackground = false
        text.isVerticallyResizable = true
        text.autoresizingMask = [.width]
        text.textContainer?.widthTracksTextView = true
        text.textContainerInset = NSSize(width: 8, height: 10)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        let value = NSMutableAttributedString(string: note.label + "\n\n", attributes: [.font: NSFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: noteColor(note)])
        value.append(NSAttributedString(string: "“" + note.quote + "”\n\n", attributes: [.font: NSFont.systemFont(ofSize: 13), .foregroundColor: NSColor.secondaryLabelColor, .paragraphStyle: paragraph]))
        value.append(NSAttributedString(string: note.body + (note.suggestion.map { "\n\nSuggested: " + $0 } ?? ""), attributes: [.font: NSFont.systemFont(ofSize: 14), .foregroundColor: NSColor.labelColor, .paragraphStyle: paragraph]))
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            for match in detector.matches(in: value.string, range: NSRange(location: 0, length: value.length)) {
                if let url = match.url { value.addAttribute(.link, value: url, range: match.range) }
            }
        }
        text.textStorage?.setAttributedString(value)
        if let container = text.textContainer { text.layoutManager?.ensureLayout(for: container) }
        let fullHeight = text.textContainer.flatMap { text.layoutManager?.usedRect(for: $0).height } ?? 300
        let height = min(460, max(180, fullHeight + 68))
        content.setFrameSize(NSSize(width: width, height: height))
        text.setFrameSize(NSSize(width: width - 24, height: max(height - 48, fullHeight + 24)))
        let scrollView = NSScrollView(frame: NSRect(x: 12, y: 44, width: width - 24, height: height - 56))
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.documentView = text
        content.addSubview(scrollView)
        let edit = button("Edit note", #selector(noteClicked))
        edit.identifier = NSUserInterfaceItemIdentifier(note.id)
        edit.frame = NSRect(x: 16, y: 10, width: 100, height: 26)
        content.addSubview(edit)
        let controller = NSViewController()
        controller.view = content
        pop.contentViewController = controller
        hoverSourcePopover = pop
        pop.show(relativeTo: NSRect(origin: point, size: NSSize(width: 1, height: 18)), of: editor, preferredEdge: .maxY)
    }

    @objc func comment() {
        guard opened else { return }
        let r = selectedRangeInDocument()
        guard r.length > 0 else {
            showAlert("Select a passage to comment.")
            return
        }
        // Calculate rect of selection in editor
        guard let lm = editor.layoutManager, let tc = editor.textContainer else {return}
        let local = NSRange(location: r.location - visible.location, length: r.length)
        let glyphRange = lm.glyphRange(forCharacterRange: local, actualCharacterRange: nil)
        let rect = lm.boundingRect(forGlyphRange: glyphRange, in: tc)
        openCommentPopover(existing: nil, targetRect: rect, view: editor)
    }

    func openCommentPopover(existing: Note?, targetRect: NSRect, view: NSView, mode: String = "comment") {
        if commentsEditing { closeComment() }
        commentPopover?.close();floatingCommentButton?.isHidden = true
        let p = NSPopover()
        p.behavior = .transient
        p.delegate = self
        p.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        textRefresh?.cancel()
        snapshot()
        editingInline = existing?.id.hasPrefix("inline-") == true || existing?.sourceStyle == "brace"
        editingNoteId = existing?.id
        targetRange = existing.map { NSRange(location: $0.start, length: $0.end - $0.start) } ?? selectedRangeInDocument()

        let vc = NSViewController()
        let popView = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 360))

        let isComment = existing.map { isDiscussion($0) } ?? (mode == "comment")
        editingSurface = isComment ? .comment : .annotation
        let titleText: String = {
            if isComment {
                return existing == nil ? "New comment" : "Edit comment"
            } else {
                return existing == nil ? "New annotation" : "Edit annotation"
            }
        }()
        let titleLabel = NSTextField(labelWithString: titleText)
        let defaultLabel = isComment ? "Feedback" : "Annotation"
        commentLabel = NSTextField(string: existing?.label ?? defaultLabel)
        commentLabel.placeholderString = isComment ? "Comment Title (e.g. Mentor Feedback, Note)" : "Annotation Title (e.g. Legal Basis, Thesis)"
        commentTag = NSPopUpButton()
        for tag in tagColors {
            commentTag.addItem(withTitle: tagName(tag))
            commentTag.lastItem?.representedObject = tag
            commentTag.lastItem?.image = NSImage(systemSymbolName: "flag.fill", accessibilityDescription: tag)?.withSymbolConfiguration(.init(paletteColors: [tagColor(tag)]))
        }
        commentLabel.delegate = self
        commentTag.target = self
        commentTag.action = #selector(annotationChanged)
        commentTag.selectItem(at: tagColors.firstIndex(of: existing?.tag ?? (isComment ? "purple" : "blue")) ?? 0)
        titleLabel.font = currentHeadlineFont(size: 14)

        commentKind = NSPopUpButton()
        commentKind.addItems(withTitles: ["comment", "correction", "vocabulary", "structure"])
        commentKind.selectItem(withTitle: existing?.kind ?? (isComment ? "comment" : "structure"))
        commentKind.target = self
        commentKind.action = #selector(annotationChanged)

        commentField = NSTextView(frame: NSRect(x: 0, y: 0, width: 280, height: 90))
        commentField.string = existing?.body ?? ""
        commentField.font = .systemFont(ofSize: 15)
        commentField.isRichText = false
        commentField.delegate = self
        commentField.autoresizingMask = [.width]
        commentField.isVerticallyResizable = true
        commentField.textContainer?.widthTracksTextView = true

        let s = NSScrollView()
        s.documentView = commentField
        s.hasVerticalScroller = true
        s.heightAnchor.constraint(equalToConstant: 140).isActive = true

        let delBtn = button(isComment ? "Remove comment" : "Remove annotation", #selector(deleteComment))
        delBtn.isHidden = (existing == nil)
        let move = button(isComment ? "Move to margin" : "Move to comments", #selector(moveNoteSurface))
        move.isHidden = existing == nil || editingInline
        let actions = stack([move, delBtn], vertical: true)

        let pills: NSStackView = {
            if isComment {
                return stack([
                    stack([button("Feedback", #selector(quickPillFeedback)), button("Clarity", #selector(quickPillClarity)), button("Logic", #selector(quickPillLogic))]),
                    stack([button("Source", #selector(quickPillSource)), button("Correction", #selector(quickPillCorrection)), button("Action", #selector(quickPillAction))])
                ], vertical: true)
            } else {
                return stack([
                    stack([button("Task", #selector(quickPillTask)), button("Cohesion", #selector(quickPillCoherence)), button("Vocabulary", #selector(quickPillVocab))]),
                    stack([button("Clause", #selector(quickPillClause)), button("Argument", #selector(quickPillArgument)), button("Correction", #selector(quickPillCorrection))])
                ], vertical: true)
            }
        }()
        pills.spacing = 6

        _ = pills
        let all = stack(isComment ? [titleLabel, s, actions] : [titleLabel, commentTag, s, actions], vertical: true)
        all.alignment = .width
        all.spacing = 8
        attach(all, to: popView, inset: 12)

        popView.setFrameSize(NSSize(width: 320, height: all.fittingSize.height + 24))
        vc.view = popView
        p.contentViewController = vc
        if isComment {
            popView.heightAnchor.constraint(equalToConstant: 250).isActive = true
            installCommentEditor(popView)
            return
        }
        commentPopover = p
        p.show(relativeTo: targetRect, of: view, preferredEdge: .maxY)
        p.contentViewController?.view.window?.makeFirstResponder(commentField)
    }

    @objc func quickPillFeedback() {
        commentLabel.stringValue = "Mentor Feedback"
        commentKind.selectItem(withTitle: "comment")
        commentTag.selectItem(at: tagColors.firstIndex(of: "purple") ?? 0)
        annotationChanged()
    }
    @objc func quickPillClarity() {
        commentLabel.stringValue = "Clarity & Phrasing"
        commentKind.selectItem(withTitle: "comment")
        commentTag.selectItem(at: tagColors.firstIndex(of: "blue") ?? 0)
        annotationChanged()
    }
    @objc func quickPillLogic() {
        commentLabel.stringValue = "Check Reasoning"
        commentKind.selectItem(withTitle: "comment")
        commentTag.selectItem(at: tagColors.firstIndex(of: "orange") ?? 0)
        annotationChanged()
    }
    @objc func quickPillAction() {
        commentLabel.stringValue = "Action Required"
        commentKind.selectItem(withTitle: "comment")
        commentTag.selectItem(at: tagColors.firstIndex(of: "red") ?? 0)
        annotationChanged()
    }
    @objc func quickPillClause() {
        commentLabel.stringValue = "Căn cứ & Điều khoản"
        commentKind.selectItem(withTitle: "structure")
        commentTag.selectItem(at: tagColors.firstIndex(of: "orange") ?? 0)
        annotationChanged()
    }

    @objc func quickPillTask(){commentLabel.stringValue = "Task Response";commentKind.selectItem(withTitle:"comment");commentTag.selectItem(at:tagColors.firstIndex(of:"blue") ?? 0);annotationChanged()}
    @objc func quickPillCoherence(){commentLabel.stringValue = "Coherence & Flow";commentKind.selectItem(withTitle:"structure");commentTag.selectItem(at:tagColors.firstIndex(of:"purple") ?? 0);annotationChanged()}
    @objc func quickPillVocab(){commentLabel.stringValue = "Vocabulary Choice";commentKind.selectItem(withTitle:"vocabulary");commentTag.selectItem(at:tagColors.firstIndex(of:"green") ?? 0);annotationChanged()}
    @objc func quickPillSource(){commentLabel.stringValue = "Source Preview";commentKind.selectItem(withTitle:"comment");commentTag.selectItem(at:tagColors.firstIndex(of:"orange") ?? 1);if commentField.string.isEmpty{commentField.string = "Source title / author:\nVerified source URL or DOI:\nEvidence and limitation: "};annotationChanged()}
    @objc func quickPillArgument(){commentLabel.stringValue = "Thesis & Argument Flow";commentKind.selectItem(withTitle:"structure");commentTag.selectItem(at:tagColors.firstIndex(of:"purple") ?? 3);annotationChanged()}
    @objc func quickPillGrammar(){commentLabel.stringValue = "Grammar & Accuracy";commentKind.selectItem(withTitle:"structure");commentTag.selectItem(at:tagColors.firstIndex(of:"yellow") ?? 0);annotationChanged()}
    @objc func quickPillCorrection(){commentLabel.stringValue = "Correction";commentKind.selectItem(withTitle:"correction");commentTag.selectItem(at:tagColors.firstIndex(of:"orange") ?? 0);annotationChanged()}

    @objc func closeComment() {
        commentPopover?.close()
        commentPopover = nil
        commentsEditing = false
        annotationSave?.cancel()
        saveDraft()
        renderNotes()
    }

    @objc func deleteComment() {
        if let id = editingNoteId {
            snapshot()
            data.annotations.removeAll { $0.id == id }
            if editingInline {
                let quote = (data.document.text as NSString).substring(with:targetRange)
                if quote.hasPrefix("{"),quote.hasSuffix("}") {data.replace(targetRange,with:String(quote.dropFirst().dropLast()));let origin = scroll.contentView.bounds.origin;render();scroll.contentView.scroll(to:origin)}
            }
            renderNotes()
            styleText()
            saveDraft()
        }
        closeComment()
    }

    func controlTextDidChange(_ notification:Notification) {
        if notification.object as? NSTextField === commentLabel { persistComment() }
        if notification.object as? NSTextField === taskPromptField {
            data.document.prompt = taskPromptField?.stringValue
            saveDraft()
        }
    }
    func controlTextDidBeginEditing(_ notification:Notification) {
        if notification.object as? NSTextField === taskPromptField {snapshot()}
    }
    func controlTextDidEndEditing(_ notification:Notification) {
        if notification.object as? NSTextField === taskPromptField {saveDraft();refreshTaskBrief()}
    }
    @objc func annotationChanged(){persistComment()}
    func popoverDidClose(_ notification:Notification) {
        guard notification.object as? NSPopover === commentPopover else{return}
        annotationSave?.cancel();saveDraft();styleText();renderNotes()
    }
    @objc func saveComment() {persistComment();closeComment()}
    func persistComment() {
        let body = commentField.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        let old = data.annotations.first { $0.id == editingNoteId }
        // Automatically alternate sides (left vs right) if not specified (Requirement 3)
        let defaultSide = (data.annotations.filter { $0.side == "left" }.count <= data.annotations.filter { $0.side == "right" }.count) ? "left" : "right"
        let note = Note(
            id: editingNoteId?.hasPrefix("inline-") == true ? UUID().uuidString : (editingNoteId ?? UUID().uuidString),
            start: targetRange.location,
            end: NSMaxRange(targetRange),
            quote: (data.document.text as NSString).substring(with: targetRange),
            kind: commentKind.titleOfSelectedItem ?? "comment",
            level: old?.level ?? ["essay", "paragraph", "sentence", "word"][level],
            label: commentLabel.stringValue.isEmpty ? "Annotation" : commentLabel.stringValue,
            body: body,
            suggestion: old?.suggestion,
            side: old?.side ?? defaultSide,
            status: old?.status,
            tag: commentTag.selectedItem?.representedObject as? String, sourceStyle: editingInline ? "brace" : old?.sourceStyle
        )
        data.annotations.removeAll { $0.id == note.id }
        data.annotations.append(note)
        editingNoteId = note.id
        notePresentation.set(editingSurface, documentID: data.document.id, noteID: note.id)
        annotationSave?.cancel()
        let save = DispatchWorkItem { [weak self] in self?.saveDraft() };annotationSave = save
        DispatchQueue.main.asyncAfter(deadline:.now() + 0.3,execute:save)

    }

    @objc func addImage() {
        guard opened else{return}
        let panel = NSOpenPanel();panel.allowedContentTypes = [.png,.jpeg,.tiff,.heic];panel.allowsMultipleSelection = false
        panel.beginSheetModal(for:window) { [weak self] response in
            guard let self = self,response == .OK,let url = panel.url else{return}
            self.receiveFiles([url])
        }
    }
    func receiveFiles(_ urls:[URL]) {
        do {
            if urls.count == 1,let url = urls.first,url.pathExtension.lowercased() == "json" {if opened {saveDraft()};try loadJSON(Data(contentsOf:url));openWorkspace();return}
            var images = data.images ?? []
            for url in urls {
                let size = (try url.resourceValues(forKeys:[.fileSizeKey])).fileSize ?? 0
                guard size <= 8_000_000,images.count < 12,images.reduce(0,{$0 + $1.data.count}) + size <= 48_000_000 else{throw ModelError.invalid}
                let bytes = try Data(contentsOf:url)
                guard NSImage(data:bytes) != nil else {showAlert("Choose an image: PNG, JPEG, TIFF or HEIC.");return}
                images.append(DocumentImage(id:UUID().uuidString,name:url.lastPathComponent,data:bytes))
            }
            snapshot();data.images = images;saveDraft();showImages()
        } catch {showAlert("Could not add image. Use up to 12 images, 8 MB each and 48 MB total.")}
    }
    func updateBriefToggleIcon() {
        let sym = briefHidden ? "chevron.down" : "chevron.up"
        if #available(macOS 11.0, *), let img = NSImage(systemSymbolName: sym, accessibilityDescription: briefHidden ? "Show task details" : "Hide task details") {
            let conf = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            briefToggleButton?.image = img.withSymbolConfiguration(conf)
        }
        briefToggleButton?.toolTip = briefHidden ? "Show task prompt & images" : "Hide task prompt"
    }

    @objc func toggleTaskBrief() {
        let origin = scroll.contentView.bounds.origin
        let oldHeight = taskBriefHeight?.constant ?? 0
        briefTransition += 1
        let transition = briefTransition
        briefAnimating = false
        briefHidden.toggle()
        refreshTaskBrief()
        let targetHeight = taskBriefHeight?.constant ?? 0
        let animate = window.isVisible && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        guard animate else {
            root.layoutSubtreeIfNeeded()
            scroll.contentView.scroll(to: origin)
            scheduleAnnotationLayout()
            return
        }
        // Clip the details while the disclosure changes size; never animate individual text/anchors.
        taskBrief.isHidden = false
        taskBriefHeight?.constant = oldHeight
        root.layoutSubtreeIfNeeded()
        briefAnimating = true
        connectorView.connections = []
        NSAnimationContext.runAnimationGroup { context in
            context.duration = BrandMotion.disclosure
            context.timingFunction = BrandMotion.smoothOut
            context.allowsImplicitAnimation = true
            taskBriefHeight?.constant = targetHeight
            root.layoutSubtreeIfNeeded()
        } completionHandler: { [weak self] in
            guard let self = self, self.briefTransition == transition else { return }
            self.briefAnimating = false
            self.taskBrief.isHidden = self.briefHidden
            self.root.layoutSubtreeIfNeeded()
            self.scroll.contentView.scroll(to: origin)
            self.scroll.reflectScrolledClipView(self.scroll.contentView)
            self.scheduleAnnotationLayout()
        }
    }
    @objc func editTaskBrief(){
        if briefHidden { briefHidden = false; refreshTaskBrief(); updateBriefToggleIcon() }
        if let field = taskPromptField {
            window.makeFirstResponder(field)
            field.currentEditor()?.selectedRange = NSRange(location: (field.stringValue as NSString).length, length: 0)
        } else {
            snapshot()
            data.document.prompt = "Add a prompt, context or instructions for this document."
            saveDraft()
            refreshTaskBrief()
            updateBriefToggleIcon()
            if let field = taskPromptField {
                window.makeFirstResponder(field)
                field.selectText(nil)
            }
        }
    }
    @objc func saveTaskBrief(){snapshot();if let pe = promptEditor{data.document.prompt = pe.string};briefHidden = false;closeOnboarding();saveDraft();refreshTaskBrief();updateBriefToggleIcon()}
    @objc func deleteTaskBrief(){snapshot();data.document.prompt = nil;data.images = nil;taskPromptField = nil;closeOnboarding();saveDraft();refreshTaskBrief();updateBriefToggleIcon()}
    @objc func showImages() { briefHidden = false;refreshTaskBrief();updateBriefToggleIcon() }
    func refreshTaskBrief(){
        let prompt = data.document.prompt ?? ""
        let hasTask = !prompt.isEmpty || !(data.images ?? []).isEmpty
        briefEditButton?.title = "Add task"
        briefEditButton?.isHidden = !prompt.isEmpty
        briefToggleButton?.isHidden = !hasTask
        updateBriefToggleIcon()
        defer {scheduleAnnotationLayout()}
        taskToggleRow?.isHidden = !hasTask
        taskBrief.isHidden = briefHidden || !hasTask
        guard !taskBrief.isHidden else {
            taskBriefHeight?.constant = 0
            return
        }
        let width = max(300, (window.contentView?.bounds.width ?? 1000) - 48)
        let innerWidth = min(920, width - 48)
        let leading = (width - innerWidth) / 2
        let content = MarginCanvas(frame:NSRect(x:0,y:0,width:width,height:220));content.autoresizesSubviews = false
        let paired = !(data.images ?? []).isEmpty && innerWidth > 620
        let textWidth = paired ? innerWidth * 0.47 : innerWidth
        let detailLabel = NSTextField(labelWithString: "DOCUMENT DETAILS  ·  " + readingType(data.document.taskType))
        detailLabel.font = .systemFont(ofSize: 11, weight: .medium)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.frame = NSRect(x: leading, y: 16, width: innerWidth - 100, height: 18)
        content.addSubview(detailLabel)
        let removeDetails = button("Remove details", #selector(deleteTaskBrief))
        removeDetails.isBordered = false
        removeDetails.font = .systemFont(ofSize: 11)
        removeDetails.contentTintColor = .secondaryLabelColor
        removeDetails.frame = NSRect(x: leading + innerWidth - 100, y: 12, width: 100, height: 24)
        content.addSubview(removeDetails)
        var y:CGFloat = 44
        if !prompt.isEmpty {
            let size = max(19,prefs.double(forKey:"briefSize"))
            let label = NSTextField(wrappingLabelWithString:prompt)
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 4
            paragraph.paragraphSpacing = 8
            let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size), .foregroundColor: NSColor.labelColor, .paragraphStyle: paragraph]
            label.attributedStringValue = NSAttributedString(string: prompt, attributes: attributes)
            label.font = .systemFont(ofSize:size, weight: .regular)
            label.isEditable = true
            label.isSelectable = true
            label.drawsBackground = false
            label.isBordered = false
            label.focusRingType = .none
            label.toolTip = "Click to edit the task. Changes save automatically."
            label.setAccessibilityLabel("Task prompt — click to edit")
            label.delegate = self
            taskPromptField = label
            let height = (prompt as NSString).boundingRect(with:NSSize(width:textWidth,height:10000),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:attributes).height + 20
            label.frame = NSRect(x:leading,y:44,width:textWidth,height:height)
            content.addSubview(label)
            y = height + 60
        } else {
            taskPromptField = nil
        }
        var imageY:CGFloat = paired ? 44 : y
        for picture in data.images ?? [] {
            guard let image = NSImage(data:picture.data) else{continue}
            let x:CGFloat = leading + (paired ? innerWidth * 0.53 : 0)
            let imageWidth = paired ? innerWidth * 0.47 : innerWidth
            let remove = button("Remove image",#selector(removeImage(_:)));remove.identifier = .init(picture.id);remove.frame = NSRect(x:x,y:imageY,width:116,height:24);content.addSubview(remove)
            let height = min(175,imageWidth * image.size.height / max(1,image.size.width))
            let view = NSImageView(frame:NSRect(x:x,y:imageY + 28,width:imageWidth,height:height));view.image = image;view.imageScaling = .scaleProportionallyUpOrDown;content.addSubview(view);imageY += height + 40
        }
        let height = max(y,imageY);content.setFrameSize(NSSize(width:width,height:height));taskBrief.documentView = content
        taskBriefHeight?.constant = min(min(260,(window.contentView?.bounds.height ?? 700) * 0.35),max(100,height))
    }
    @objc func removeImage(_ sender:NSButton){snapshot();data.images?.removeAll{$0.id == sender.identifier?.rawValue};saveDraft();showImages()}

    // MARK: - Import / Export
    @objc func openRecent(_ sender: NSButton) {
        guard let path = sender.identifier?.rawValue else { return }
        let url = URL(fileURLWithPath: path)
        do {
            let bytes = try Data(contentsOf: url)
            guard bytes.count <= 100_000_000 else { throw ModelError.invalid }
            if opened { saveDraft() }
            if url.pathExtension.lowercased() == "json" { try loadJSON(bytes) }
            else {
                guard bytes.count <= 3_000_000, let text = String(data: bytes, encoding: .utf8) else { throw ModelError.invalid }
                data = .plain(text, title: url.deletingPathExtension().lastPathComponent); past = []; future = []
            }
            NSDocumentController.shared.noteNewRecentDocumentURL(url); openWorkspace()
        } catch { showAlert(error.localizedDescription) }
    }

    @objc func importFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .json, UTType(filenameExtension: "md") ?? .text, UTType(filenameExtension: "markdown") ?? .text]
        panel.beginSheetModal(for: window) { [weak self] resp in
            guard let self = self, resp == .OK, let url = panel.url else { return }
            do {
                if self.opened { self.saveDraft() }
                let bytes = try Data(contentsOf: url)
                guard bytes.count <= 100_000_000 else { throw ModelError.invalid }
                if url.pathExtension.lowercased() == "json" {
                    try self.loadJSON(bytes)
                } else {
                    guard bytes.count <= 3_000_000, let text = String(data: bytes, encoding: .utf8) else { throw ModelError.invalid }
                    self.data = .plain(text, title: url.deletingPathExtension().lastPathComponent)
                    self.past = []
                    self.future = []
                }
                NSDocumentController.shared.noteNewRecentDocumentURL(url)
                self.openWorkspace()
            } catch {
                self.showAlert(error.localizedDescription)
            }
        }
    }

    @objc func exportFile() {
        guard opened else { return }
        renameTitle()
        let panel = NSSavePanel()
        panel.nameFieldStringValue = data.document.title + ".json"
        let format = NSPopUpButton()
        format.addItems(withTitles: ["Annotation JSON (.json)", "Pure text (.txt)", "Pure text (.md)"])
        panel.accessoryView = stack([format, NSTextField(labelWithString:"JSON includes annotations and images. MD / TXT contains text only.")], vertical:true)

        panel.beginSheetModal(for: window) { [weak self] resp in
            guard let self = self, resp == .OK, let chosen = panel.url else { return }
            do {
                let idx = format.indexOfSelectedItem
                let ext = ["json", "txt", "md"][idx]
                let url = chosen.pathExtension.lowercased() == ext ? chosen : chosen.deletingPathExtension().appendingPathExtension(ext)
                if url != chosen && FileManager.default.fileExists(atPath:url.path){self.showAlert("That filename already exists. Choose its exact name in Save to confirm replacement.");return}
                let bytes: Data
                if idx == 0 {
                    let enc = JSONEncoder()
                    enc.outputFormatting = [.prettyPrinted, .sortedKeys]
                    bytes = try enc.encode(self.data)
                } else {
                    bytes = Data(self.data.document.text.utf8)
                }
                try bytes.write(to: url, options: .atomic)
            } catch {
                self.showAlert(error.localizedDescription)
            }
        }
    }

    func saveDraft() {
        guard opened else { return }
        data.document.title = titleField.stringValue
        do {
            try FileManager.default.createDirectory(at: saveURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(data).write(to: saveURL, options: .atomic)
            try LibraryStore.save(data,to:saveURL.deletingLastPathComponent().appendingPathComponent("Library"))
        } catch {
            header.stringValue = "Could not save locally — export a copy"
        }
    }

    func applyAppearance() {
        let isDark = isDarkMode()
        let appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
        NSApp.appearance = appearance
        window?.appearance = appearance
        preferencesWindow?.appearance = appearance
        updateRootBackground()
    }

    @objc func toggleFullScreen() {
        window.toggleFullScreen(nil)
    }

    // MARK: - Onboarding Modal (Requirement 7)
    @objc func showOnboarding() {
        let sheet = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 580, height: 500), styleMask: [.titled], backing: .buffered, defer: false)
        sheet.title = "Pass Passage By! — Writing Studio Setup"

        let title = NSTextField(labelWithString: "Pass Passage By!")
        title.font = currentHeadlineFont(size: 24)

        let intro = NSTextField(wrappingLabelWithString: "Your native writing studio for closer readings, academic source previews, and pedagogical feedback.")
        intro.font = .systemFont(ofSize: 14)
        intro.textColor = .secondaryLabelColor

        let f1 = createFeatureRow(symbol: "atom", title: "Academic Research & Source Previews", desc: "Read credited open-access selections, follow DOI links, and discuss the evidence in the margins.")
        let f2 = createFeatureRow(symbol: "text.quote", title: "Argument Flow & Composition", desc: "Analyze thesis statements, concessions, and counter-arguments with bidirectional visual connector guidelines.")
        let f3 = createFeatureRow(symbol: "graduationcap", title: "IELTS Band 8.5+ Criteria", desc: "Evaluate Task 1 and Task 2 essays across Task Response, Coherence, Lexical Resource, and Grammar.")
        let f4 = createFeatureRow(symbol: "sparkles", title: "Antigravity AI Agent Kit (@PPB!)", desc: "Connect local agents to review essays, export skill packages, or import structured annotation JSONs.")

        let startBtn = button("Try Practice Document", #selector(startFromOnboarding))
        startBtn.controlSize = .large

        let close = button("Done", #selector(closeOnboarding), keyEquivalent: "\u{1b}")
        let all = stack([title, intro, f1, f2, f3, f4, dictionaryPicker(), stack([close, startBtn])], vertical: true)
        all.spacing = 11
        all.alignment = .leading
        if let content = sheet.contentView {attach(all, to: content, inset: 24)}

        window.beginSheet(sheet)
    }

    func createFeatureRow(symbol: String, title: String, desc: String) -> NSView {
        let icon: NSImageView
        if #available(macOS 11.0, *), let img = NSImage(systemSymbolName: symbol, accessibilityDescription: title) {
            icon = NSImageView(image: img)
            icon.contentTintColor = .controlAccentColor
        } else {
            icon = NSImageView()
        }
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 26).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 26).isActive = true

        let t = NSTextField(labelWithString: title)
        t.font = currentHeadlineFont(size: 14)
        let d = NSTextField(wrappingLabelWithString: desc)
        d.font = .systemFont(ofSize:12)
        d.textColor = .secondaryLabelColor

        let textStack = stack([t, d], vertical: true)
        textStack.spacing = 2

        let row = stack([icon, textStack])
        row.spacing = 14
        row.alignment = .top
        return row
    }

    @objc func closeOnboarding(){if let sheet = window.attachedSheet {window.endSheet(sheet);sheet.orderOut(nil)}}
    @objc func startFromOnboarding() {
        prefs.set(true, forKey: "onboarded")
        if let sheet = window.attachedSheet {
            window.endSheet(sheet)
            sheet.orderOut(nil)
        }
        openExample()
    }

    // MARK: - Settings (Requirement 5: Themes)
    @objc func showSettings(_ sender: Any?) {
        let panel = preferencesWindow ?? makePreferencesWindow()
        panel.center();panel.makeKeyAndOrderFront(nil);NSApp.activate(ignoringOtherApps:true)
    }
    func makePreferencesWindow()->NSWindow {
        let panel = NSWindow(contentRect:NSRect(x:0,y:0,width:760,height:540),styleMask:[.titled,.closable],backing:.buffered,defer:false)
        panel.title = "Settings";panel.isReleasedWhenClosed = false;panel.collectionBehavior = [.fullScreenAuxiliary,.moveToActiveSpace]
        let content = MarginCanvas(frame:NSRect(x:0,y:0,width:760,height:540));content.autoresizesSubviews = false
        let sidebarTitle = NSTextField(labelWithString:"Preferences");sidebarTitle.font = .systemFont(ofSize:16,weight:.semibold);sidebarTitle.frame = NSRect(x:20,y:24,width:150,height:26);content.addSubview(sidebarTitle)
        let tabs = NSTabView(frame:NSRect(x:190,y:0,width:570,height:540));tabs.tabViewType = .noTabsNoBorder;content.addSubview(tabs);preferencesTabs = tabs;preferencesNavigation = []
        func popup(_ key:String,_ values:[String])->NSPopUpButton {
            let control = NSPopUpButton();control.addItems(withTitles:values);control.selectItem(withTitle:prefs.string(forKey:key) ?? values[0]);control.identifier = .init(key);control.target = self;control.action = #selector(settingChanged);return control
        }
        func row(_ label:String,_ control:NSView)->NSStackView {
            let title = NSTextField(labelWithString:label);title.widthAnchor.constraint(equalToConstant:150).isActive = true
            if control is NSPopUpButton || control is NSTextField {control.widthAnchor.constraint(equalToConstant:270).isActive = true}
            return stack([title,control])
        }
        func check(_ key:String,_ label:String)->NSButton {
            let control = NSButton(checkboxWithTitle:label,target:self,action:#selector(settingChanged));control.identifier = .init(key);control.state = prefs.bool(forKey:key) ? .on : .off;return control
        }
        let dark = check("dark","Dark appearance");appearanceToggle = dark
        let themePicker = ThemePicker(selected:prefs.string(forKey:"theme") ?? "Paper")
        themePicker.onChange = { [weak self] title in
            let control = NSPopUpButton();control.addItem(withTitle:title);control.identifier = .init("theme");self?.settingChanged(control)
        }
        let preset = popup("zoomPreset",["Teacher","Student","Custom"]);zoomPresetControl = preset
        let path = NSTextField(wrappingLabelWithString:zoomPathDescription());path.textColor = .secondaryLabelColor;zoomRouteLabel = path
        let picker = ZoomPathPicker();zoomPathPicker = picker
        picker.configure(route:PassageMarkup.route(prefs.string(forKey:"zoomPreset") ?? "Teacher",paragraph:prefs.bool(forKey:"zoomParagraph"),sentence:prefs.bool(forKey:"zoomSentence")))
        picker.onChange = { [weak self] route in
            guard let self = self else{return}
            self.prefs.set(route.contains(1),forKey:"zoomParagraph");self.prefs.set(route.contains(2),forKey:"zoomSentence")
            self.prefs.set("Custom",forKey:"zoomPreset");self.zoomPresetControl?.selectItem(withTitle:"Custom")
            self.zoomRouteLabel?.stringValue = self.zoomPathDescription()
            if self.opened {self.level = 0;self.editor.clearPointer();self.render()}
        }
        let dict = popup("dictionary",["System default"] + dictionaries.entries.map{$0.0})
        let tagRows = tagColors.map {color -> NSView in
            let field = NSTextField(string:tagName(color));field.identifier = .init("tag." + color);field.target = self;field.action = #selector(renameTag(_:))
            let label = NSTextField(labelWithString:"●  " + color.capitalized);label.textColor = tagColor(color);label.widthAnchor.constraint(equalToConstant:150).isActive = true;field.widthAnchor.constraint(equalToConstant:270).isActive = true
            return stack([label,field])
        }
        let presetTitle = NSTextField(labelWithString:"Tag Palettes")
        presetTitle.textColor = .secondaryLabelColor
        presetTitle.font = .systemFont(ofSize:12,weight:.semibold)
        presetTitle.widthAnchor.constraint(equalToConstant:150).isActive = true
        let presetStack = NSStackView()
        presetStack.orientation = .horizontal
        presetStack.spacing = 6
        presetStack.alignment = .centerY
        func makePresetButton(_ title: String, _ action: Selector) -> NSButton {
            let b = NSButton(title: title, target: self, action: action)
            b.bezelStyle = .rounded
            b.controlSize = .small
            b.font = .systemFont(ofSize: 11, weight: .medium)
            return b
        }
        let b1 = makePresetButton("NĐ 30", #selector(applyPresetAdministrative))
        let b2 = makePresetButton("Onboarding", #selector(applyPresetOnboarding))
        let b3 = makePresetButton("IELTS", #selector(applyPresetIelts))
        let b4 = makePresetButton("Mặc định", #selector(applyPresetDefault))
        for btn in [b1, b2, b3, b4] { presetStack.addArrangedSubview(btn) }
        let presetRow = stack([presetTitle, presetStack])
        let sections:[(String,String,[NSView])] = [
            ("Appearance","Choose the page and pointer colors you read comfortably.",[dark,row("Pointer highlight",popup("pointerMode",["Hold fn","Hold Option","Always","Off"])),themePicker,row("Hover effect",popup("hoverStyle",["Solid","Gradient","Stardust"])),check("notes","Show margin annotations")]),
            ("Typography","Essay and task text have separate reading sizes.",[row("Writing font",popup("font",["Georgia","Baskerville","Helvetica Neue","Menlo"])),numericSetting("size",label:"Essay size (pt)",minimum:16,maximum:32),numericSetting("briefSize",label:"Task size (pt)",minimum:17,maximum:28),numericSetting("spacing",label:"Line spacing",minimum:1.2,maximum:2.2),numericSetting("paragraphSpacing",label:"Paragraph gap",minimum:0,maximum:60),numericSetting("lineWidth",label:"Writing width",minimum:400,maximum:1100),numericSetting("indent",label:"First line indent",minimum:0,maximum:60)]),
            ("Gestures","Configure shortcuts and reading navigation path.",[row("Reading path",preset),picker,path]),
            ("Dictionary","Only dictionaries installed on this Mac are listed.",[row("Dictionary",dict)]),
            ("Tags","Rename each color or pick a preconfigured palette for your workflow.",[presetRow] + tagRows),
            ("Updates","Signed updates are delivered through Sparkle.",updateSettingsControls()),
            ("Intelligence","OCR uses Apple Vision and works without model downloads.",[NSTextField(wrappingLabelWithString:LocalFeedback.appleStatus),NSTextField(wrappingLabelWithString:"AI feedback runs locally when Apple Intelligence is available. No automatic model downloads. Review suggestions before teaching.")])
        ]
        for (index,section) in sections.enumerated(){
            let nav = button(section.0,#selector(selectPreferencesSection(_:)));nav.image = NSImage(systemSymbolName:["paintpalette","textformat","hand.point.up.left","character.book.closed","tag","arrow.triangle.2.circlepath","sparkles"][index],accessibilityDescription:section.0);nav.imagePosition = .imageLeading;nav.isBordered = false;nav.alignment = .left;nav.tag = index;nav.frame = NSRect(x:16,y:72 + index * 42,width:162,height:36);content.addSubview(nav);preferencesNavigation.append(nav)
            let page = MarginCanvas(frame:NSRect(x:0,y:0,width:570,height:540));page.autoresizesSubviews = false
            let title = NSTextField(labelWithString:section.0);title.font = .systemFont(ofSize:22,weight:.semibold);title.frame = NSRect(x:24,y:24,width:510,height:30);page.addSubview(title)
            let subtitle = NSTextField(wrappingLabelWithString:section.1);subtitle.font = .systemFont(ofSize:12);subtitle.textColor = .secondaryLabelColor;subtitle.frame = NSRect(x:24,y:60,width:510,height:34);page.addSubview(subtitle)
            var y:CGFloat = 112
            for control in section.2 {
                if let row = control as? NSStackView,let title = row.arrangedSubviews.first as? NSTextField {title.widthAnchor.constraint(equalToConstant:150).isActive = true}
                let height:CGFloat = control is ZoomPathPicker ? 150 : (control is ThemePicker ? 104 : 36)
                control.frame = NSRect(x:24,y:y,width:510,height:height);page.addSubview(control);y += height + 14
            }
            let item = NSTabViewItem(identifier:section.0);item.view = page;tabs.addTabViewItem(item)
        }
        panel.contentView = content;preferencesWindow = panel;selectPreferencesSection(preferencesNavigation[0]);return panel
    }
    func updateSettingsControls()->[NSView] {
        let version = Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? "Development"
        let title = NSTextField(labelWithString:"Pass Passage By! " + version)
        let status = NSTextField(wrappingLabelWithString:appUpdates.status);status.textColor = .secondaryLabelColor
        let auto = NSButton(checkboxWithTitle:"Automatically check for updates",target:self,action:#selector(changeUpdateChecks(_:)));auto.state = appUpdates.automaticallyChecks ? .on : .off
        let check = NSButton(title:"Check for Updates…",target:appUpdates,action:#selector(AppUpdates.check(_:)));check.bezelStyle = .rounded
        return [title,status,auto,check]
    }
    @objc func changeUpdateChecks(_ sender:NSButton){appUpdates.automaticallyChecks = sender.state == .on}
    @objc func selectPreferencesSection(_ sender:NSButton){
        preferencesTabs?.selectTabViewItem(at:sender.tag)
        for button in preferencesNavigation {button.contentTintColor = button === sender ? .controlAccentColor : .labelColor;button.font = .systemFont(ofSize:13,weight:button === sender ? .semibold : .regular);button.wantsLayer = true;if let layer = button.layer { LiquidGlass.configureLayer(layer, radius: 8, shadow: false) };button.layer?.backgroundColor = (button === sender ? NSColor.controlAccentColor.withAlphaComponent(0.13) : NSColor.clear).cgColor}
    }

    @objc func renameTag(_ sender:NSTextField){guard let key = sender.identifier?.rawValue else{return};prefs.set(sender.stringValue,forKey:key);if opened {renderNotes()}}
    @objc func applyPresetAdministrative() {
        applyTagPreset([
            ("blue", "Thể thức chuẩn"),
            ("orange", "Căn cứ pháp lý"),
            ("purple", "Thẩm quyền ban hành"),
            ("green", "Điều khoản quy định"),
            ("red", "Hiệu lực thi hành"),
            ("yellow", "Văn phong hành chính"),
            ("gray", "Nơi nhận & Lưu trữ")
        ])
    }
    @objc func applyPresetOnboarding() {
        applyTagPreset([
            ("blue", "Quy định chung"),
            ("orange", "Quy trình thực hiện"),
            ("purple", "Hạn mức duyệt chi"),
            ("green", "Lưu ý quan trọng"),
            ("red", "Nghiêm cấm / Chế tài"),
            ("yellow", "Biểu mẫu đính kèm"),
            ("gray", "Hỗ trợ & Liên hệ")
        ])
    }
    @objc func applyPresetIelts() {
        applyTagPreset([
            ("blue", "Task Response"),
            ("orange", "Coherence & Cohesion"),
            ("purple", "Lexical Resource"),
            ("green", "Grammatical Accuracy"),
            ("red", "Critical Correction"),
            ("yellow", "Thesis & Topic"),
            ("gray", "Academic Register")
        ])
    }
    @objc func applyPresetDefault() {
        applyTagPreset([
            ("blue", "Blue"),
            ("orange", "Orange"),
            ("red", "Red"),
            ("purple", "Purple"),
            ("green", "Green"),
            ("yellow", "Yellow"),
            ("gray", "Gray")
        ])
    }
    func applyTagPreset(_ list: [(String, String)]) {
        for (color, name) in list {
            prefs.set(name, forKey: "tag." + color)
        }
        if let tabs = preferencesTabs {
            for item in tabs.tabViewItems where item.identifier as? String == "Tags" {
                if let page = item.view {
                    let fields = page.subviews.compactMap { $0 as? NSStackView }
                        .flatMap { $0.arrangedSubviews }
                        .compactMap { $0 as? NSTextField }
                        .filter { $0.isEditable }
                    for field in fields {
                        if let id = field.identifier?.rawValue, id.hasPrefix("tag.") {
                            let color = String(id.dropFirst(4))
                            field.stringValue = tagName(color)
                        }
                    }
                }
            }
        }
        if opened { renderNotes() }
    }
    func numericSetting(_ key: String, label: String, minimum: Double, maximum: Double) -> NSView {
        let field = NSTextField(string: String(format:key == "spacing" ? "%.2f" : "%.0f",prefs.double(forKey:key)))
        let formatter = NumberFormatter();formatter.minimum = NSNumber(value:minimum);formatter.maximum = NSNumber(value:maximum);formatter.maximumFractionDigits = 2
        field.formatter = formatter;field.identifier = .init(key);field.target = self;field.action = #selector(settingChanged)
        field.widthAnchor.constraint(equalToConstant:90).isActive = true
        let stepper = NSStepper();stepper.minValue = minimum;stepper.maxValue = maximum;stepper.increment = key == "spacing" ? 0.05 : 1;stepper.doubleValue = prefs.double(forKey:key)
        stepper.identifier = .init(key);stepper.target = self;stepper.action = #selector(stepSetting(_:))
        return stack([NSTextField(labelWithString:label),field,stepper])
    }
    @objc func stepSetting(_ sender: NSStepper) {
        if let row = sender.superview as? NSStackView, let field = row.arrangedSubviews.compactMap({$0 as? NSTextField}).last {
            field.doubleValue = sender.doubleValue
        }
        settingChanged(sender)
    }

    func dictionaryPicker() -> NSView {
        let pop = NSPopUpButton()
        pop.addItems(withTitles: ["System default"] + dictionaries.entries.map { $0.0 })
        pop.selectItem(withTitle: prefs.string(forKey: "dictionary") ?? "System default")
        pop.identifier = .init("dictionary"); pop.target = self; pop.action = #selector(settingChanged)
        return stack([NSTextField(labelWithString: "Dictionary"), pop])
    }

    @objc func settingChanged(_ sender: NSControl) {
        guard let key = sender.identifier?.rawValue else { return }
        if let p = sender as? NSPopUpButton {
            prefs.set(p.titleOfSelectedItem, forKey: key)
            if key == "theme" {
                prefs.set(p.titleOfSelectedItem == "Midnight", forKey: "dark")
                appearanceToggle?.state = prefs.bool(forKey:"dark") ? .on : .off
            }
        } else if let b = sender as? NSButton {
            prefs.set(b.state == .on, forKey: key)
        } else {
            let limits: [String: ClosedRange<Double>] = ["size":12...48,"spacing":1.2...2.2,"paragraphSpacing":0...60,"indent":0...60,"lineWidth":400...1100,"briefSize":17...28]
            if let limit = limits[key] {
                let value = sender.doubleValue.isFinite ? min(limit.upperBound,max(limit.lowerBound,sender.doubleValue)) : limit.lowerBound
                sender.doubleValue = value;prefs.set(value,forKey:key)
                if let row = sender.superview as? NSStackView { for control in row.arrangedSubviews where control !== sender {
                    if let step = control as? NSStepper {step.doubleValue = value}
                    if let field = control as? NSTextField, field.isEditable {field.doubleValue = value}
                }}
            } else {prefs.set(sender.doubleValue,forKey:key)}
        }
        if key == "zoomParagraph" || key == "zoomSentence" {
            prefs.set("Custom",forKey:"zoomPreset");zoomPresetControl?.selectItem(withTitle:"Custom")
        }
        if key == "pointerMode" {editor.clearPointer()}
        if key.hasPrefix("zoom") {
            zoomPathPicker?.configure(route:PassageMarkup.route(prefs.string(forKey:"zoomPreset") ?? "Teacher",paragraph:prefs.bool(forKey:"zoomParagraph"),sentence:prefs.bool(forKey:"zoomSentence")))
            zoomRouteLabel?.stringValue = zoomPathDescription()
            if opened {level = 0;editor.clearPointer();gestureDelta = 0;render()}
        }
        if key == "dictionary", opened, level == 3 { fullDefinition = false; lookupDictionary() }
        applyAppearance()
        if opened {
            if key == "briefSize" {refreshTaskBrief()}
            styleText()
            renderNotes()
            adaptLayout()
        }
    }

    @objc func showAbout() {
        let panel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 440), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        panel.title = "About Pass Passage By!"
        panel.isReleasedWhenClosed = false

        let canvas = MarginCanvas(frame: NSRect(x: 0, y: 0, width: 520, height: 440))
        panel.contentView = canvas

        // App Icon
        let iconView = NSImageView(frame: NSRect(x: (520 - 56) / 2, y: 20, width: 56, height: 56))
        iconView.image = NSImage(named: "Passage") ?? NSImage(systemSymbolName: "book.closed", accessibilityDescription: "Pass Passage By!")
        iconView.wantsLayer = true
        if let layer = iconView.layer { LiquidGlass.configureLayer(layer, radius: 12, shadow: false) }
        iconView.layer?.masksToBounds = true
        canvas.addSubview(iconView)

        func makeLabel(_ text: String, y: CGFloat, size: CGFloat, weight: NSFont.Weight, color: NSColor = .labelColor) -> NSTextField {
            let tf = NSTextField(wrappingLabelWithString: text)
            tf.font = .systemFont(ofSize: size, weight: weight)
            tf.textColor = color
            tf.alignment = .center
            tf.frame = NSRect(x: 24, y: y, width: 472, height: 22)
            canvas.addSubview(tf)
            return tf
        }

        _ = makeLabel("Pass Passage By!", y: 84, size: 19, weight: .bold)
        _ = makeLabel("Version 1.6.0 (Build 9) · Academic Writing Studio", y: 108, size: 12, weight: .medium, color: .secondaryLabelColor)

        let desc = NSTextField(wrappingLabelWithString: "The native writing studio for closer readings, academic source previews, and pedagogical feedback on macOS.")
        desc.font = NSFont(name: "Georgia", size: 13) ?? .systemFont(ofSize: 13)
        desc.alignment = .center
        desc.textColor = .labelColor
        desc.frame = NSRect(x: 36, y: 134, width: 448, height: 36)
        canvas.addSubview(desc)

        // 4 Badges in 2 columns
        let badges: [(String, String)] = [
            ("🔬 Research", "DOI previews & citations"),
            ("✍️ Essays", "Argument flow & dialectics"),
            ("🎓 IELTS", "Task 1 & 2 band criteria"),
            ("🤖 @PPB!", "Antigravity AI Agent kit")
        ]
        let colW: CGFloat = 220
        for (i, b) in badges.enumerated() {
            let col = i % 2
            let row = i / 2
            let x: CGFloat = 34 + CGFloat(col) * (colW + 12)
            let y: CGFloat = 178 + CGFloat(row) * 40

            let badgeView = NSView(frame: NSRect(x: x, y: y, width: colW, height: 34))
            badgeView.wantsLayer = true
            if let layer = badgeView.layer { LiquidGlass.configureLayer(layer, radius: 8, shadow: false) }
            badgeView.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor

            let titleTf = NSTextField(labelWithString: b.0)
            titleTf.font = .systemFont(ofSize: 11, weight: .bold)
            titleTf.textColor = .labelColor
            titleTf.frame = NSRect(x: 10, y: 17, width: colW - 20, height: 15)

            let descTf = NSTextField(labelWithString: b.1)
            descTf.font = .systemFont(ofSize: 10, weight: .regular)
            descTf.textColor = .secondaryLabelColor
            descTf.frame = NSRect(x: 10, y: 2, width: colW - 20, height: 14)

            badgeView.addSubview(titleTf)
            badgeView.addSubview(descTf)
            canvas.addSubview(badgeView)
        }

        // Tech specs
        let specs = NSTextField(wrappingLabelWithString: "Apple Silicon Native · Apple Vision OCR · Liquid Glass HIG · Sparkle Updates")
        specs.font = .systemFont(ofSize: 11, weight: .medium)
        specs.textColor = .tertiaryLabelColor
        specs.alignment = .center
        specs.frame = NSRect(x: 24, y: 270, width: 472, height: 18)
        canvas.addSubview(specs)

        // Separator
        let sep = NSBox(frame: NSRect(x: 36, y: 294, width: 448, height: 1))
        sep.boxType = .separator
        canvas.addSubview(sep)

        // Copyright / Local-first
        let copy = NSTextField(wrappingLabelWithString: "Local-first • No account or API keys required • Privacy by design")
        copy.font = .systemFont(ofSize: 11, weight: .regular)
        copy.textColor = .secondaryLabelColor
        copy.alignment = .center
        copy.frame = NSRect(x: 24, y: 304, width: 472, height: 18)
        canvas.addSubview(copy)

        // Glass Done button
        let doneBtn = GlassPillButton(title: "Done", target: self, action: #selector(closeInfoWindow))
        doneBtn.bezelStyle = .regularSquare
        doneBtn.isBordered = false
        doneBtn.frame = NSRect(x: (520 - 120) / 2, y: 334, width: 120, height: 30)
        doneBtn.attributedTitle = NSAttributedString(
            string: "Done",
            attributes: [
                .foregroundColor: NSColor.labelColor,
                .font: NSFont.systemFont(ofSize: 12, weight: .semibold)
            ]
        )
        canvas.addSubview(doneBtn)

        infoWindow = panel
        panel.center()
        panel.makeKeyAndOrderFront(nil)
    }

    @objc func closeInfoWindow() {
        infoWindow?.close()
    }

    @objc func showPrivacy() { showInfo("Privacy Policy", file: "PRIVACY") }
    @objc func showTerms() { showInfo("Terms of Service", file: "TERMS") }

    func showInfo(_ title: String, file: String) {
        let url = Bundle.main.url(forResource: file, withExtension: "txt") ?? resourceDirectory.appendingPathComponent(file + ".txt")
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        let panel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 520), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        panel.title = title
        panel.isReleasedWhenClosed = false

        let view = NSTextView(frame: NSRect(x: 0, y: 0, width: 600, height: 520))
        view.isEditable = false
        view.isSelectable = true
        view.string = text
        view.font = NSFont(name: "Georgia", size: 14) ?? .systemFont(ofSize: 14)
        view.textContainerInset = NSSize(width: 32, height: 28)

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.documentView = view
        view.autoresizingMask = [.width]
        view.isVerticallyResizable = true
        view.textContainer?.widthTracksTextView = true
        panel.contentView = scroll
        infoWindow = panel
        panel.center()
        panel.makeKeyAndOrderFront(nil)
    }

    func showAlert(_ text: String) {
        let a = NSAlert()
        a.messageText = "Pass Passage By!"
        a.informativeText = text
        a.beginSheetModal(for: window)
    }
}
