import SwiftUI

struct ReaderView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var sourceStore: SourceStore

    @AppStorage("readerFontSize") private var fontSize = 18.0
    @AppStorage("readerLineSpacing") private var lineSpacing = 8.0
    @AppStorage("readerTheme") private var readerTheme = "system"

    @State private var currentBook: Book
    @State private var currentChapterIndex: Int = 0
    @State private var chapterContent = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showChapters = false
    @State private var didPrepare = false

    private let service = BookSourceService()

    init(book: Book) {
        _currentBook = State(initialValue: book)
        _currentChapterIndex = State(initialValue: book.lastReadChapterIndex)
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("加载中…")
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if chapterContent.isEmpty {
                Text("暂无内容")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                Text(chapterContent)
                    .font(.system(size: fontSize))
                    .lineSpacing(lineSpacing)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
        }
        .background(backgroundColor)
        .navigationTitle(currentChapterTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showChapters = true
                } label: {
                    Image(systemName: "list.bullet")
                }
                .disabled(currentBook.chapters.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .task {
            await prepare()
        }
        .sheet(isPresented: $showChapters) {
            chapterListView
        }
        .alert("出错了", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var currentChapterTitle: String {
        guard currentBook.chapters.indices.contains(currentChapterIndex) else { return currentBook.title }
        return currentBook.chapters[currentChapterIndex].title
    }

    private var bottomBar: some View {
        HStack {
            Button {
                Task { await loadChapter(at: currentChapterIndex - 1) }
            } label: {
                Image(systemName: "chevron.left")
                Text("上一章")
            }
            .disabled(currentChapterIndex <= 0 || isLoading)

            Spacer()

            Text("\(currentBook.chapters.isEmpty ? 0 : currentChapterIndex + 1) / \(currentBook.chapters.count)")
                .font(.footnote)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                Task { await loadChapter(at: currentChapterIndex + 1) }
            } label: {
                Text("下一章")
                Image(systemName: "chevron.right")
            }
            .disabled(currentChapterIndex >= max(0, currentBook.chapters.count - 1) || isLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
    }

    private var chapterListView: some View {
        NavigationView {
            List {
                ForEach(Array(currentBook.chapters.enumerated()), id: \.element.id) { index, chapter in
                    Button {
                        showChapters = false
                        Task { await loadChapter(at: index) }
                    } label: {
                        HStack {
                            Text(chapter.title)
                                .foregroundColor(index == currentChapterIndex ? .accentColor : .primary)
                                .lineLimit(1)
                            Spacer()
                            if index == currentChapterIndex {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("目录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        showChapters = false
                    }
                }
            }
        }
    }

    private var backgroundColor: Color {
        switch readerTheme {
        case "light":
            return Color(.systemBackground)
        case "sepia":
            return Color(red: 0.96, green: 0.92, blue: 0.84)
        case "dark":
            return Color(red: 0.08, green: 0.08, blue: 0.10)
        default:
            return Color(.systemBackground)
        }
    }

    private var textColor: Color {
        switch readerTheme {
        case "sepia":
            return Color(red: 0.2, green: 0.15, blue: 0.1)
        case "dark":
            return Color(red: 0.82, green: 0.82, blue: 0.85)
        default:
            return Color(.label)
        }
    }

    private func prepare() async {
        guard !didPrepare else { return }
        didPrepare = true

        if let existing = library.books.first(where: { $0.id == currentBook.id }) {
            currentBook = existing
            currentChapterIndex = existing.lastReadChapterIndex
        } else if currentBook.kind == .online,
                  let existing = library.books.first(where: {
                    $0.kind == .online &&
                    $0.sourceID == currentBook.sourceID &&
                    $0.remoteBookURL == currentBook.remoteBookURL
                  }) {
            currentBook = existing
            currentChapterIndex = existing.lastReadChapterIndex
        } else {
            library.addOnlineBook(currentBook)
        }

        if currentBook.kind == .online && currentBook.chapters.isEmpty {
            guard let source = sourceStore.sources.first(where: { $0.id == currentBook.sourceID }) else {
                errorMessage = "找不到对应书源，请先在“书源”中添加。"
                return
            }
            do {
                currentBook.chapters = try await service.catalog(for: currentBook, source: source)
                library.update(currentBook)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        await loadChapter(at: currentBook.lastReadChapterIndex)
    }

    private func loadChapter(at index: Int) async {
        guard currentBook.chapters.indices.contains(index) else { return }
        currentChapterIndex = index
        currentBook.lastReadChapterIndex = index
        library.update(currentBook)

        isLoading = true
        defer { isLoading = false }

        let chapter = currentBook.chapters[index]

        if currentBook.kind == .local {
            if let content = library.localContent(for: chapter) {
                chapterContent = content
            } else {
                errorMessage = "本地文件读取失败"
            }
            return
        }

        guard let source = sourceStore.sources.first(where: { $0.id == currentBook.sourceID }) else {
            errorMessage = "找不到对应书源"
            return
        }

        do {
            let content = try await service.content(for: chapter, source: source)
            chapterContent = content
            if currentBook.chapters.indices.contains(index) {
                currentBook.chapters[index].content = content
            }
            library.update(currentBook)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}