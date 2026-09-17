import Cocoa
import PDFKit

final class ExportPage:NSView {
    override var isFlipped:Bool {true}
    let drawContent:()->Void
    init(draw:@escaping ()->Void){drawContent = draw;super.init(frame:NSRect(x:0,y:0,width:960,height:1120))}
    @available(*, unavailable)
    required init?(coder:NSCoder){fatalError("This view is created programmatically")}
    override func draw(_ dirtyRect:NSRect){NSColor.white.setFill();bounds.fill();drawContent()}
}
func annotatedPDF(_ document:Breakdown,surfaces:[String:NoteSurface] = [:])->PDFDocument {
    let result = PDFDocument()
    let text = document.document.text as NSString
    let storage = NSTextStorage(string:document.document.text,attributes:[.font:NSFont(name:"Georgia",size:17) ?? NSFont.systemFont(ofSize:17),.foregroundColor:NSColor.black])
    let style = NSMutableParagraphStyle();style.lineSpacing = 7;style.paragraphSpacing = 16
    storage.addAttribute(.paragraphStyle,value:style,range:NSRange(location:0,length:storage.length))
    let manager = NSLayoutManager();storage.addLayoutManager(manager)
    let notes = PassageMarkup.orderedNotes(document.document.text,existing:document.annotations)
    let marginNotes = notes.filter {surfaces[$0.id] != .comment}
    let commentNotes = notes.filter {surfaces[$0.id] == .comment}
    for note in notes {
        let comment = surfaces[note.id] == .comment
        storage.addAttributes([.underlineStyle:NSUnderlineStyle.single.rawValue,.underlineColor:comment ? NSColor.systemPurple : NSColor.systemBlue],range:NSRange(location:note.start,length:note.end - note.start))
    }
    var previous = 0
    repeat {
        let container = NSTextContainer(containerSize:NSSize(width:490,height:920));container.lineFragmentPadding = 0;manager.addTextContainer(container)
        let glyphs = manager.glyphRange(for:container)
        let chars = manager.characterRange(forGlyphRange:glyphs,actualGlyphRange:nil)
        let pageNumber = result.pageCount + 1
        let view = ExportPage {
            let documentTitle = document.document.title as NSString
            documentTitle.draw(at:NSPoint(x:235,y:45),withAttributes:[.font:NSFont.systemFont(ofSize:19,weight:.semibold),.foregroundColor:NSColor.black])
            manager.drawBackground(forGlyphRange:glyphs,at:NSPoint(x:235,y:110));manager.drawGlyphs(forGlyphRange:glyphs,at:NSPoint(x:235,y:110))
            var bottoms:[Bool:CGFloat] = [true:110,false:110]
            for note in marginNotes where NSIntersectionRange(chars,NSRange(location:note.start,length:note.end - note.start)).length > 0 {
                let left = note.side == "left"
                let intersection = NSIntersectionRange(chars,NSRange(location:note.start,length:note.end - note.start))
                let range = manager.glyphRange(forCharacterRange:intersection,actualCharacterRange:nil)
                let anchor = manager.boundingRect(forGlyphRange:range,in:container)
                let y = max(bottoms[left] ?? 110,anchor.minY + 110)
                let x:CGFloat = left ? 25 : 755
                let content = note.label + "\n" + note.body + (note.suggestion.map{"\nSuggested: " + $0} ?? "")
                let attrs:[NSAttributedString.Key:Any] = [.font:NSFont.systemFont(ofSize:11),.foregroundColor:NSColor.black]
                let size = (content as NSString).boundingRect(with:NSSize(width:180,height:10000),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:attrs).size
                // Reserve enough vertical room by scaling a dense note locally, never moving essay text.
                let height = min(size.height,1000 - y)
                let shown = size.height > height ? note.label + " — see Annotation details" : content
                if height > 25 {(shown as NSString).draw(in:NSRect(x:x,y:y,width:180,height:max(0,height)),withAttributes:attrs)}
                let path = NSBezierPath();path.move(to:NSPoint(x:left ? 215 : 745,y:y + 5));path.line(to:NSPoint(x:left ? 231 : 729,y:anchor.minY + 115));NSColor.systemBlue.setStroke();path.stroke()
                bottoms[left] = y + size.height + 22
            }
            ("Pass Passage By! · \(pageNumber)" as NSString).draw(at:NSPoint(x:420,y:1070),withAttributes:[.font:NSFont.systemFont(ofSize:10),.foregroundColor:NSColor.gray])
        }
        if let pdf = PDFDocument(data:view.dataWithPDF(inside:view.bounds)),let page = pdf.page(at:0){result.insert(page,at:result.pageCount)}
        if NSMaxRange(glyphs) <= previous{break};previous = NSMaxRange(glyphs)
    } while previous < manager.numberOfGlyphs && text.length > 0
    if !marginNotes.isEmpty {
        let details = marginNotes.enumerated().map { index,n in "\(index + 1). \(n.label)\n“\(n.quote)”\n\(n.body)" + (n.suggestion.map{"\nSuggested: " + $0} ?? "") }.joined(separator:"\n\n")
        let appendix = annotatedPDF(.plain(details,title:"Annotation details"))
        for index in 0..<appendix.pageCount {if let page = appendix.page(at:index){result.insert(page,at:result.pageCount)}}
    }
    if !commentNotes.isEmpty {
        let details = commentNotes.enumerated().map { index,n in "💬 \(index + 1). \(n.label)\n“\(n.quote)”\n\(n.body)" }.joined(separator:"\n\n")
        let appendix = annotatedPDF(.plain(details,title:"Comments · feedback & discussion"))
        for index in 0..<appendix.pageCount {if let page = appendix.page(at:index){result.insert(page,at:result.pageCount)}}
    }
    for image in document.images ?? [] {if let native = NSImage(data:image.data),let page = PDFPage(image:native){result.insert(page,at:result.pageCount)}}
    return result
}

