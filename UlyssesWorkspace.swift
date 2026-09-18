import Cocoa
import QuartzCore

// MARK: - Ulysses Data Models & Enums

enum UlyssesGroupType: String {
    case all = "All"
    case inbox = "Inbox"
    case gettingStarted = "Getting Started"
    case project = "Project"
}

struct UlyssesGroupItem {
    let id: String
    let name: String
    let icon: String
    let type: UlyssesGroupType
    var badgeCount: Int = 0
}

struct UlyssesSheetItem {
    let id: String
    let title: String
    let snippet: String
    let dateString: String
    let document: Breakdown
}

// MARK: - Ulysses Annotation Popover (Screenshot 3)

final class UlyssesAnnotationPopover: NSPopover {
    var onRemove: (() -> Void)?
    var onSave: ((String) -> Void)?

    static func show(
        for note: Note,
        relativeTo rect: NSRect,
        of view: NSView,
        preferredEdge: NSRectEdge = .maxY,
        isDark: Bool = true,
        onRemove: (() -> Void)? = nil,
        onSave: ((String) -> Void)? = nil
    ) -> UlyssesAnnotationPopover {
        let pop = UlyssesAnnotationPopover()
        pop.behavior = .transient
        pop.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        pop.onRemove = onRemove
        pop.onSave = onSave

        let width: CGFloat = 320
        let height: CGFloat = 136
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        container.wantsLayer = true

        let textScroll = NSScrollView(frame: NSRect(x: 14, y: 44, width: width - 28, height: 76))
        textScroll.drawsBackground = false
        textScroll.hasVerticalScroller = true

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: width - 28, height: 76))
        textView.string = note.body.isEmpty ? note.label : note.body
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: 13, weight: .regular)
        textView.textColor = isDark ? NSColor.white : NSColor.black
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 0, height: 2)
        textScroll.documentView = textView
        container.addSubview(textScroll)

        let divider = NSBox(frame: NSRect(x: 12, y: 38, width: width - 24, height: 1))
        divider.boxType = .separator
        container.addSubview(divider)

        let removeBtn = NSButton(
            title: "Remove Annotation",
            target: pop,
            action: #selector(handleRemove)
        )
        removeBtn.bezelStyle = .inline
        removeBtn.isBordered = false
        removeBtn.font = .systemFont(ofSize: 11, weight: .regular)
        removeBtn.contentTintColor = .secondaryLabelColor
        removeBtn.frame = NSRect(x: width - 146, y: 8, width: 134, height: 22)
        container.addSubview(removeBtn)

        let vc = NSViewController()
        vc.view = container
        pop.contentViewController = vc
        pop.show(relativeTo: rect, of: view, preferredEdge: preferredEdge)
        return pop
    }

    @objc func handleRemove() {
        close()
        onRemove?()
    }
}

// MARK: - Ulysses Bottom Markup Bar (Screenshot 1 & 2)

