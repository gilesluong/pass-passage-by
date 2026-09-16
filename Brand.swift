import Cocoa
// Native adaptation of transitions.dev: short text swap, reversible page motion.
enum BrandMotion { static let textSwap=0.15; static let page=0.25 }
final class PaperBackdrop:NSView {
 var receiveFiles:(([URL])->Void)?
 override init(frame:NSRect){super.init(frame:frame);registerForDraggedTypes([.fileURL])}
 required init?(coder:NSCoder){super.init(coder:coder);registerForDraggedTypes([.fileURL])}
 override func draggingEntered(_ sender:NSDraggingInfo)->NSDragOperation {.copy}
 override func performDragOperation(_ sender:NSDraggingInfo)->Bool {
  guard let urls=sender.draggingPasteboard.readObjects(forClasses:[NSURL.self],options:[.urlReadingFileURLsOnly:true]) as? [URL], !urls.isEmpty else{return false}
  receiveFiles?(urls);return true
 }
 var decorated=false {didSet{needsDisplay=true}}
 override func draw(_ dirtyRect:NSRect){
  let dark=effectiveAppearance.bestMatch(from:[.darkAqua,.aqua]) == .darkAqua
  let bg = dark ? NSColor(calibratedRed:0.11,green:0.12,blue:0.15,alpha:1) : NSColor(calibratedRed:0.96,green:0.96,blue:0.97,alpha:1)
  bg.setFill()
  dirtyRect.fill()
  super.draw(dirtyRect)
  guard decorated else{return}
  (dark ? NSColor.white : NSColor(calibratedRed:0.12,green:0.35,blue:0.33,alpha:1)).withAlphaComponent(0.045).setStroke()
  for index in 0..<6 {
   let rect=NSRect(x:bounds.maxX-300+CGFloat(index)*28,y:bounds.midY-170+CGFloat(index)*10,width:470,height:470)
   let path=NSBezierPath(roundedRect:rect,xRadius:150,yRadius:150);path.lineWidth=1;path.stroke()
  }
 }
}
