import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore
    @State private var showImporter = false
    @State private var importErrorMessage: String?

    var body: some View {
        NavigationView {
            Group {
                if library.books.isEmpty {
                    emptyView
                } else {
                    bookList
                }
            }
            .navigationTitle("书架")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.plainText, .data],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("导入失败", isPresented: Binding(
                get: { importErrorMessage != nil },
                set: { if !$0 { importErrorMessage = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(importErrorMessage ?? "")
            }
        }
    }

    private var bookList: some View {
        List {
            ForEach(library.books) { book in
                NavigationLink {
                    ReaderView(book: book)
                } label: {
                    BookRow(book: book)
                }
            }
            .onDelete { offsets in
                let booksToDelete = offsets.map { library.books[$0] }
                for book in booksToDelete {
                    library.delete(book)
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("书架空空如也")
                .font(.title3)
            Text("点击右上角 + 导入 TXT 小说，或到“搜索”页使用书源在线找书。")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                try library.importLocalFile(from: url)
            } catch {
                importErrorMessage = error.localizedDescription
            }
        case .failure(let error):
            importErrorMessage = error.localizedDescription
        }
    }
}

private struct BookRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: book.kind == .local ? "doc.text" : "globe")
                .font(.title2)
                .foregroundColor(book.kind == .local ? .blue : .green)
                .frame(width: 40, height: 40)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(book.kind == .local ? "本地" : "在线")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(book.kind == .local ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                        .clipShape(Capsule())
                    if let author = book.author, !author.isEmpty {
                        Text(author)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            if !book.chapters.isEmpty {
                Text("\(book.chapters.count)章")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}