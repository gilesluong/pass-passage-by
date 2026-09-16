import Foundation
@main struct ModelTests {
 static func main() throws {
  let bytes=try Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1]));let demo=try JSONDecoder().decode(Breakdown.self,from:bytes);try demo.validate()
  let encoded=try JSONEncoder().encode(demo);let roundtrip=try JSONDecoder().decode(Breakdown.self,from:encoded);assert(roundtrip.document.text==demo.document.text);assert(roundtrip.annotations.count==5)
  var d=Breakdown.plain("🌿 hello world.",title:"Unicode");d.annotations=[Note(id:"a",start:3,end:8,quote:"hello",kind:"comment",level:"word",label:"x",body:"y")];try d.validate();d.replace(NSRange(location:0,length:0),with:"Hi ");assert(d.annotations[0].start==6);try d.validate();d.replace(NSRange(location:6,length:5),with:"goodbye");assert(d.annotations[0].quote=="goodbye");assert(d.annotations[0].status=="needs-review");try d.validate();d.replace(NSRange(location:6,length:7),with:"");assert(d.annotations.isEmpty)
  let r=demo.range(level:3,offset:430);assert((demo.document.text as NSString).substring(with:r)=="at")
  let paragraph=demo.range(level:1,offset:430);assert((demo.document.text as NSString).substring(with:paragraph).hasPrefix("One clear"))
  let empty=Breakdown.plain("",title:"");assert(empty.range(level:3,offset:0).length==0)
  var bad=demo;bad.annotations[0].quote="wrong";do{try bad.validate();assertionFailure("Must reject")}catch{}
  var rich=demo
  rich.annotations[0].tag="purple";rich.annotations[0].sourceStyle="brace"
  rich.images=[DocumentImage(id:"image",name:"chart.png",data:Data([1,2,3]))]
  try rich.validate()
  let restored=try JSONDecoder().decode(Breakdown.self,from:JSONEncoder().encode(rich))
  assert(restored.annotations[0].tag=="purple" && restored.annotations[0].sourceStyle=="brace")
  assert(restored.images?.first?.data==Data([1,2,3]))
  rich.images=Array(repeating:DocumentImage(id:"x",name:"x",data:Data()),count:13)
  do {try rich.validate();assertionFailure("Reject too many images")} catch {}
  print("PASS: JSON roundtrip, 5 sample annotations, Unicode offsets, insertion, replacement, deletion, semantic ranges, empty text, invalid quote rejection")
 }
}
