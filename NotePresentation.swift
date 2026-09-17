import Foundation

/// Presentation is independent of semantic kind: historical `comment` notes may be margin annotations.
enum NoteSurface: String, Codable {
    case annotation
    case comment
}

struct NotePresentation {
    let defaults: UserDefaults
    private func key(_ documentID: String) -> String { "note-surfaces.v1." + documentID }

    func surface(documentID: String, noteID: String) -> NoteSurface {
        let map = defaults.dictionary(forKey: key(documentID)) as? [String: String] ?? [:]
        return map[noteID].flatMap(NoteSurface.init(rawValue:)) ?? .annotation
    }

    func set(_ surface: NoteSurface, documentID: String, noteID: String) {
        var map = defaults.dictionary(forKey: key(documentID)) as? [String: String] ?? [:]
        map[noteID] = surface.rawValue
        defaults.set(map, forKey: key(documentID))
    }
}
