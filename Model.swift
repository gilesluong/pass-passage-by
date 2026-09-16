import Foundation

struct Note: Codable {
 var id: String; var start: Int; var end: Int; var quote: String
 var kind: String; var level: String; var label: String; var body: String
 var suggestion: String?; var side: String?; var status: String?
 var tag: String? = nil
 var sourceStyle: String? = nil
}
struct Essay: Codable {
 var id: String; var title: String; var text: String; var taskType: String
 var prompt: String?; var language: String?
}
struct DocumentImage: Codable { var id: String; var name: String; var data: Data }
struct Breakdown: Codable {
 var images: [DocumentImage]? = nil
 var format = "ielts-semantic-breakdown"; var version = 1
 var document: Essay; var annotations: [Note]
 static func plain(_ text: String, title: String) -> Breakdown {
  Breakdown(document: Essay(id:UUID().uuidString,title:title,text:text,taskType:"unknown"),annotations:[])
 }
 func validate() throws {
  guard format == "ielts-semantic-breakdown", version == 1, document.text.utf8.count <= 3_000_000 else {throw ModelError.invalid}
  let source=document.text as NSString
  guard (images ?? []).count <= 12, (images ?? []).reduce(0,{$0+$1.data.count}) <= 48_000_000, (images ?? []).allSatisfy({$0.data.count <= 8_000_000}) else {throw ModelError.invalid}
  var ids=Set<String>()
  for n in annotations {
   guard n.start>=0,n.end>n.start,n.end<=source.length,ids.insert(n.id).inserted,
    ["essay","paragraph","sentence","word"].contains(n.level),
    ["comment","correction","vocabulary","structure","bold","italic","underline","highlight"].contains(n.kind),
    source.substring(with:NSRange(location:n.start,length:n.end-n.start))==n.quote else {throw ModelError.invalid}
  }
 }
 mutating func replace(_ range:NSRange, with replacement:String) {
  let source=document.text as NSString
  guard range.location>=0,NSMaxRange(range)<=source.length else{return}
  let delta=(replacement as NSString).length-range.length
  document.text=source.replacingCharacters(in:range,with:replacement)
  let updated=document.text as NSString
  annotations=annotations.compactMap { original in
   var n=original
   if n.end<=range.location { return n }
   if n.start>=NSMaxRange(range) {n.start+=delta;n.end+=delta;return n}
   n.start=min(n.start,range.location)
   n.end=max(n.start, n.end>NSMaxRange(range) ? n.end+delta:range.location+(replacement as NSString).length)
   guard n.end>n.start,n.end<=updated.length else{return nil}
   n.quote=updated.substring(with:NSRange(location:n.start,length:n.end-n.start));n.status="needs-review"
   return n
  }
 }
 func range(level:Int, offset:Int)->NSRange {
  let source=document.text as NSString
  if level==0 || source.length==0 {return NSRange(location:0,length:source.length)}
  let safe=min(max(offset,0),source.length-1)
  let pattern = level==1 ? #"[^\r\n]+(?:\n(?!\s*\n)[^\n]+)*"# : level==2 ? #"[^.!?\n]+(?:[.!?]+[\"”’']*|$)"# : #"[\p{L}\p{N}]+(?:['’\-][\p{L}\p{N}]+)*"#
  let regex=try! NSRegularExpression(pattern:pattern,options:.anchorsMatchLines)
  let matches=regex.matches(in:document.text,range:NSRange(location:0,length:source.length))
  return matches.min(by:{distance($0.range,safe)<distance($1.range,safe)})?.range ?? NSRange(location:0,length:source.length)
 }
}
func distance(_ r:NSRange,_ x:Int)->Int { x<r.location ? r.location-x : x>=NSMaxRange(r) ? x-NSMaxRange(r)+1:0 }
enum ModelError:LocalizedError {case invalid;var errorDescription:String?{"Invalid annotation JSON: check its version, unique IDs, and exact quote offsets."}}
