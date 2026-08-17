import Foundation

enum BookKind: String, Codable {
    case local
    case online
}

struct Book: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var author: String?
    var kind: BookKind
    var localFileName: String?
    var sourceID: UUID?
    var remoteBookURL: String?
    var chapters: [Chapter] = []
    var lastReadChapterIndex: Int = 0
    var addedAt: Date = Date()

    init(
        title: String,
        author: String? = nil,
        kind: BookKind,
        localFileName: String? = nil,
        sourceID: UUID? = nil,
        remoteBookURL: String? = nil
    ) {
        self.title = title
        self.author = author
        self.kind = kind
        self.localFileName = localFileName
        self.sourceID = sourceID
        self.remoteBookURL = remoteBookURL
    }
}