import Cocoa
let source=NSImage(contentsOfFile:"Assets/ppb-icon.png")!
let folder=URL(fileURLWithPath:CommandLine.arguments[1]);try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
for size in [16,32,128,256,512] {for scale in [1,2] {
 let pixels=size*scale
 let image=NSImage(size:NSSize(width:pixels,height:pixels));image.lockFocus();NSBezierPath(roundedRect:NSRect(x:0,y:0,width:pixels,height:pixels),xRadius:CGFloat(pixels)*0.29,yRadius:CGFloat(pixels)*0.29).addClip();source.draw(in:NSRect(x:0,y:0,width:pixels,height:pixels));image.unlockFocus()
 let bytes=NSBitmapImageRep(data:image.tiffRepresentation!)!.representation(using:.png,properties:[:])!
 try bytes.write(to:folder.appendingPathComponent("icon_\(size)x\(size)\(scale==2 ? "@2x":"").png"))
}}
