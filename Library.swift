import Cocoa
import CryptoKit
struct WritingRecord {let url:URL;let document:Breakdown;let modified:Date}
enum LibraryStore {
    static func save(_ document:Breakdown,to folder:URL)throws {
        try document.validate();try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        let name = SHA256.hash(data:Data(document.document.id.utf8)).map{String(format:"%02x",$0)}.joined()
        try JSONEncoder().encode(document).write(to:folder.appendingPathComponent(name + ".json"),options:.atomic)
    }
    static func records(in folder:URL)->[WritingRecord] {
        var seen = Set<String>()
        return ((try? FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:[.contentModificationDateKey])) ?? []).compactMap {url in
            guard url.pathExtension == "json",let bytes = try? Data(contentsOf:url),let document = try? JSONDecoder().decode(Breakdown.self,from:bytes) else{return nil}
            return WritingRecord(url:url,document:document,modified:(try? url.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
        }.sorted{$0.modified > $1.modified}.filter{seen.insert($0.document.document.id).inserted}
    }
}
final class WritingLibrary:NSWindowController,NSTableViewDataSource,NSTableViewDelegate,NSSearchFieldDelegate {
    weak var passage:Passage?
    var records:[WritingRecord] = []
    var allRecords:[WritingRecord] = []
    let table = NSTableView(),preview = NSTextView()
    let searchField = NSSearchField()
    let pin = NSButton()
    init(passage:Passage){
        self.passage = passage
        allRecords = LibraryStore.records(in:passage.saveURL.deletingLastPathComponent().appendingPathComponent("Library"))
        records = allRecords
        let panel = NSWindow(contentRect:NSRect(x:0,y:0,width:900,height:620),styleMask:[.titled,.closable,.resizable],backing:.buffered,defer:false);panel.title = "My writing (Notes)";panel.minSize = NSSize(width:860,height:460)
        super.init(window:panel)
        let root = NSView();panel.contentView = root
        let split = NSSplitView(frame:NSRect(x:0,y:0,width:900,height:550));split.isVertical = true;split.dividerStyle = .thin
        let list = NSScrollView(frame:NSRect(x:0,y:0,width:300,height:550)),content = NSScrollView(frame:NSRect(x:301,y:0,width:599,height:550));list.hasVerticalScroller = true;content.hasVerticalScroller = true
        let column = NSTableColumn(identifier:.init("writing"));column.title = "All writing";column.width = 290;table.addTableColumn(column);table.headerView = nil;table.rowHeight = 76;table.dataSource = self;table.delegate = self;table.target = self;table.doubleAction = #selector(openSelected);list.documentView = table
        preview.frame = NSRect(x:0,y:0,width:560,height:520);preview.isEditable = false;preview.font = NSFont(name:"Georgia",size:18);preview.textContainerInset = NSSize(width:24,height:24);preview.isVerticallyResizable = true;preview.autoresizingMask = [.width];preview.textContainer?.widthTracksTextView = true;content.documentView = preview
        split.addArrangedSubview(list);split.addArrangedSubview(content)
        searchField.placeholderString = "Search notes…"
        searchField.delegate = self
        searchField.widthAnchor.constraint(equalToConstant:150).isActive = true
        let open = NSButton(title:"Open writing",target:self,action:#selector(openSelected));open.bezelStyle = .rounded
        let del = NSButton(title:"Delete",target:self,action:#selector(deleteSelected));del.bezelStyle = .rounded
        let new = passage.button("New Sheet",#selector(Passage.newEssay)),scan = passage.button("Scan document…",#selector(Passage.captureDocument))
        pin.title = "Pin to Home";pin.target = self;pin.action = #selector(pinSelected(_:));pin.bezelStyle = .rounded
        let bar = passage.stack([new,scan,del,open,pin,searchField]);root.addSubview(bar);root.addSubview(split);bar.translatesAutoresizingMaskIntoConstraints = false;split.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([bar.leadingAnchor.constraint(equalTo:root.leadingAnchor,constant:16),bar.topAnchor.constraint(equalTo:root.topAnchor,constant:12),bar.trailingAnchor.constraint(lessThanOrEqualTo:root.trailingAnchor,constant:-16),split.topAnchor.constraint(equalTo:bar.bottomAnchor,constant:12),split.leadingAnchor.constraint(equalTo:root.leadingAnchor),split.trailingAnchor.constraint(equalTo:root.trailingAnchor),split.bottomAnchor.constraint(equalTo:root.bottomAnchor)])
        split.setPosition(300,ofDividerAt:0);table.reloadData()
        if records.isEmpty {preview.string = "Your writing lives here.\n\nCreate a sheet or scan a page to begin. Changes are saved automatically on this Mac."}else{table.selectRowIndexes(IndexSet(integer:0),byExtendingSelection:false);updatePreview()}
    }
    @available(*, unavailable)
    required init?(coder:NSCoder){fatalError("This view is created programmatically")}
    func controlTextDidChange(_ obj:Notification){
        let q = searchField.stringValue.trimmingCharacters(in:.whitespacesAndNewlines).lowercased()
        records = q.isEmpty ? allRecords : allRecords.filter{$0.document.document.title.lowercased().contains(q) || $0.document.document.text.lowercased().contains(q)}
        table.reloadData()
        if !records.isEmpty {table.selectRowIndexes(IndexSet(integer:0),byExtendingSelection:false)}
        updatePreview()
    }
    func numberOfRows(in tableView:NSTableView)->Int {records.count}
    func tableView(_ tableView:NSTableView,viewFor tableColumn:NSTableColumn?,row:Int)->NSView? {
        let record = records[row]
        let cell = NSView()
        let titleLabel = NSTextField(labelWithString:record.document.document.title)
        titleLabel.font = .systemFont(ofSize:14,weight:.semibold)
        let df = DateFormatter();df.dateStyle = .short;df.timeStyle = .short
        let timeStr = df.string(from:record.modified)
        let snippet = String(record.document.document.text.prefix(60)).replacingOccurrences(of:"\n",with:" ")
        let subLabel = NSTextField(wrappingLabelWithString:"\(timeStr)  ·  \(snippet)")
        subLabel.font = .systemFont(ofSize:12)
        subLabel.textColor = .secondaryLabelColor
        subLabel.maximumNumberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(titleLabel);cell.addSubview(subLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo:cell.topAnchor,constant:6),
            titleLabel.leadingAnchor.constraint(equalTo:cell.leadingAnchor,constant:8),
            titleLabel.trailingAnchor.constraint(equalTo:cell.trailingAnchor,constant:-8),
            subLabel.topAnchor.constraint(equalTo:titleLabel.bottomAnchor,constant:4),
            subLabel.leadingAnchor.constraint(equalTo:cell.leadingAnchor,constant:8),
            subLabel.trailingAnchor.constraint(equalTo:cell.trailingAnchor,constant:-8),
            subLabel.bottomAnchor.constraint(lessThanOrEqualTo:cell.bottomAnchor,constant:-4)
        ])
        return cell
    }
    func tableViewSelectionDidChange(_ notification:Notification){updatePreview()}
    func updatePreview(){
        pin.isEnabled = records.indices.contains(table.selectedRow)
        guard records.indices.contains(table.selectedRow) else{
            preview.string = allRecords.isEmpty ? "Your writing lives here.\n\nCreate a sheet or scan a page to begin. Changes are saved automatically on this Mac." : "No note selected."
            return
        }
        let d = records[table.selectedRow].document
        pin.title = (passage?.prefs.stringArray(forKey:"showcaseIDs") ?? []).contains(d.document.id) ? "Unpin from Home" : "Pin to Home"
        preview.string = d.document.title + "\n\n" + d.document.text
    }
    @objc func deleteSelected(){
        guard records.indices.contains(table.selectedRow) else{return}
        let url = records[table.selectedRow].url
        do {try FileManager.default.trashItem(at:url,resultingItemURL:nil)}catch{passage?.showAlert(error.localizedDescription);return}
        allRecords.removeAll{$0.url == url}
        records.removeAll{$0.url == url}
        table.reloadData()
        if !records.isEmpty {table.selectRowIndexes(IndexSet(integer:0),byExtendingSelection:false)}
        updatePreview()
    }
    @objc func pinSelected(_ sender:NSButton){
        guard let passage = passage,records.indices.contains(table.selectedRow) else{return}
        let id = records[table.selectedRow].document.document.id
        var ids = passage.prefs.stringArray(forKey:"showcaseIDs") ?? []
        if ids.contains(id){ids.removeAll{$0 == id};sender.title = "Pin to Home"}else{ids.append(id);sender.title = "Unpin from Home"}
        passage.prefs.set(ids,forKey:"showcaseIDs")
    }
    @objc func openSelected(){guard let passage = passage,records.indices.contains(table.selectedRow) else{return};do{if passage.opened {passage.saveDraft()};try passage.loadJSON(Data(contentsOf:records[table.selectedRow].url));passage.openWorkspace();close()}catch{passage.showAlert(error.localizedDescription)}}
}
extension Passage {
    @objc func showWritingLibrary(){if opened {saveDraft()};let library = WritingLibrary(passage:self);writingLibrary = library;library.window?.center();library.showWindow(nil)}
}
