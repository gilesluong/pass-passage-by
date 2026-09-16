import Cocoa
import QuartzCore

enum PointerPolicy {
    static func isActive(mode:String,option:Bool)->Bool {mode == "Always" || (mode == "Hold Option" && option)}
}

final class ZoomPathPicker:NSView {
    override var isFlipped:Bool {true}
    var route=[0,1,2,3]
    var onChange:(([Int])->Void)?
    private var chips:[NSButton]=[]
    private let active=NSTextField(labelWithString:"YOUR READING PATH")
    private let available=NSTextField(labelWithString:"AVAILABLE STEPS")
    override init(frame:NSRect) {
        super.init(frame:frame);wantsLayer=true
        for label in [active,available] {label.font = .systemFont(ofSize:10,weight:.semibold);label.textColor = .secondaryLabelColor;addSubview(label)}
        for (i,title) in ["Essay","Paragraph","Sentence","Word"].enumerated() {
            let button=NSButton(title:title,target:self,action:#selector(choose(_:)));button.tag=i;button.bezelStyle = .rounded;button.setButtonType(.toggle);button.wantsLayer=true;button.setAccessibilityLabel(title+((i==0 || i==3) ? ", required step":"; click to include or exclude"));addSubview(button);chips.append(button)
        }
    }
    required init?(coder:NSCoder){fatalError()}
    func configure(route:[Int]) {self.route=route;arrange(animated:false)}
    @objc func choose(_ sender:NSButton) {
        guard sender.tag != 0,sender.tag != 3 else{return}
        if route.contains(sender.tag) {route.removeAll{$0==sender.tag}}else{route.append(sender.tag);route.sort()}
        arrange(animated:true);onChange?(route)
    }
    override func layout(){super.layout();arrange(animated:false)}
    private func arrange(animated:Bool) {
        active.frame=NSRect(x:0,y:0,width:300,height:16);available.frame=NSRect(x:0,y:86,width:300,height:16)
        let off=(0...3).filter{!route.contains($0)}
        for (i,chip) in chips.enumerated() {
            let selected=route.contains(i);let position=(selected ? route:off).firstIndex(of:i) ?? 0
            let target=NSRect(x:CGFloat(position)*122,y:selected ? 26:110,width:112,height:30)
            chip.isEnabled=i != 0 && i != 3;chip.state=selected ? .on:.off;chip.contentTintColor=selected ? .controlAccentColor:.secondaryLabelColor
            if animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                NSAnimationContext.runAnimationGroup {context in context.duration=0.25;context.timingFunction=CAMediaTimingFunction(controlPoints:0.22,1,0.36,1);chip.animator().frame=target}
            }else{chip.frame=target}
        }
    }
}

extension Passage {
    @objc func togglePointerHighlight() {
        let mode=prefs.string(forKey:"pointerMode") ?? "Hold Option"
        prefs.set(mode == "Always" ? "Hold Option":"Always",forKey:"pointerMode")
        if opened {editor.updatePointer(at:editor.convert(window.mouseLocationOutsideOfEventStream,from:nil))}
        preferencesWindow?.close();preferencesWindow=nil
    }
    func updateSelectionAction() {
        guard editor.selectedRange().length>0,commentPopover?.isShown != true else{floatingCommentButton?.isHidden=true;return}
        let range=editor.selectedRange();var actual=NSRange()
        let screen=editor.firstRect(forCharacterRange:NSRange(location:range.location,length:1),actualRange:&actual)
        let local=editor.convert(window.convertFromScreen(screen),from:nil)
        if floatingCommentButton?.superview !== editor {floatingCommentButton?.removeFromSuperview();floatingCommentButton=nil}
        let pill=floatingCommentButton ?? FloatingCommentPill(frame:.zero)
        pill.title="Comment  ⌥⌘M";pill.font = .systemFont(ofSize:12,weight:.medium);pill.target=self;pill.action=#selector(comment)
        pill.frame=NSRect(x:max(editor.visibleRect.minX+8,min(local.minX,editor.visibleRect.maxX-170)),y:max(editor.visibleRect.minY+4,local.minY-34),width:164,height:28)
        if pill.superview == nil {editor.addSubview(pill)}
        pill.isHidden=false;floatingCommentButton=pill
    }
}

extension Passage {
    func showcaseDocuments()->[(Breakdown,String)] {
        let ids=prefs.stringArray(forKey:"showcaseIDs") ?? []
        return LibraryStore.records(in:saveURL.deletingLastPathComponent().appendingPathComponent("Library")).filter{ids.contains($0.document.document.id)}.sorted{ids.firstIndex(of:$0.document.document.id)! < ids.firstIndex(of:$1.document.document.id)!}.map{($0.document,$0.url.path)}
    }
    @objc func toggleShowcasePin(){
        guard opened else{return};saveDraft()
        var ids=prefs.stringArray(forKey:"showcaseIDs") ?? []
        if ids.contains(data.document.id){ids.removeAll{$0==data.document.id}}else{ids.append(data.document.id)}
        prefs.set(ids,forKey:"showcaseIDs")
        showHome()
    }
}

final class ThemePicker:NSView {
    override var isFlipped:Bool {true}
    var onChange:((String)->Void)?
    var selected:String
    let names=["Paper","Sepia","Forest","Midnight"]
    var buttons:[NSButton]=[]
    init(selected:String){self.selected=selected;super.init(frame:.zero)
        for (i,name) in names.enumerated(){let b=NSButton(title:"Aa\n"+name,target:self,action:#selector(selectTheme(_:)));b.tag=i;b.bezelStyle = .regularSquare;b.isBordered=false;b.wantsLayer=true;b.layer?.cornerRadius=10;b.font=NSFont(name:"Georgia",size:16);b.setAccessibilityLabel(name+" theme");addSubview(b);buttons.append(b)}
    }
    required init?(coder:NSCoder){fatalError()}
    override func layout(){super.layout();let colors=[NSColor(calibratedRed:0.98,green:0.97,blue:0.93,alpha:1),NSColor(calibratedRed:0.92,green:0.85,blue:0.72,alpha:1),NSColor(calibratedRed:0.12,green:0.25,blue:0.21,alpha:1),NSColor(calibratedRed:0.14,green:0.16,blue:0.20,alpha:1)]
        for (i,b) in buttons.enumerated(){b.frame=NSRect(x:CGFloat(i)*126,y:8,width:116,height:86);b.layer?.backgroundColor=colors[i].cgColor;b.contentTintColor=i<2 ? .darkGray:.white;b.layer?.borderWidth=names[i]==selected ? 3:0;b.layer?.borderColor=NSColor.controlAccentColor.cgColor}
    }
    @objc func selectTheme(_ sender:NSButton){selected=names[sender.tag];needsLayout=true;onChange?(selected)}
}
