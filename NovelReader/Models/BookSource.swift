import Foundation

struct BookSource: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var searchURL: String
    var searchMethod: String = "GET"
    var searchCharset: String = "UTF-8"
    var bookListPath: String = "books"
    var bookNamePath: String = "name"
    var bookAuthorPath: String = "author"
    var bookUrlPath: String = "url"
    var bookUrlPrefix: String = ""
    var catalogURL: String?
    var catalogListPath: String = "chapters"
    var catalogTitlePath: String = "title"
    var catalogUrlPath: String = "url"
    var catalogUrlPrefix: String = ""
    var contentURL: String?
    var contentType: String = "json"
    var contentPath: String = "content"
    var contentCharset: String = "UTF-8"
    var enabled: Bool = true

    init(
        id: UUID = UUID(),
        name: String,
        searchURL: String,
        searchMethod: String = "GET",
        searchCharset: String = "UTF-8",
        bookListPath: String = "books",
        bookNamePath: String = "name",
        bookAuthorPath: String = "author",
        bookUrlPath: String = "url",
        bookUrlPrefix: String = "",
        catalogURL: String? = nil,
        catalogListPath: String = "chapters",
        catalogTitlePath: String = "title",
        catalogUrlPath: String = "url",
        catalogUrlPrefix: String = "",
        contentURL: String? = nil,
        contentType: String = "json",
        contentPath: String = "content",
        contentCharset: String = "UTF-8",
        enabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.searchURL = searchURL
        self.searchMethod = searchMethod
        self.searchCharset = searchCharset
        self.bookListPath = bookListPath
        self.bookNamePath = bookNamePath
        self.bookAuthorPath = bookAuthorPath
        self.bookUrlPath = bookUrlPath
        self.bookUrlPrefix = bookUrlPrefix
        self.catalogURL = catalogURL
        self.catalogListPath = catalogListPath
        self.catalogTitlePath = catalogTitlePath
        self.catalogUrlPath = catalogUrlPath
        self.catalogUrlPrefix = catalogUrlPrefix
        self.contentURL = contentURL
        self.contentType = contentType
        self.contentPath = contentPath
        self.contentCharset = contentCharset
        self.enabled = enabled
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, searchURL, searchMethod, searchCharset
        case bookListPath, bookNamePath, bookAuthorPath, bookUrlPath, bookUrlPrefix
        case catalogURL, catalogListPath, catalogTitlePath, catalogUrlPath, catalogUrlPrefix
        case contentURL, contentType, contentPath, contentCharset, enabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        searchURL = try c.decode(String.self, forKey: .searchURL)
        searchMethod = try c.decodeIfPresent(String.self, forKey: .searchMethod) ?? "GET"
        searchCharset = try c.decodeIfPresent(String.self, forKey: .searchCharset) ?? "UTF-8"
        bookListPath = try c.decodeIfPresent(String.self, forKey: .bookListPath) ?? "books"
        bookNamePath = try c.decodeIfPresent(String.self, forKey: .bookNamePath) ?? "name"
        bookAuthorPath = try c.decodeIfPresent(String.self, forKey: .bookAuthorPath) ?? "author"
        bookUrlPath = try c.decodeIfPresent(String.self, forKey: .bookUrlPath) ?? "url"
        bookUrlPrefix = try c.decodeIfPresent(String.self, forKey: .bookUrlPrefix) ?? ""
        catalogURL = try c.decodeIfPresent(String.self, forKey: .catalogURL)
        catalogListPath = try c.decodeIfPresent(String.self, forKey: .catalogListPath) ?? "chapters"
        catalogTitlePath = try c.decodeIfPresent(String.self, forKey: .catalogTitlePath) ?? "title"
        catalogUrlPath = try c.decodeIfPresent(String.self, forKey: .catalogUrlPath) ?? "url"
        catalogUrlPrefix = try c.decodeIfPresent(String.self, forKey: .catalogUrlPrefix) ?? ""
        contentURL = try c.decodeIfPresent(String.self, forKey: .contentURL)
        contentType = try c.decodeIfPresent(String.self, forKey: .contentType) ?? "json"
        contentPath = try c.decodeIfPresent(String.self, forKey: .contentPath) ?? "content"
        contentCharset = try c.decodeIfPresent(String.self, forKey: .contentCharset) ?? "UTF-8"
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(searchURL, forKey: .searchURL)
        try c.encode(searchMethod, forKey: .searchMethod)
        try c.encode(searchCharset, forKey: .searchCharset)
        try c.encode(bookListPath, forKey: .bookListPath)
        try c.encode(bookNamePath, forKey: .bookNamePath)
        try c.encode(bookAuthorPath, forKey: .bookAuthorPath)
        try c.encode(bookUrlPath, forKey: .bookUrlPath)
        try c.encode(bookUrlPrefix, forKey: .bookUrlPrefix)
        try c.encode(catalogURL, forKey: .catalogURL)
        try c.encode(catalogListPath, forKey: .catalogListPath)
        try c.encode(catalogTitlePath, forKey: .catalogTitlePath)
        try c.encode(catalogUrlPath, forKey: .catalogUrlPath)
        try c.encode(catalogUrlPrefix, forKey: .catalogUrlPrefix)
        try c.encode(contentURL, forKey: .contentURL)
        try c.encode(contentType, forKey: .contentType)
        try c.encode(contentPath, forKey: .contentPath)
        try c.encode(contentCharset, forKey: .contentCharset)
        try c.encode(enabled, forKey: .enabled)
    }
}