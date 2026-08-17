import Foundation
import CoreFoundation

struct SearchResult: Identifiable {
    let id = UUID()
    let book: Book
    let source: BookSource
}

enum BookSourceServiceError: LocalizedError {
    case invalidURL
    case network(Error)
    case invalidResponse
    case noCatalog

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "??? URL"
        case .network(let error):
            return "?????\(error.localizedDescription)"
        case .invalidResponse:
            return "????????????"
        case .noCatalog:
            return "???????????"
        }
    }
}

struct BookSourceService {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
        ]
        return URLSession(configuration: config)
    }()

    func search(keyword: String, in sources: [BookSource]) async -> [SearchResult] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let enabledSources = sources.filter { $0.enabled }
        var results: [SearchResult] = []

        await withTaskGroup(of: [SearchResult].self) { group in
            for source in enabledSources {
                group.addTask {
                    await self.search(source: source, keyword: trimmed)
                }
            }

            for await batch in group {
                results.append(contentsOf: batch)
            }
        }

        return results
    }

    private func search(source: BookSource, keyword: String) async -> [SearchResult] {
        do {
            guard let url = buildURL(template: source.searchURL, replacements: ["keyword": keyword]) else {
                return []
            }

            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return []
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) else {
                return []
            }

            let searched = Self.value(at: source.bookListPath, in: json)
            let list: [Any]
            if let array = searched as? [Any] {
                list = array
            } else if searched != nil {
                list = [searched]
            } else {
                return []
            }

            return list.compactMap { item in
                guard let name = Self.stringValue(at: source.bookNamePath, in: item), !name.isEmpty else {
                    return nil
                }
                let author = Self.stringValue(at: source.bookAuthorPath, in: item) ?? ""
                let rawURL = Self.stringValue(at: source.bookUrlPath, in: item) ?? ""
                let remoteURL = Self.absoluteURL(rawURL, prefix: source.bookUrlPrefix)
                let book = Book(
                    title: name,
                    author: author.isEmpty ? nil : author,
                    kind: .online,
                    sourceID: source.id,
                    remoteBookURL: remoteURL
                )
                return SearchResult(book: book, source: source)
            }
        } catch {
            return []
        }
    }

    func catalog(for book: Book, source: BookSource) async throws -> [Chapter] {
        guard let template = source.catalogURL, let bookURL = book.remoteBookURL else {
            throw BookSourceServiceError.noCatalog
        }

        guard let url = buildURL(template: template, replacements: ["bookUrl": bookURL]) else {
            throw BookSourceServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw BookSourceServiceError.invalidResponse
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            throw BookSourceServiceError.invalidResponse
        }

        let searched = Self.value(at: source.catalogListPath, in: json)
        let list: [Any]
        if let array = searched as? [Any] {
            list = array
        } else if searched != nil {
            list = [searched]
        } else {
            throw BookSourceServiceError.invalidResponse
        }

        var chapters: [Chapter] = []
        for (index, item) in list.enumerated() {
            let title = Self.stringValue(at: source.catalogTitlePath, in: item) ?? "?\(index + 1)?"
            let rawURL = Self.stringValue(at: source.catalogUrlPath, in: item) ?? ""
            let url = Self.absoluteURL(rawURL, prefix: source.catalogUrlPrefix)
            chapters.append(Chapter(title: title, url: url))
        }
        return chapters
    }

    func content(for chapter: Chapter, source: BookSource) async throws -> String {
        if let cached = chapter.content, !cached.isEmpty {
            return cached
        }

        guard let template = source.contentURL else {
            throw BookSourceServiceError.invalidURL
        }

        guard let url = buildURL(template: template, replacements: ["chapterUrl": chapter.url]) else {
            throw BookSourceServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw BookSourceServiceError.invalidResponse
        }

        if source.contentType.lowercased() == "text" {
            return Self.decodeText(data, charset: source.contentCharset)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data),
              let text = Self.stringValue(at: source.contentPath, in: json), !text.isEmpty else {
            throw BookSourceServiceError.invalidResponse
        }
        return text
    }

    private func buildURL(template: String, replacements: [String: String]) -> URL? {
        var string = template
        for (key, value) in replacements {
            let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            string = string.replacingOccurrences(of: "{\(key)}", with: encoded)
        }
        return URL(string: string)
    }

    private static func absoluteURL(_ raw: String, prefix: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        guard !prefix.isEmpty else { return trimmed }
        if prefix.hasSuffix("/") && trimmed.hasPrefix("/") {
            return prefix + String(trimmed.dropFirst())
        }
        return prefix + (trimmed.hasPrefix("/") ? "" : "/") + trimmed
    }

    static func value(at path: String, in object: Any) -> Any? {
        var current: Any? = object
        var trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPath.hasPrefix("$.") {
            trimmedPath = String(trimmedPath.dropFirst(2))
        }

        let parts = trimmedPath.split(separator: ".").map(String.init)
        for part in parts {
            if part.isEmpty { continue }
            if let bracketIndex = part.firstIndex(of: "[") {
                let key = String(part[..<bracketIndex])
                let rest = String(part[bracketIndex...])
                if !key.isEmpty {
                    if let dict = current as? [String: Any] {
                        current = dict[key]
                    } else if let array = current as? [Any], let idx = Int(key), array.indices.contains(idx) {
                        current = array[idx]
                    } else {
                        return nil
                    }
                }
                if let array = current as? [Any], let index = parseBracketIndex(rest) {
                    guard array.indices.contains(index) else { return nil }
                    current = array[index]
                } else if let dict = current as? [String: Any] {
                    let subKey = rest.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                    current = dict[subKey]
                } else {
                    return nil
                }
            } else {
                if let dict = current as? [String: Any] {
                    current = dict[part]
                } else if let array = current as? [Any], let index = Int(part) {
                    guard array.indices.contains(index) else { return nil }
                    current = array[index]
                } else {
                    return nil
                }
            }
        }
        return current
    }

    private static func parseBracketIndex(_ text: String) -> Int? {
        let digits = text.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        return Int(digits)
    }

    private static func stringValue(at path: String, in object: Any) -> String? {
        guard let value = value(at: path, in: object) else { return nil }
        if let string = value as? String {
            return string
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    private static func decodeText(_ data: Data, charset: String) -> String {
        let normalized = charset.uppercased().replacingOccurrences(of: "_", with: "-")
        switch normalized {
        case "UTF-8", "UTF8":
            return String(data: data, encoding: .utf8) ?? ""
        case "GBK", "GB18030", "GB2312":
            let gb = CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            )
            return NSString(data: data, encoding: gb) as String? ?? ""
        default:
            return String(data: data, encoding: .utf8) ?? ""
        }
    }
}
