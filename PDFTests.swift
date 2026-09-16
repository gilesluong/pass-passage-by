import Cocoa
import PDFKit
@main struct PDFTests {
static func main()throws {
 _ = NSApplication.shared
 let data=try JSONDecoder().decode(Breakdown.self,from:Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1])))
 let pdf=annotatedPDF(data)
 guard pdf.pageCount>0,let bytes=pdf.dataRepresentation(),let decoded=PDFDocument(data:bytes) else{fatalError("No PDF")}
 let text=decoded.string ?? ""
 precondition(text.contains("guidance"));precondition(text.contains("Annotation details"));precondition(text.contains(data.annotations[0].label))
 try bytes.write(to:URL(fileURLWithPath:"/tmp/PPB-preview-test.pdf"))
 print("PASS: PDF pages, source text, annotation details; pages=\(pdf.pageCount)")
}
}