final class UlyssesMarkupBar: NSView {
    var onMarkup: ((String) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupBar()
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    private func setupBar() {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 20
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        let items = [
            ("# Title", "heading"),
            ("- List", "list"),
            ("> Quote", "quote"),
            ("(img) Image", "image"),
            ("...", "more")
        ]

        for (title, actionKey) in items {
            let btn = NSButton(title: title, target: self, action: #selector(itemClicked(_:)))
            btn.identifier = NSUserInterfaceItemIdentifier(actionKey)
            btn.bezelStyle = .inline
            btn.isBordered = false
            btn.font = .systemFont(ofSize: 12, weight: .regular)
            btn.contentTintColor = .secondaryLabelColor
            stack.addArrangedSubview(btn)
        }

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    @objc private func itemClicked(_ sender: NSButton) {
        if let key = sender.identifier?.rawValue {
            onMarkup?(key)
        }
    }
}

// MARK: - Ulysses Library Sidebar (Column 1)

final class UlyssesSidebar: NSView, NSTableViewDataSource, NSTableViewDelegate {
    var groups: [UlyssesGroupItem] = []
    var onSelectGroup: ((UlyssesGroupItem) -> Void)?
    var onToggleSidebar: (() -> Void)?
    var onNewGroup: (() -> Void)?

    private let table = NSTableView()
    private let scrollView = NSScrollView()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupView()
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    private func setupView() {
        let topBar = NSView()
        topBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topBar)

        let newGroupBtn = GlassCircleButton(
            symbolName: "folder.badge.plus",
            target: self,
            action: #selector(newGroupAction),
            size: 28,
            accessibilityDescription: "New Group"
        )

        let toggleBtn = GlassCircleButton(
            symbolName: "sidebar.left",
            target: self,
            action: #selector(toggleAction),
            size: 28,
            accessibilityDescription: "Toggle Sidebar"
        )

        let headerStack = NSStackView(views: [newGroupBtn, toggleBtn])
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(headerStack)

        let col = NSTableColumn(identifier: .init("group"))
        table.addTableColumn(col)
        table.headerView = nil
        table.rowHeight = 28
        table.dataSource = self
        table.delegate = self
        table.backgroundColor = .clear
        table.selectionHighlightStyle = .regular

        scrollView.documentView = table
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: topAnchor),
            topBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 44),

            headerStack.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -14),
            headerStack.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            scrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func newGroupAction() { onNewGroup?() }
    @objc private func toggleAction() { onToggleSidebar?() }

    func reloadData(with groups: [UlyssesGroupItem]) {
        self.groups = groups
        table.reloadData()
        if !groups.isEmpty && table.selectedRow < 0 {
            table.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int { groups.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = groups[row]
        let cell = NSTableCellView()
        cell.wantsLayer = true

        let icon = NSImageView()
        if let img = NSImage(systemSymbolName: item.icon, accessibilityDescription: item.name) {
            icon.image = img
        }
        icon.contentTintColor = .systemBlue
        icon.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(icon)

        let label = NSTextField(labelWithString: item.name)
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(label)

        var constraints = [
            icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 12),
            icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),

            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ]

        if item.badgeCount > 0 {
            let badge = NSTextField(labelWithString: "\(item.badgeCount)")
            badge.font = .systemFont(ofSize: 11, weight: .semibold)
            badge.textColor = .secondaryLabelColor
            badge.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(badge)
            constraints.append(badge.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -12))
            constraints.append(badge.centerYAnchor.constraint(equalTo: cell.centerYAnchor))
            constraints.append(label.trailingAnchor.constraint(lessThanOrEqualTo: badge.leadingAnchor, constant: -4))
        } else {
            constraints.append(label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -12))
        }

        NSLayoutConstraint.activate(constraints)
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = table.selectedRow
        guard row >= 0 && row < groups.count else { return }
        onSelectGroup?(groups[row])
    }
}

// MARK: - Ulysses Sheet List (Column 2)

final class UlyssesSheetList: NSView, NSTableViewDataSource, NSTableViewDelegate {
    var sheets: [UlyssesSheetItem] = []
    var groupTitle: String = "All" {
        didSet { titleLabel.stringValue = groupTitle }
    }
    var onSelectSheet: ((UlyssesSheetItem) -> Void)?
    var onNewSheet: (() -> Void)?

    private let titleLabel = NSTextField(labelWithString: "All")
    private let table = NSTableView()
    private let scrollView = NSScrollView()
    private var sortBtn: GlassCircleButton?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupView()
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    private func setupView() {
        let topBar = NSView()
        topBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topBar)

        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(titleLabel)

        let sBtn = GlassCircleButton(
            symbolName: "slider.horizontal.3",
            target: self,
            action: #selector(filterToggleAction(_:)),
            size: 28,
            accessibilityDescription: "Filter"
        )
        sortBtn = sBtn

