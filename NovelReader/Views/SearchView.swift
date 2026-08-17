import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var sourceStore: SourceStore

    @State private var keyword = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false
    @State private var searchMessage: String?

    private let service = BookSourceService()

    var body: some View {
        NavigationView {
            List {
                if isSearching {
                    HStack {
                        Spacer()
                        ProgressView("正在搜索…")
                        Spacer()
                    }
                    .padding(.vertical, 12)
                } else if results.isEmpty && !keyword.isEmpty {
                    Text("没有找到结果，或当前书源不可用。")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                }

                ForEach(results) { result in
                    NavigationLink {
                        ReaderView(book: result.book)
                    } label: {
                        SearchResultRow(result: result)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("搜索")
            .searchable(text: $keyword, placement: .navigationBarDrawer(displayMode: .always), prompt: "书名 / 作者")
            .onSubmit(of: .search) {
                Task { await search() }
            }
            .alert("提示", isPresented: Binding(
                get: { searchMessage != nil },
                set: { if !$0 { searchMessage = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(searchMessage ?? "")
            }
        }
    }

    private func search() async {
        guard !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSearching = true
        results = []
        let found = await service.search(keyword: keyword, in: sourceStore.sources)
        results = found
        isSearching = false
        if found.isEmpty {
            searchMessage = "没有搜索到结果，请检查书源是否可用。"
        }
    }
}

private struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(result.book.title)
                .font(.headline)
                .lineLimit(1)
            HStack(spacing: 8) {
                Text(result.source.name)
                    .font(.caption)
                    .foregroundColor(.blue)
                if let author = result.book.author, !author.isEmpty {
                    Text(author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}