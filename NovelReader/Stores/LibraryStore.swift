import Foundation
import CoreFoundation
import Combine

final class LibraryStore: ObservableObject {
    @Published var books: [Book] = []

    private let fileManager = FileManager.default
    private let booksDirectoryName = "Books"

    init() {
        load()
    }

    private var libraryFileURL: URL {
        let dir = applicationSupportDirectory()
        return dir.appendingPathComponent("library.json")
    }

    private func applicationSupportDirectory() -> URL {
        let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    func booksDirectory() -> URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent(booksDirectoryName, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func load() {
        guard let data = try? Data(contentsOf: libraryFileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Book].self, from: data) {
            books = decoded
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(books) {
            try? data.write(to: libraryFileURL, options: .atomic)
        }
    }

    @discardableResult
    func importLocalFile(from url: URL) throws -> Book {
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let text = Self.decodeText(data)
        let title = url.deletingPathExtension().lastPathComponent

        var book = Book(title: title, author: nil, kind: .local)
        let bookFolder = booksDirectory().appendingPathComponent(book.id.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: bookFolder, withIntermediateDirectories: true)

        var chapters = Self.parseChapters(text)
        for index in chapters.indices {
            let chapter = chapters[index]
            let fileName = "\(index).txt"
            let chapterURL = bookFolder.appendingPathComponent(fileName)
            if let content = chapter.content?.data(using: .utf8) {
                try content.write(to: chapterURL, options: .atomic)
            }
            chapters[index].url = "\(book.id.uuidString)/\(fileName)"
            chapters[index].content = nil
        }
        book.chapters = chapters
        book.localFileName = book.id.uuidString

        books.insert(book, at: 0)
        save()
        return book
    }

    func localContent(for chapter: Chapter) -> String? {
        guard !chapter.url.contains("://") else { return nil }
        let url = URL(fileURLWithPath: chapter.url, relativeTo: booksDirectory()).standardizedFileURL
        return try? String(contentsOf: url, encoding: .utf8)
    }

    func addOnlineBook(_ book: Book) {
        books.insert(book, at: 0)
        save()
    }

    func update(_ book: Book) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[index] = book
        save()
    }

    func delete(_ book: Book) {
        books.removeAll { $0.id == book.id }
        if let folderName = book.localFileName {
            let folder = booksDirectory().appendingPathComponent(folderName, isDirectory: true)
            try? fileManager.removeItem(at: folder)
        }
        save()
    }

    private static func decodeText(_ data: Data) -> String {
        if let text = String(data: data, encoding: .utf8) {
            return text
        }

        let gb18030 = CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        )
        if let text = NSString(data: data, encoding: gb18030) as String? {
            return text
        }

        return String(data: data, encoding: .isoLatin1) ?? ""
    }

    static func parseChapters(_ text: String) -> [Chapter] {
        let pattern = "^[ \t]*((第[0-9一二三四五六七八九十百千万零两]+[章节卷回集部篇].*)|(序章|楔子|前言|后记|尾声|番外|外传|终章).*|Chapter\\s+\\d+.*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .anchorsMatchLines]) else {
            return [Chapter(title: "全文", url: "", content: text)]
        }

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, options: [], range: fullRange)

        var boundaries: [(title: String, location: Int)] = []
        for match in matches {
            let range = match.range
            if let swiftRange = Range(range, in: text) {
                let rawTitle = String(text[swiftRange])
                let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                boundaries.append((title: title, location: range.location))
            }
        }

        if boundaries.isEmpty {
            return [Chapter(title: "全文", url: "", content: text)]
        }

        var chapters: [Chapter] = []
        for index in boundaries.indices {
            let start = boundaries[index].location
            let end = index + 1 < boundaries.count ? boundaries[index + 1].location : nsText.length
            let contentRange = NSRange(location: start, length: end - start)
            let content = contentRange.location != NSNotFound ? nsText.substring(with: contentRange) : ""
            chapters.append(Chapter(title: boundaries[index].title, url: "", content: content))
        }
        return chapters
    }
}