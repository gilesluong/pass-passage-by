import Cocoa

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
            let quote = button(note.quote, #selector(revealDiscussion(_:)))
            quote.identifier = NSUserInterfaceItemIdentifier(note.id)
            quote.isBordered = false
            quote.alignment = .left
            quote.cell?.wraps = true
            quote.cell?.lineBreakMode = .byTruncatingTail
            quote.heightAnchor.constraint(equalToConstant: 38).isActive = true
            quote.toolTip = "Show passage and edit comment"
            let body = NSTextField(wrappingLabelWithString: note.body)
            body.font = .systemFont(ofSize: 13)
            let edit = button("Edit comment", #selector(revealDiscussion(_:)))
            edit.identifier = NSUserInterfaceItemIdentifier(note.id)
            let entry = stack([quote, body, edit], vertical: true)
            entry.alignment = .leading
            list.addArrangedSubview(entry)
            entry.widthAnchor.constraint(equalTo: list.widthAnchor).isActive = true
            body.widthAnchor.constraint(equalTo: entry.widthAnchor).isActive = true
            quote.widthAnchor.constraint(equalTo: entry.widthAnchor).isActive = true
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