        let newBtn = GlassCircleButton(
            symbolName: "square.and.pencil",
            target: self,
            action: #selector(newSheetAction),
            size: 28,
            accessibilityDescription: "New Sheet"
        )

        let trailingStack = NSStackView(views: [sBtn, newBtn])
        trailingStack.spacing = 8
        trailingStack.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(trailingStack)

        let col = NSTableColumn(identifier: .init("sheet"))
        table.addTableColumn(col)
        table.headerView = nil
        table.rowHeight = 88
        table.dataSource = self
        table.delegate = self
        table.backgroundColor = .clear
        table.selectionHighlightStyle = .regular

        scrollView.documentView = table
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: topAnchor),
            topBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            trailingStack.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -14),
            trailingStack.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            scrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func newSheetAction() { onNewSheet?() }
    @objc private func filterToggleAction(_ sender: GlassCircleButton) { sender.isActive.toggle() }

    func reloadData(with sheets: [UlyssesSheetItem]) {
        self.sheets = sheets
        table.reloadData()
        if !sheets.isEmpty && table.selectedRow < 0 {
            table.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int { sheets.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = sheets[row]
        let cell = NSView()
        cell.wantsLayer = true

        let card = NSView()
        card.wantsLayer = true
        if let l = card.layer {
            l.cornerCurve = .continuous
            l.cornerRadius = 8
        }
        card.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(card)

        let dateLabel = NSTextField(labelWithString: item.dateString)
        dateLabel.font = .systemFont(ofSize: 11, weight: .regular)
        dateLabel.textColor = .tertiaryLabelColor
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(dateLabel)

        let titleField = NSTextField(labelWithString: item.title.isEmpty ? "Empty Sheet" : item.title)
        titleField.font = .systemFont(ofSize: 13, weight: item.title.isEmpty ? .regular : .bold)
        titleField.textColor = item.title.isEmpty ? .secondaryLabelColor : .labelColor
        titleField.maximumNumberOfLines = 2
        titleField.lineBreakMode = .byTruncatingTail
        titleField.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleField)

        let snippetLabel = NSTextField(wrappingLabelWithString: item.snippet)
        snippetLabel.font = .systemFont(ofSize: 12, weight: .regular)
        snippetLabel.textColor = .secondaryLabelColor
        snippetLabel.maximumNumberOfLines = 2
        snippetLabel.lineBreakMode = .byTruncatingTail
        snippetLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(snippetLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cell.topAnchor, constant: 4),
            card.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -4),
            card.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
            card.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),

            dateLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            dateLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),

            titleField.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 3),
            titleField.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            titleField.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),

            snippetLabel.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 2),
            snippetLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            snippetLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            snippetLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -6)
        ])

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = table.selectedRow
        guard row >= 0 && row < sheets.count else { return }
        onSelectSheet?(sheets[row])
    }
}

// MARK: - Ulysses Suggestions View (Screenshot 2)

struct SpellingSuggestionItem {
    let word: String
    let range: NSRange
    let category: String
    let guesses: [String]
}