extension Passage {
    var commentSurfaces:[String:NoteSurface] {
        var map:[String:NoteSurface] = [:]
        for note in data.annotations where isDiscussion(note) {map[note.id] = .comment}
        return map
    }

    @objc func showSharePreview(){
        guard opened else{return}
        saveDraft()
        let pdf = annotatedPDF(data,surfaces:commentSurfaces)
        let controller = ShareController(document:data,pdf:pdf,surfaces:commentSurfaces)
        shareController = controller;controller.showWindow(nil);controller.window?.center()
    }

    /// Reopen an exported bundle folder (essay.md + annotations.json + optional presentation.json).
    func importWritingBundle(_ folder:URL)throws {
        let annotations = folder.appendingPathComponent("annotations.json")
        guard FileManager.default.fileExists(atPath:annotations.path) else {throw ModelError.invalid}
        if opened {saveDraft()}
        try loadJSON(try Data(contentsOf:annotations))
        let presentation = folder.appendingPathComponent("presentation.json")
        if let bytes = try? Data(contentsOf:presentation),
           let payload = try? JSONSerialization.jsonObject(with:bytes) as? [String:Any],
           (payload["format"] as? String) == "ppb-note-surfaces/v1",
           let map = payload["surfaces"] as? [String:String] {
            for (noteID,raw) in map where raw == NoteSurface.comment.rawValue {
                notePresentation.set(.comment,documentID:data.document.id,noteID:noteID)
            }
        }
        NSDocumentController.shared.noteNewRecentDocumentURL(annotations)
        openWorkspace()
    }
}
final class ShareController:NSWindowController {
    let essay:Breakdown;let pdf:PDFDocument
    let surfaces:[String:NoteSurface]
    var sharingPicker:NSSharingServicePicker?
    let preview = PDFView();let format = NSPopUpButton()
    init(document:Breakdown,pdf:PDFDocument,surfaces:[String:NoteSurface] = [:]){
        self.essay = document;self.pdf = pdf;self.surfaces = surfaces
        let window = NSWindow(contentRect:NSRect(x:0,y:0,width:920,height:780),styleMask:[.titled,.closable,.resizable],backing:.buffered,defer:false)
        super.init(window:window);window.title = "Share · " + document.document.title;window.isReleasedWhenClosed = false
        format.addItems(withTitles:["PDF · with annotations","Markdown + JSON"])
        let export = NSButton(title:"Export…",target:self,action:#selector(exportDocument))
        let share = NSButton(title:"Share…",target:self,action:#selector(shareDocument(_:)))
        let bar = NSStackView(views:[format,export,share]);bar.spacing = 12
        preview.document = pdf;preview.autoScales = true;preview.displayMode = .singlePageContinuous
        let all = NSStackView(views:[bar,preview]);all.orientation = .vertical;all.alignment = .width;all.spacing = 12;all.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView();content.addSubview(all);window.contentView = content
        NSLayoutConstraint.activate([all.leadingAnchor.constraint(equalTo:content.leadingAnchor,constant:16),all.trailingAnchor.constraint(equalTo:content.trailingAnchor,constant:-16),all.topAnchor.constraint(equalTo:content.topAnchor,constant:16),all.bottomAnchor.constraint(equalTo:content.bottomAnchor,constant:-16)])
    }
    @available(*, unavailable)
    required init?(coder:NSCoder){fatalError("This view is created programmatically")}
    func write(to url:URL)throws {
        if format.indexOfSelectedItem == 0 {guard let bytes = pdf.dataRepresentation() else{throw ModelError.invalid};try bytes.write(to:url,options:.atomic)}
        else {
            try FileManager.default.createDirectory(at:url,withIntermediateDirectories:false)
            try Data(essay.document.text.utf8).write(to:url.appendingPathComponent("essay.md"),options:.atomic)
            let encoder = JSONEncoder();encoder.outputFormatting = [.prettyPrinted,.sortedKeys]
            try encoder.encode(essay).write(to:url.appendingPathComponent("annotations.json"),options:.atomic)
            let commentIDs = essay.annotations.filter {surfaces[$0.id] == .comment}.map {$0.id}
            if !commentIDs.isEmpty {
                let payload:[String:Any] = ["format":"ppb-note-surfaces/v1","document":essay.document.id,"surfaces":Dictionary(uniqueKeysWithValues:commentIDs.map{($0,NoteSurface.comment.rawValue)})]
                try JSONSerialization.data(withJSONObject:payload,options:[.prettyPrinted,.sortedKeys]).write(to:url.appendingPathComponent("presentation.json"),options:.atomic)
            }
        }
    }
    @objc func exportDocument(){let panel = NSSavePanel();panel.nameFieldStringValue = format.indexOfSelectedItem == 0 ? essay.document.title + ".pdf" : essay.document.title + "-bundle";panel.beginSheetModal(for:window ?? NSWindow()){response in guard response == .OK,let url = panel.url else{return};do{try self.write(to:url)}catch{NSAlert(error:error).runModal()}}}
    @objc func shareDocument(_ sender:NSButton){do{let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);let url = directory.appendingPathComponent(format.indexOfSelectedItem == 0 ? "Essay.pdf" : "Essay-bundle");try write(to:url);let picker = NSSharingServicePicker(items:[url]);sharingPicker = picker;picker.show(relativeTo:sender.bounds,of:sender,preferredEdge:.minY)}catch{NSAlert(error:error).runModal()}}
}
