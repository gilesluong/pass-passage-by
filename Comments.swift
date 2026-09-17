import Cocoa

/// Rounded quiet surface for a single inspector comment card.
final class CommentCardSurface: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let dark = LiquidGlass.isDark(for: self)
        let path = NSBezierPath(roundedRect: bounds, xRadius: 10, yRadius: 10)
        LiquidGlass.cardBackground(isDark: dark).setFill()
        path.fill()
        NSColor.separatorColor.withAlphaComponent(0.6).setStroke()
        path.stroke()
    }
}

extension Passage {
    var notePresentation: NotePresentation { NotePresentation(defaults: prefs) }

    func isDiscussion(_ note: Note) -> Bool {
        notePresentation.surface(documentID: data.document.id, noteID: note.id) == .comment
    }

    @objc func toggleComments() {
        if commentsVisible {
            closeComment()
            commentsVisible = false
        } else {
            commentsVisible = true
            renderComments()
        }
        adaptLayout()
        renderNotes()
    }

    func renderComments() {
        guard !commentsEditing else { return }
        commentsPane.subviews.forEach { $0.removeFromSuperview() }
        let heading = NSTextField(labelWithString: "Comments")
        heading.font = .systemFont(ofSize: 16, weight: .semibold)
        let close = button("Close comments", #selector(toggleComments), symbol: "xmark")
        let headerRow = stack([heading, close])
        headerRow.distribution = .equalSpacing
        let list = stack([], vertical: true)
        list.alignment = .leading
        list.spacing = 16
        let notes = displayedNotes.filter { isDiscussion($0) }.sorted { $0.start < $1.start }
        if notes.isEmpty {
            let empty = NSTextField(wrappingLabelWithString: "Select text and press ⌥⌘M to add feedback. Existing margin notes stay in place until you move them here.")
            empty.textColor = .secondaryLabelColor
            list.addArrangedSubview(empty)
            empty.widthAnchor.constraint(equalTo: list.widthAnchor).isActive = true
        }
        for note in notes {
            let card = CommentCardSurface()
            let tag = NSTextField(labelWithString:"💬  " + note.label)
            tag.font = .systemFont(ofSize: 12, weight: .semibold)
            tag.textColor = noteColor(note)
            let edit = button("Edit", #selector(revealDiscussion(_:)))
            edit.identifier = NSUserInterfaceItemIdentifier(note.id)
            edit.isBordered = false
            edit.font = .systemFont(ofSize: 11)
            edit.contentTintColor = .secondaryLabelColor
            let headerRow = stack([tag, edit])
            headerRow.distribution = .equalSpacing
            let accent = NSBox();accent.boxType = .custom;accent.borderWidth = 0;accent.fillColor = noteColor(note);accent.cornerRadius = 1.5;accent.contentViewMargins = NSSize(width: 0, height: 0)
            let quote = button(note.quote, #selector(revealDiscussion(_:)))
            quote.identifier = NSUserInterfaceItemIdentifier(note.id)
            quote.isBordered = false
            quote.alignment = .left
            quote.font = .systemFont(ofSize: 12)
            quote.contentTintColor = .secondaryLabelColor
            quote.cell?.wraps = true
            quote.cell?.lineBreakMode = .byTruncatingTail
            quote.toolTip = "Show passage and edit comment"
            let quoteRow = stack([accent, quote])
            quoteRow.alignment = .top
            quoteRow.spacing = 8
            let body = NSTextField(wrappingLabelWithString: note.body)
            body.font = .systemFont(ofSize: 13)
            let entry = stack([headerRow, quoteRow, body], vertical: true)
            entry.alignment = .leading
            entry.spacing = 6
            card.addSubview(entry)
            entry.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                entry.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
                entry.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
                entry.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
                entry.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
                accent.widthAnchor.constraint(equalToConstant: 3),
                quoteRow.widthAnchor.constraint(equalTo: entry.widthAnchor),
                quote.widthAnchor.constraint(equalTo: quoteRow.widthAnchor, constant: -11),
                body.widthAnchor.constraint(equalTo: entry.widthAnchor)
            ])
            list.addArrangedSubview(card)
            card.widthAnchor.constraint(equalTo: list.widthAnchor).isActive = true
        }
        let listScroll = NSScrollView()
        listScroll.hasVerticalScroller = true
        listScroll.drawsBackground = false
        let canvas = MarginCanvas()
        listScroll.documentView = canvas
        canvas.translatesAutoresizingMaskIntoConstraints = false
        attach(list, to: canvas, inset: 12)
        canvas.widthAnchor.constraint(equalTo: listScroll.contentView.widthAnchor).isActive = true
        let content = stack([headerRow, listScroll], vertical: true)
        content.alignment = .leading
        attach(content, to: commentsPane, inset: 12)
        headerRow.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
        listScroll.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
    }

    @objc func revealDiscussion(_ sender: NSButton) {
        guard let note = displayedNotes.first(where: { $0.id == sender.identifier?.rawValue }) else { return }
        focus = note.start
        level = 0
        render()
        let local = NSRange(location: note.start - visible.location, length: note.end - note.start)
        editor.setSelectedRange(local)
        editor.scrollRangeToVisible(local)
        openCommentPopover(existing: note, targetRect: .zero, view: editor)
    }

    @objc func moveNoteSurface() {
        guard let id = editingNoteId,
              let note = displayedNotes.first(where: { $0.id == id }) else { return }
        let destination: NoteSurface = isDiscussion(note) ? .annotation : .comment
        notePresentation.set(destination, documentID: data.document.id, noteID: id)
        closeComment()
        commentsVisible = destination == .comment
        renderNotes()
        adaptLayout()
    }

    func installCommentEditor(_ view: NSView) {
        commentsEditing = true
        commentsVisible = true
        commentsPane.subviews.forEach { $0.removeFromSuperview() }
        let content = stack([button("Back to comments", #selector(closeComment)), view], vertical: true)
        content.alignment = .leading
        content.translatesAutoresizingMaskIntoConstraints = false
        commentsPane.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: commentsPane.topAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: commentsPane.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: commentsPane.trailingAnchor, constant: -12)
        ])
        view.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
        adaptLayout()
        renderNotes()
        window.makeFirstResponder(commentField)
    }
}