final class UlyssesSuggestionsView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    var allSuggestions: [SpellingSuggestionItem] = []
    var filteredSuggestions: [SpellingSuggestionItem] = []
    var selectedCategory: String = "All"

    var onSelectSuggestion: ((SpellingSuggestionItem) -> Void)?
    var onCopyAgentPrompt: (() -> Void)?
    var onRevealFolder: (() -> Void)?

    private let table = NSTableView()
    private let scrollView = NSScrollView()
    private let catAllBtn = NSButton()
    private let catSpellingBtn = NSButton()
    private let catCapBtn = NSButton()
    private let sectionTitle = NSTextField(labelWithString: "All")

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupView()
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    private func setupView() {
        let titleLabel = NSTextField(labelWithString: "Suggestions")
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Filter Category Buttons (All, Spelling, Capitalization)
        let filterStack = NSStackView()
        filterStack.orientation = .vertical
        filterStack.spacing = 3
        filterStack.alignment = .leading
        filterStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(filterStack)

        setupCategoryBtn(catAllBtn, title: "All", category: "All")
        setupCategoryBtn(catSpellingBtn, title: "Spelling", category: "Spelling")
        setupCategoryBtn(catCapBtn, title: "Capitalization", category: "Capitalization")

        filterStack.addArrangedSubview(catAllBtn)
        filterStack.addArrangedSubview(catSpellingBtn)
        filterStack.addArrangedSubview(catCapBtn)
        updateCategoryButtons()

        // Section Title
        sectionTitle.font = .systemFont(ofSize: 11, weight: .semibold)
        sectionTitle.textColor = .secondaryLabelColor
        sectionTitle.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sectionTitle)

        // Suggestions Table
        let col = NSTableColumn(identifier: .init("suggestion"))
        table.addTableColumn(col)
        table.headerView = nil
        table.rowHeight = 28
        table.backgroundColor = .clear
        table.dataSource = self
        table.delegate = self
        table.selectionHighlightStyle = .regular

        scrollView.documentView = table
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        // AI Agent Harness Card
        let agentCard = NSView()
        agentCard.wantsLayer = true
        if let l = agentCard.layer {
            l.cornerCurve = .continuous
            l.cornerRadius = LiquidGlass.smallCornerRadius
        }
        agentCard.translatesAutoresizingMaskIntoConstraints = false
        addSubview(agentCard)

        let agentHeader = NSTextField(labelWithString: "✦ AI Agent Assistant")
        agentHeader.font = .systemFont(ofSize: 12, weight: .bold)
        agentHeader.textColor = .labelColor
        agentHeader.translatesAutoresizingMaskIntoConstraints = false
        agentCard.addSubview(agentHeader)

        let agentDesc = NSTextField(wrappingLabelWithString: "Guide Antigravity or local agent to read the active file and generate inline annotations.")
        agentDesc.font = .systemFont(ofSize: 11, weight: .regular)
        agentDesc.textColor = .secondaryLabelColor
        agentDesc.translatesAutoresizingMaskIntoConstraints = false
        agentCard.addSubview(agentDesc)

        let copyBtn = NSButton(title: "Copy Prompt & Guide Agent", target: self, action: #selector(handleCopyPrompt))
        copyBtn.bezelStyle = .rounded
        copyBtn.font = .systemFont(ofSize: 11, weight: .medium)
        copyBtn.contentTintColor = .systemBlue
        copyBtn.translatesAutoresizingMaskIntoConstraints = false
        agentCard.addSubview(copyBtn)

        let revealBtn = NSButton(title: "Reveal in Finder", target: self, action: #selector(handleRevealFolder))
        revealBtn.bezelStyle = .rounded
        revealBtn.font = .systemFont(ofSize: 11, weight: .regular)
        revealBtn.contentTintColor = .secondaryLabelColor
        revealBtn.translatesAutoresizingMaskIntoConstraints = false
        agentCard.addSubview(revealBtn)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            filterStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            filterStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            filterStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            sectionTitle.topAnchor.constraint(equalTo: filterStack.bottomAnchor, constant: 14),
            sectionTitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            sectionTitle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            scrollView.topAnchor.constraint(equalTo: sectionTitle.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: agentCard.topAnchor, constant: -10),

            agentCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            agentCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            agentCard.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

            agentHeader.topAnchor.constraint(equalTo: agentCard.topAnchor, constant: 10),
            agentHeader.leadingAnchor.constraint(equalTo: agentCard.leadingAnchor, constant: 10),
            agentHeader.trailingAnchor.constraint(equalTo: agentCard.trailingAnchor, constant: -10),

            agentDesc.topAnchor.constraint(equalTo: agentHeader.bottomAnchor, constant: 4),
            agentDesc.leadingAnchor.constraint(equalTo: agentCard.leadingAnchor, constant: 10),
            agentDesc.trailingAnchor.constraint(equalTo: agentCard.trailingAnchor, constant: -10),

            copyBtn.topAnchor.constraint(equalTo: agentDesc.bottomAnchor, constant: 8),
            copyBtn.leadingAnchor.constraint(equalTo: agentCard.leadingAnchor, constant: 10),
            copyBtn.trailingAnchor.constraint(equalTo: agentCard.trailingAnchor, constant: -10),
            copyBtn.heightAnchor.constraint(equalToConstant: 26),

            revealBtn.topAnchor.constraint(equalTo: copyBtn.bottomAnchor, constant: 6),
            revealBtn.leadingAnchor.constraint(equalTo: agentCard.leadingAnchor, constant: 10),
            revealBtn.trailingAnchor.constraint(equalTo: agentCard.trailingAnchor, constant: -10),
            revealBtn.bottomAnchor.constraint(equalTo: agentCard.bottomAnchor, constant: -10),
            revealBtn.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func setupCategoryBtn(_ btn: NSButton, title: String, category: String) {
        btn.title = "  ○  \(title)"
        btn.target = self
        btn.action = #selector(categoryClicked(_:))
        btn.identifier = NSUserInterfaceItemIdentifier(category)
        btn.isBordered = false
        btn.alignment = .left
        btn.font = .systemFont(ofSize: 12, weight: .regular)
        btn.wantsLayer = true
        if let l = btn.layer {
            l.cornerCurve = .continuous
            l.cornerRadius = 6
        }
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 22).isActive = true
    }

    private func updateCategoryButtons() {
        for btn in [catAllBtn, catSpellingBtn, catCapBtn] {
            let cat = btn.identifier?.rawValue ?? ""
            let isSelected = cat == selectedCategory
            btn.title = isSelected ? "  ●  \(cat)" : "  ○  \(cat)"
            btn.contentTintColor = isSelected ? .systemBlue : .secondaryLabelColor
            btn.layer?.backgroundColor = isSelected ? NSColor.systemBlue.withAlphaComponent(0.12).cgColor : NSColor.clear.cgColor
        }
    }

    func updateSuggestions(_ list: [SpellingSuggestionItem]) {
        allSuggestions = list
        applyFilter()
    }

    private func applyFilter() {
        if selectedCategory == "All" {
            filteredSuggestions = allSuggestions
        } else {
            filteredSuggestions = allSuggestions.filter { $0.category == selectedCategory }
        }
        sectionTitle.stringValue = selectedCategory
        table.reloadData()
    }

    @objc private func handleCopyPrompt() { onCopyAgentPrompt?() }
    @objc private func handleRevealFolder() { onRevealFolder?() }

    @objc private func categoryClicked(_ sender: NSButton) {
        if let cat = sender.identifier?.rawValue {
            selectedCategory = cat
            updateCategoryButtons()
            applyFilter()
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int { filteredSuggestions.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < filteredSuggestions.count else { return nil }
        let item = filteredSuggestions[row]
        let cell = NSView()
        cell.wantsLayer = true

        let badge = NSTextField(labelWithString: "{\(item.word)}")
        badge.font = .systemFont(ofSize: 12, weight: .medium)
        badge.textColor = .systemBlue
        badge.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(badge)

        let catTag = NSTextField(labelWithString: item.category)
        catTag.font = .systemFont(ofSize: 10, weight: .regular)
        catTag.textColor = .tertiaryLabelColor
        catTag.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(catTag)

        NSLayoutConstraint.activate([
            badge.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
            badge.centerYAnchor.constraint(equalTo: cell.centerYAnchor),

            catTag.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
            catTag.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = table.selectedRow
        guard row >= 0 && row < filteredSuggestions.count else { return }
        onSelectSuggestion?(filteredSuggestions[row])
    }
}

// MARK: - Ulysses Inspector Dashboard (Column 4)

final class UlyssesInspector: NSView, NSTableViewDataSource, NSTableViewDelegate {
    var charCount: Int = 0
    var wordCount: Int = 0
    var readingTimeSec: Int = 0
    var headings: [(level: Int, text: String, location: Int)] = []
    var annotations: [Note] = []

    var onSelectHeading: ((Int) -> Void)?
    var onSelectAnnotation: ((Note) -> Void)?
    var onSelectSuggestion: ((SpellingSuggestionItem) -> Void)?
    var onCopyAgentPrompt: (() -> Void)?
    var onRevealFolder: (() -> Void)?

    private var tabButtons: [GlassCircleButton] = []
    private var selectedTabIndex: Int = 0

    private let dashboardStack = NSStackView()
    let suggestionsView = UlyssesSuggestionsView()

    private let outlineTable = NSTableView()
    private let annotationsTable = NSTableView()

    private let charVal = NSTextField(labelWithString: "0")
    private let wordVal = NSTextField(labelWithString: "0")
    private let avgVal = NSTextField(labelWithString: "0 sec")

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupView()
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    private func setupView() {
        // Top Icon Tab Bar (Screenshot 1 & 2)
        let tabStack = NSStackView()
        tabStack.orientation = .horizontal
        tabStack.spacing = 6
        tabStack.alignment = .centerY
        tabStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tabStack)

        let tabIcons = [
            ("square.grid.2x2", "Dashboard"),
            ("chart.line.uptrend.xyaxis", "Progress"),
            ("list.bullet.indent", "Outline"),
            ("tag", "Annotations"),
            ("bubble.left.and.bubble.right", "Comments"),
            ("sparkles", "Suggestions")
        ]

        for (idx, (icon, desc)) in tabIcons.enumerated() {
            let btn = GlassCircleButton(symbolName: icon, target: self, action: #selector(tabClicked(_:)), size: 26, accessibilityDescription: desc)
            btn.tag = idx
            tabButtons.append(btn)
            tabStack.addArrangedSubview(btn)
        }
        tabButtons.first?.isActive = true

        let tabDivider = NSBox()
        tabDivider.boxType = .separator
        tabDivider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tabDivider)

        // Dashboard Elements Container
        dashboardStack.orientation = .vertical
        dashboardStack.spacing = 16
        dashboardStack.alignment = .width
        dashboardStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dashboardStack)

        // Progress Box
        let progHeader = makeSectionHeader("Progress")
        let progBox = NSView()
        progBox.translatesAutoresizingMaskIntoConstraints = false
        progBox.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let cLabel = NSTextField(labelWithString: "Characters")
        let wLabel = NSTextField(labelWithString: "Words")
        let aLabel = NSTextField(labelWithString: "Average")
        for l in [cLabel, wLabel, aLabel] {
            l.font = .systemFont(ofSize: 12, weight: .regular)
            l.textColor = .secondaryLabelColor
        }

        for v in [charVal, wordVal, avgVal] {
            v.font = .systemFont(ofSize: 12, weight: .semibold)
            v.textColor = .labelColor
            v.alignment = .right
        }

        let leftCol = NSStackView(views: [cLabel, wLabel, aLabel])
        leftCol.orientation = .vertical; leftCol.spacing = 4; leftCol.alignment = .leading
        leftCol.translatesAutoresizingMaskIntoConstraints = false
        progBox.addSubview(leftCol)

        let rightCol = NSStackView(views: [charVal, wordVal, avgVal])
        rightCol.orientation = .vertical; rightCol.spacing = 4; rightCol.alignment = .trailing
        rightCol.translatesAutoresizingMaskIntoConstraints = false
        progBox.addSubview(rightCol)

        NSLayoutConstraint.activate([
            leftCol.leadingAnchor.constraint(equalTo: progBox.leadingAnchor, constant: 14),
            leftCol.topAnchor.constraint(equalTo: progBox.topAnchor),
            rightCol.trailingAnchor.constraint(equalTo: progBox.trailingAnchor, constant: -14),
            rightCol.topAnchor.constraint(equalTo: progBox.topAnchor)
        ])

        // Keywords
        let kwHeader = makeSectionHeader("Keywords")
        let addKwBtn = NSButton(title: "Add keyword", target: nil, action: nil)
        addKwBtn.bezelStyle = .inline
        addKwBtn.isBordered = false
        addKwBtn.font = .systemFont(ofSize: 12, weight: .regular)
        addKwBtn.contentTintColor = .secondaryLabelColor

        // Outline Box
        let outlineHeader = makeSectionHeader("Outline")
        let outlineScroll = NSScrollView()
        outlineScroll.hasVerticalScroller = true
        outlineScroll.drawsBackground = false
        outlineScroll.heightAnchor.constraint(equalToConstant: 110).isActive = true
        let oCol = NSTableColumn(identifier: .init("outline"))
        outlineTable.addTableColumn(oCol)
        outlineTable.headerView = nil
        outlineTable.rowHeight = 22
        outlineTable.backgroundColor = .clear
        outlineTable.dataSource = self
        outlineTable.delegate = self
        outlineScroll.documentView = outlineTable

        // Annotations Box
        let annHeader = makeSectionHeader("Annotations")
        let annScroll = NSScrollView()
        annScroll.hasVerticalScroller = true
        annScroll.drawsBackground = false
        annScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        let aCol = NSTableColumn(identifier: .init("annotation"))
        annotationsTable.addTableColumn(aCol)
        annotationsTable.headerView = nil
        annotationsTable.rowHeight = 26
        annotationsTable.backgroundColor = .clear
        annotationsTable.dataSource = self
        annotationsTable.delegate = self
        annScroll.documentView = annotationsTable

        dashboardStack.addArrangedSubview(progHeader)
        dashboardStack.addArrangedSubview(progBox)
        dashboardStack.addArrangedSubview(kwHeader)
        dashboardStack.addArrangedSubview(addKwBtn)
        dashboardStack.addArrangedSubview(outlineHeader)
        dashboardStack.addArrangedSubview(outlineScroll)
        dashboardStack.addArrangedSubview(annHeader)
        dashboardStack.addArrangedSubview(annScroll)

        // Suggestions View
        suggestionsView.translatesAutoresizingMaskIntoConstraints = false
        suggestionsView.isHidden = true
        addSubview(suggestionsView)

        suggestionsView.onSelectSuggestion = { [weak self] item in
            self?.onSelectSuggestion?(item)
        }
        suggestionsView.onCopyAgentPrompt = { [weak self] in
            self?.onCopyAgentPrompt?()
        }
        suggestionsView.onRevealFolder = { [weak self] in
            self?.onRevealFolder?()
        }

        NSLayoutConstraint.activate([
            tabStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            tabStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            tabStack.heightAnchor.constraint(equalToConstant: 32),

            tabDivider.topAnchor.constraint(equalTo: tabStack.bottomAnchor, constant: 8),
            tabDivider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            tabDivider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            tabDivider.heightAnchor.constraint(equalToConstant: 1),

            dashboardStack.topAnchor.constraint(equalTo: tabDivider.bottomAnchor, constant: 12),
            dashboardStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            dashboardStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            dashboardStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16),

            suggestionsView.topAnchor.constraint(equalTo: tabDivider.bottomAnchor),
            suggestionsView.leadingAnchor.constraint(equalTo: leadingAnchor),
            suggestionsView.trailingAnchor.constraint(equalTo: trailingAnchor),
            suggestionsView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func tabClicked(_ sender: GlassCircleButton) {
        selectTab(sender.tag)
    }

    func selectTab(_ index: Int) {
        selectedTabIndex = index
        for (i, btn) in tabButtons.enumerated() {
            btn.isActive = (i == index)
        }
        if index == 5 {
            suggestionsView.isHidden = false
            dashboardStack.isHidden = true
        } else {
            suggestionsView.isHidden = true
            dashboardStack.isHidden = false
        }
    }

    func scanDocumentText(_ text: String) {
        let spellChecker = NSSpellChecker.shared
        let nsText = text as NSString
        var offset = 0
        var items: [SpellingSuggestionItem] = []

        // Check text with NSSpellChecker
        var count = 0
        while offset < nsText.length && count < 50 {
            let misspelledRange = spellChecker.checkSpelling(of: text, startingAt: offset)
            if misspelledRange.location == NSNotFound || misspelledRange.length == 0 {
                break
            }
            let word = nsText.substring(with: misspelledRange)
            let isCap = word.first?.isLowercase == true && (misspelledRange.location == 0 || nsText.substring(with: NSRange(location: max(0, misspelledRange.location - 2), length: min(2, misspelledRange.location))).contains("."))
            let cat = isCap ? "Capitalization" : "Spelling"
            items.append(SpellingSuggestionItem(word: word, range: misspelledRange, category: cat, guesses: []))
            offset = misspelledRange.location + misspelledRange.length
            count += 1
        }

        // Also detect curly-brace annotations like {âss} or {âss|...}
        let pattern = #"\{([^{}|\n]+)(?:\|[^{}\n]*)?\}"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in matches {
                let wordRange = match.range(at: 1)
                if wordRange.location != NSNotFound {
                    let rawWord = nsText.substring(with: wordRange)
                    if !items.contains(where: { $0.word == rawWord }) {
                        items.append(SpellingSuggestionItem(word: rawWord, range: match.range, category: "Spelling", guesses: []))
                    }
                }
            }
        }

        suggestionsView.updateSuggestions(items)
    }

    private func makeSectionHeader(_ title: String) -> NSTextField {
        let tf = NSTextField(labelWithString: title)
        tf.font = .systemFont(ofSize: 11, weight: .medium)
        tf.textColor = .secondaryLabelColor
        return tf
    }

    func updateMetrics(chars: Int, words: Int) {
        charCount = chars
        wordCount = words
        readingTimeSec = Int(ceil(Double(words) / 200.0 * 60.0))
        charVal.stringValue = "\(chars)"
        wordVal.stringValue = "\(words)"
        avgVal.stringValue = readingTimeSec < 60 ? "\(readingTimeSec) sec" : "\(readingTimeSec / 60) min"
    }

    func updateHeadings(_ list: [(level: Int, text: String, location: Int)]) {
        headings = list
        outlineTable.reloadData()
    }

    func updateAnnotations(_ list: [Note]) {
        annotations = list
        annotationsTable.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView === outlineTable {
            return headings.count
        } else {
            return annotations.count
        }
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = NSView()
        cell.wantsLayer = true

        let icon = NSImageView()
        if let img = NSImage(systemSymbolName: "circle", accessibilityDescription: nil) {
            icon.image = img
        }
        icon.contentTintColor = .tertiaryLabelColor
        icon.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(icon)

        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(label)

        if tableView === outlineTable {
            let h = headings[row]
            label.stringValue = h.text
        } else {
            let note = annotations[row]
            let display = note.body.isEmpty ? note.label : note.body
            label.stringValue = display
        }

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 10),
            icon.heightAnchor.constraint(equalToConstant: 10),

            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tv = notification.object as? NSTableView {
            let row = tv.selectedRow
            if tv === outlineTable, row >= 0 && row < headings.count {
                onSelectHeading?(headings[row].location)
            } else if tv === annotationsTable, row >= 0 && row < annotations.count {
                onSelectAnnotation?(annotations[row])
            }
        }
    }
}
