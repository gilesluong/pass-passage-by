import Foundation

// Source text stays lossless. These ranges only control its native presentation.
struct MarkupSpan { let range: NSRange; let kind: String }
enum PassageMarkup {
    static func spans(_ text: String) -> [MarkupSpan] {
        let length = (text as NSString).length
        let patterns: [(String,String)] = [
            ("code", #"(?s)```.*?```|`[^`\n]+`"#),
            ("heading", #"(?m)^#{1,6}\s+[^\n]+"#),
            ("strong", #"\*\*[^*\n]+\*\*"#),
            ("emphasis", #"(?<!\w)_[^_\n]+_(?!\w)"#),
            ("highlight", #"::[^:\n]+::"#),
            ("redact", #"\|\|[^\n]+?\|\|"#),
            ("comment", #"\+\+[^\n]+?\+\+"#),
            ("link", #"!?\[[^\]\n]+\]\([^\)\n]+\)"#),
            ("quote", #"(?m)^>[^\n]*"#),
            ("list", #"(?m)^\s*(?:[-*+] |\d+\. |\[\] |\[x\] )[^\n]*"#),
            ("divider", #"(?m)^\s*----+\s*$"#),
            ("annotation", #"(?<!\\)\{[^{}\n]+\}"#)
        ]
        var result: [MarkupSpan] = []
        for (kind,pattern) in patterns {
            let matches = (try? NSRegularExpression(pattern: pattern))?.matches(in: text, range: NSRange(location:0,length:length)) ?? []
            for match in matches where kind == "code" || !result.contains(where: {$0.kind == "code" && NSIntersectionRange($0.range,match.range).length > 0}) {
                result.append(MarkupSpan(range:match.range,kind:kind))
            }
        }
        return result
    }
    static func notes(_ text: String) -> [Note] {
        let source = text as NSString
        return spans(text).filter {$0.kind == "annotation"}.enumerated().map { i,span in
            let quote = source.substring(with:span.range)
            return Note(id:"inline-\(span.range.location)",start:span.range.location,end:NSMaxRange(span.range),quote:quote,kind:"comment",level:"sentence",label:"Annotation",body:String(quote.dropFirst().dropLast()),side:i % 2 == 0 ? "left" : "right")
        }
    }
    static func orderedNotes(_ text: String, existing: [Note]) -> [Note] {
        (existing + notes(text).filter { inline in !existing.contains { $0.start == inline.start && $0.end == inline.end } }).sorted { $0.start == $1.start ? $0.id < $1.id : $0.start < $1.start }
    }
    struct Edit { let range: NSRange; let replacement: String; let selection: NSRange }
    static func toggle(_ text: String, selection: NSRange, start: String, end: String) -> Edit {
        let source = text as NSString, prefix = start as NSString, suffix = end as NSString
        let selected = source.substring(with:selection)
        if !end.isEmpty, selected.hasPrefix(start), selected.hasSuffix(end), selection.length >= prefix.length + suffix.length {
            let inner = (selected as NSString).substring(with:NSRange(location:prefix.length,length:selection.length - prefix.length - suffix.length))
            return Edit(range:selection,replacement:inner,selection:NSRange(location:selection.location,length:(inner as NSString).length))
        }
        if !end.isEmpty, selection.location >= prefix.length, NSMaxRange(selection) + suffix.length <= source.length,
           source.substring(with:NSRange(location:selection.location - prefix.length,length:prefix.length)) == start,
           source.substring(with:NSRange(location:NSMaxRange(selection),length:suffix.length)) == end {
            let range = NSRange(location:selection.location - prefix.length,length:selection.length + prefix.length + suffix.length)
            return Edit(range:range,replacement:selected,selection:NSRange(location:range.location,length:selection.length))
        }
        return Edit(range:selection,replacement:start + selected + end,selection:NSRange(location:selection.location + prefix.length,length:selection.length))
    }
    static func route(_ preset: String, paragraph: Bool = true, sentence: Bool = true) -> [Int] {
        if preset == "Student" { return [0,3] }
        if preset == "Custom" { return [0] + (paragraph ? [1] : []) + (sentence ? [2] : []) + [3] }
        return [0,1,2,3]
    }
}
