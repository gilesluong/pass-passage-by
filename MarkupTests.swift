import Foundation
@main struct MarkupTests {
 static func main() throws {
  let source="🙂 **claim** {Explain this} and _reason_.\n`{not a note}`\n\\{escaped}\n# Heading\n::focus::"
  let notes=PassageMarkup.notes(source)
  precondition(notes.count == 1)
  precondition(notes[0].body == "Explain this")
  precondition((source as NSString).substring(with:NSRange(location:notes[0].start,length:notes[0].end-notes[0].start)) == notes[0].quote)
  let document=Breakdown(document:Essay(id:"test",title:"test",text:source,taskType:"unknown"),annotations:notes)
  try document.validate()
  precondition(PassageMarkup.route("Student") == [0,3])
  precondition(PassageMarkup.route("Teacher") == [0,1,2,3])
  precondition(PassageMarkup.route("Custom",paragraph:false,sentence:true) == [0,2,3])
  precondition(PassageMarkup.spans(source).contains {$0.kind == "heading"})
  let added=PassageMarkup.toggle("🙂 word",selection:NSRange(location:3,length:4),start:"**",end:"**")
  precondition(added.replacement == "**word**" && added.selection.location == 5)
  let removed=PassageMarkup.toggle("🙂 **word**",selection:NSRange(location:5,length:4),start:"**",end:"**")
  precondition(removed.replacement == "word" && removed.range == NSRange(location:3,length:8))
  let whole=PassageMarkup.toggle("_word_",selection:NSRange(location:0,length:6),start:"_",end:"_")
  precondition(whole.replacement == "word")
  let mixed="{Earlier note} later"
  let existing=Note(id:"old",start:15,end:20,quote:"later",kind:"comment",level:"sentence",label:"Later",body:"Later note",side:"left")
  let ordered=PassageMarkup.orderedNotes(mixed,existing:[existing])
  precondition(ordered.map {$0.start} == [0,15], "Inline note must be placed before later persisted notes")
  precondition(PassageMarkup.route("Custom",paragraph:false,sentence:false) == [0,3])
  precondition(PassageMarkup.route("Custom",paragraph:true,sentence:false) == [0,1,3])
  var edited=PassageMarkup.notes("{Earlier note}")[0]
  edited.id="saved";edited.body="Updated independently";edited.sourceStyle="brace"
  let merged=PassageMarkup.orderedNotes("{Earlier note}",existing:[edited])
  precondition(merged.count==1 && merged[0].body=="Updated independently")
  print("PASS: toggle formatting,  markup, escaped/code braces, Unicode annotation anchors, student/teacher/custom routes")
 }
}
