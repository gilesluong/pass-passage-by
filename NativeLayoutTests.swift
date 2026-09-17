import Cocoa
import PDFKit
final class TestPassage:Passage {
    override var resourceDirectory:URL {URL(fileURLWithPath:FileManager.default.currentDirectoryPath)}
    override func saveDraft() {} // Never write the user's draft during layout tests.
}
@main struct NativeLayoutTests {
    static func render(_ view:NSView,to path:String)throws {
        let pdf=PDFDocument(data:view.dataWithPDF(inside:view.bounds))!
        let image=pdf.page(at:0)!.thumbnail(of:view.bounds.size,for:.mediaBox)
        try NSBitmapImageRep(data:image.tiffRepresentation!)!.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:path))
    }
    static func main() throws {
        _ = NSApplication.shared
        let app=TestPassage()
        let name="ppb-layout-test-"+UUID().uuidString
        let prefs=UserDefaults(suiteName:name)!
        defer {prefs.removePersistentDomain(forName:name)}
        app.prefs=prefs
        prefs.register(defaults:["size":22.0,"spacing":1.5,"lineWidth":820.0,"paragraphSpacing":32.0,"notes":true,"briefSize":19.0,"font":"Georgia","theme":"Paper"])
        app.window=NSWindow(contentRect:NSRect(x:0,y:0,width:1200,height:800),styleMask:[.titled,.resizable],backing:.buffered,defer:false)
        app.applyAppearance() // Verify pre-root appearance safety without launching UI or Sparkle.
        app.data=try JSONDecoder().decode(Breakdown.self,from:Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1])))
        app.openWorkspace()
        app.root.layoutSubtreeIfNeeded();app.refreshTaskBrief();app.root.layoutSubtreeIfNeeded();app.updateConnectors()
        try render(app.root,to:"/tmp/ppb-task-layout.png")
        for _ in 0..<4 {
            app.root.layoutSubtreeIfNeeded();app.updateConnectors()
            precondition(!app.connectorView.connections.isEmpty,"Visible annotations must retain connectors")
            for line in app.connectorView.connections {precondition(app.connectorView.bounds.contains(line.endPoint),"Connector must stay inside essay viewport")}
            let original=app.data.document.text
            app.toggleTaskBrief();app.root.layoutSubtreeIfNeeded();app.updateConnectors()
            precondition(app.data.document.text==original,"Toggling the task cannot change essay anchors")
            if app.briefHidden { precondition(app.taskBrief.isHidden && app.taskBriefHeight?.constant == 0) }
            let toggle = app.briefToggleButton!
            let toggleRect = app.root.convert(toggle.bounds, from: toggle)
            precondition(abs(toggleRect.midX - app.root.bounds.midX) < 2, "Task chevron must be centered")
            for canvas in [app.leftNotes,app.rightNotes] {
                for card in canvas.subviews where !card.isHidden {
                    precondition(card.frame.maxX <= canvas.bounds.width)
                    for child in card.subviews {precondition(child.frame.maxX <= card.bounds.width)}
                }
            }
        }
        app.setLevel(3)
        app.root.layoutSubtreeIfNeeded()
        precondition(!app.dictionaryPane.isHidden, "Dictionary pane must be visible in word level")
        let entries = app.fetchDictionaryEntries(word: "food", tab: 0)
        precondition(!entries.isEmpty, "Dictionary entries for 'food' must be found")
        app.lookupWord("food")
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        app.root.layoutSubtreeIfNeeded()
        precondition(app.definition.string.contains("food"), "Definition text must contain headword")
        try render(app.root, to: "/tmp/ppb-dictionary-layout.png")
        app.setLevel(0)
        app.data = .plain("",title:"New")
        app.openWorkspace();app.root.layoutSubtreeIfNeeded()
        precondition(app.briefEditButton?.title=="Add task")
        precondition(app.briefEditButton?.isEnabled==true)
        app.promptEditor=NSTextView()
        app.promptEditor?.string="A new task. Explain your position with examples."
        app.saveTaskBrief();app.root.layoutSubtreeIfNeeded()
        precondition(app.data.document.prompt==app.promptEditor?.string)
        precondition(!app.taskBrief.isHidden)
        precondition(app.briefEditButton?.isHidden==true)
        precondition(app.taskPromptField?.isEditable==true)
        app.taskPromptField?.stringValue="Updated task directly."
        app.controlTextDidChange(Notification(name:NSControl.textDidChangeNotification,object:app.taskPromptField))
        precondition(app.data.document.prompt=="Updated task directly.")
        let labels=app.taskBrief.documentView!.subviews.compactMap{$0 as? NSTextField}
        precondition(labels.first!.font!.pointSize>=19)
        app.deleteTaskBrief();app.root.layoutSubtreeIfNeeded()
        precondition(app.data.document.prompt==nil && app.taskBrief.isHidden)
        precondition(app.briefEditButton?.title=="Add task")
        let settings=app.makePreferencesWindow()
        for button in app.preferencesNavigation {
            app.selectPreferencesSection(button);settings.contentView!.layoutSubtreeIfNeeded()
            if button.title=="Tags" {
                let page=app.preferencesTabs!.selectedTabViewItem!.view!
                let fields=page.subviews.compactMap{$0 as? NSStackView}.flatMap{$0.arrangedSubviews}.compactMap{$0 as? NSTextField}.filter{$0.isEditable}
                precondition(fields.count==7)
                for field in fields {precondition(field.frame.width>=260,"Tag names must not collapse")}
                try render(settings.contentView!,to:"/tmp/ppb-settings-layout.png")
            }
        }
        app.prefs.set(true,forKey:"dark")
        app.window.appearance = NSAppearance(named:.darkAqua)
        app.applyAppearance()
        app.showHome();app.root.layoutSubtreeIfNeeded()
        let homeScroll=app.root.subviews.first as! NSScrollView
        let dashboard=homeScroll.documentView as! HomeDashboard
        dashboard.layoutSubtreeIfNeeded()
        try render(app.root,to:"/tmp/ppb-home-layout.png")
        for section in dashboard.sections {
            for card in section.cards {
                card.layoutSubtreeIfNeeded()
                precondition(card.heading.maximumNumberOfLines == 0)
                precondition(card.open.isHidden)
                precondition(!card.badge.stringValue.contains("margin notes"))
                precondition(card.note.frame.maxY <= card.bounds.height)
            }
        }
        app.prefs.set(false,forKey:"dark")
        app.window.appearance = NSAppearance(named:.aqua)
        app.applyAppearance()
        app.showHome();app.root.layoutSubtreeIfNeeded()
        let homeScrollLight=app.root.subviews.first as! NSScrollView
        let dashboardLight=homeScrollLight.documentView as! HomeDashboard
        dashboardLight.layoutSubtreeIfNeeded()
        try render(app.root,to:"/tmp/ppb-home-layout-light.png")
        precondition(!PointerPolicy.isActive(mode:"Hold Option",option:false))
        precondition(PointerPolicy.isActive(mode:"Hold Option",option:true))
        precondition(PointerPolicy.isActive(mode:"Always",option:false))
        precondition(!PointerPolicy.isActive(mode:"Off",option:true))
        precondition(dashboardLight.searchField.delegate === dashboardLight)
        precondition(dashboardLight.searchField.sendsSearchStringImmediately)
        let pageClip=homeScrollLight.contentView
        precondition(pageClip.constrainBoundsRect(NSRect(x:240,y:100,width:pageClip.bounds.width,height:pageClip.bounds.height)).minX==0)
        pageClip.scroll(to:NSPoint(x:240,y:100));dashboardLight.repositionStickySidebar()
        precondition(dashboardLight.sidebar.convert(.zero,to:homeScrollLight).x>=0,"Horizontal swipe must never hide the sidebar")
        dashboardLight.searchField.stringValue="food waste"
        dashboardLight.controlTextDidChange(Notification(name:NSControl.textDidChangeNotification,object:dashboardLight.searchField));dashboardLight.layoutSubtreeIfNeeded()
        precondition(!dashboardLight.cards.isEmpty,"Search must find actual results")
        precondition(dashboardLight.cards.allSatisfy{$0.heading.stringValue.localizedCaseInsensitiveContains("food") || $0.detail.stringValue.localizedCaseInsensitiveContains("food")})
        dashboardLight.searchField.stringValue="interpolated"
        dashboardLight.controlTextDidChange(Notification(name:NSControl.textDidChangeNotification,object:dashboardLight.searchField));dashboardLight.layoutSubtreeIfNeeded()
        precondition(dashboardLight.cards.contains{$0.heading.stringValue.contains("workplace")},"Search includes full document text, beyond card excerpts")
        try render(app.root,to:"/tmp/ppb-search-layout.png")
        dashboardLight.searchField.stringValue="ppb-no-match-unique"
        dashboardLight.controlTextDidChange(Notification(name:NSControl.textDidChangeNotification,object:dashboardLight.searchField));dashboardLight.layoutSubtreeIfNeeded()
        precondition(dashboardLight.cards.isEmpty && !dashboardLight.emptyResults.isHidden)
        dashboardLight.searchField.stringValue=""
        dashboardLight.controlTextDidChange(Notification(name:NSControl.textDidChangeNotification,object:dashboardLight.searchField));dashboardLight.layoutSubtreeIfNeeded()
        precondition(dashboardLight.allCards.allSatisfy{!$0.card.isHidden},"Clearing search restores all writing")
        for url in try FileManager.default.contentsOfDirectory(at:URL(fileURLWithPath:"Reading"),includingPropertiesForKeys:nil) where url.pathExtension=="json" && url.lastPathComponent != "manifest.json" {let doc=try JSONDecoder().decode(Breakdown.self,from:Data(contentsOf:url));try doc.validate();precondition(doc.document.prompt!.contains("CC BY"))}
        let picker=app.zoomPathPicker!;picker.configure(route:[0,1,2,3])
        let chip=NSButton();chip.tag=1;picker.choose(chip);precondition(picker.route == [0,2,3]);picker.choose(chip);precondition(picker.route == [0,1,2,3])
        app.prefs.set("Student",forKey:"zoomPreset");app.level=0;precondition(app.nextZoomLevel(1)==3);app.level=3;precondition(app.nextZoomLevel(-1)==0)
        app.window.setContentSize(NSSize(width:760,height:600));app.root.layoutSubtreeIfNeeded();dashboardLight.layoutSubtreeIfNeeded()
        if let categories=dashboardLight.categoryBar {categories.layoutSubtreeIfNeeded();for control in categories.subviews where !control.isHidden {precondition(control.frame.maxX<=categories.bounds.width+1,"Category controls must fit compact window")}}
        app.window.setContentSize(NSSize(width:1200,height:800));app.root.layoutSubtreeIfNeeded();dashboardLight.layoutSubtreeIfNeeded()
        print("PASS: hold-Option pointer policy, search restoration, tap-to-select zoom route and student navigation")
        let agent=app.makeAgentWindow();agent.contentView!.layoutSubtreeIfNeeded()
        precondition(app.agentInstruction().contains("PPB IMPORT CONTRACT"))
        precondition(app.agentInstruction().contains("ielts-semantic-breakdown"))
        try render(agent.contentView!,to:"/tmp/ppb-agent-layout.png")

        app.showAbout()
        precondition(app.infoWindow != nil)
        app.infoWindow!.contentView!.layoutSubtreeIfNeeded()
        try render(app.infoWindow!.contentView!, to: "/tmp/ppb-about-layout.png")
        app.closeInfoWindow()

        app.showPrivacy()
        precondition(app.infoWindow != nil)
        app.closeInfoWindow()

        app.showTerms()
        precondition(app.infoWindow != nil)
        app.closeInfoWindow()

        var swipe=HomeSwipeGesture()
        precondition(swipe.consume(x:-25,y:1,time:1,began:true,unphased:false,momentum:false)==1)
        precondition(swipe.consume(x:-50,y:0,time:1.5,began:false,unphased:false,momentum:true)==0)
        precondition(swipe.consume(x:-50,y:0,time:1.6,began:false,unphased:false,momentum:false)==0)
        precondition(swipe.consume(x:25,y:0,time:2,began:true,unphased:false,momentum:false)==(-1))
        precondition(swipe.consume(x:5,y:30,time:3,began:true,unphased:false,momentum:false)==0)
        precondition(swipe.consume(x:40,y:1,time:3.1,began:false,unphased:false,momentum:false)==0)
        precondition(swipe.horizontal == false,"Vertical gesture cannot turn into carousel navigation")
        app.newIELTSEssay()
        precondition(app.data.document.taskType == "task2")
        precondition(app.data.document.text.isEmpty && (app.data.document.prompt ?? "").isEmpty && app.data.annotations.isEmpty)
        try app.data.validate()

        app.newResearchPaper()
        precondition(app.data.document.taskType == "research")
        precondition(app.data.document.text.isEmpty && (app.data.document.prompt ?? "").isEmpty && app.data.annotations.isEmpty)
        try app.data.validate()

        app.newDiscursiveEssay()
        precondition(app.data.document.taskType == "discursive")
        precondition(app.data.document.text.isEmpty && (app.data.document.prompt ?? "").isEmpty && app.data.annotations.isEmpty)
        try app.data.validate()
        let fixture=NSImage(size:NSSize(width:1200,height:700))
        fixture.lockFocus();NSColor.white.setFill();NSRect(x:0,y:0,width:1200,height:700).fill()
        let sample="Public transport helps people reach school.\nTeachers can explain complex ideas clearly."
        (sample as NSString).draw(in:NSRect(x:60,y:350,width:1080,height:240),withAttributes:[.font:NSFont.systemFont(ofSize:34),.foregroundColor:NSColor.black]);fixture.unlockFocus()
        let page=try LocalOCR.page(fixture)
        let recognized=try LocalOCR.recognize([page])
        precondition(recognized.text.contains("Public transport") && recognized.text.contains("Teachers"),"Vision must read the local fixture")
        let source="😀 Improve public transport. Improve public transport."
        let notes=try LocalFeedback.anchors([SuggestedNote(quote:"public transport",label:"Topic",body:"Name the specific service.",occurrence:1)],source:source)
        precondition(notes[0].start>30)
        var rejected=false
        do {_ = try LocalFeedback.anchors([SuggestedNote(quote:"invented",label:"Bad",body:"Bad")],source:source)}catch{rejected=true}
        precondition(rejected,"Fabricated quotes cannot become annotations")
        app.acceptScan(source,pages:[],notes:notes,destination:0);try app.data.validate()
        let original=app.data.document.text
        app.acceptScan("An additional paragraph.",pages:[],notes:[],destination:1)
        precondition(app.data.document.text.hasPrefix(original));try app.data.validate()
        app.acceptScan("Discuss both views.",pages:[],notes:[],destination:2)
        precondition(app.data.document.prompt=="Discuss both views." && app.data.document.text.hasPrefix(original));try app.data.validate()
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:folder)}
        try LibraryStore.save(app.data,to:folder);try LibraryStore.save(app.data,to:folder)
        precondition(LibraryStore.records(in:folder).count==1)
        let review=ScanReview(passage:app,pages:[page]);review.work?.cancel();review.text.string=recognized.text;review.window!.contentView!.layoutSubtreeIfNeeded();precondition(review.window!.contentView!.bounds.width<=970);precondition(review.text.enclosingScrollView!.bounds.width>=300)
        try render(review.window!.contentView!,to:"/tmp/ppb-scan-layout.png")
        let library=WritingLibrary(passage:app);library.window!.contentView!.layoutSubtreeIfNeeded()
        precondition(library.preview.enclosingScrollView!.bounds.width>=300,"Library preview must remain visible")
        try render(library.window!.contentView!,to:"/tmp/ppb-library-layout.png")
        print("PASS: offline Vision OCR, Unicode AI anchors, invalid quote rejection, scan destinations and library persistence")
        print("PASS: task toggle connectors, new-task save/delete actions, 19pt brief, all settings pages and tag widths (offscreen AppKit)")
    }
}
