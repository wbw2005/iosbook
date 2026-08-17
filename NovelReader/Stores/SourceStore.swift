import Foundation
import Combine

final class SourceStore: ObservableObject {
    @Published var sources: [BookSource] = []

    private let fileManager = FileManager.default

    init() {
        load()
    }

    private var sourcesFileURL: URL {
        let dir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("book_sources.json")
    }

    func load() {
        guard let data = try? Data(contentsOf: sourcesFileURL) else { return }
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([BookSource].self, from: data) {
            sources = decoded
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(sources) {
            try? data.write(to: sourcesFileURL, options: .atomic)
        }
    }

    func add(_ source: BookSource) {
        sources.append(source)
        save()
    }

    func update(_ source: BookSource) {
        guard let index = sources.firstIndex(where: { $0.id == source.id }) else { return }
        sources[index] = source
        save()
    }

    func delete(_ source: BookSource) {
        sources.removeAll { $0.id == source.id }
        save()
    }

    func toggle(_ source: BookSource) {
        var updated = source
        updated.enabled.toggle()
        update(updated)
    }

    func addSampleSourceIfNeeded() {
        guard sources.isEmpty else { return }
        add(BookSource(
            name: "示例书源（可修改）",
            searchURL: "https://example.com/api/search?q={keyword}",
            bookListPath: "books",
            bookNamePath: "name",
            bookAuthorPath: "author",
            bookUrlPath: "url",
            bookUrlPrefix: "https://example.com",
            catalogURL: "{bookUrl}/chapters",
            catalogListPath: "chapters",
            catalogTitlePath: "title",
            catalogUrlPath: "url",
            contentURL: "{chapterUrl}",
            contentPath: "content"
        ))
    }
}