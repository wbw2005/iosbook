import SwiftUI

struct SourceListView: View {
    @EnvironmentObject private var sourceStore: SourceStore

    @State private var showAdd = false
    @State private var editingSource: BookSource?
    @State private var showJSONImport = false

    var body: some View {
        NavigationView {
            Group {
                if sourceStore.sources.isEmpty {
                    emptyView
                } else {
                    sourceList
                }
            }
            .navigationTitle("书源")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showJSONImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }

                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                SourceEditView(source: nil)
            }
            .sheet(item: $editingSource) { source in
                SourceEditView(source: source)
            }
            .sheet(isPresented: $showJSONImport) {
                SourceImportView()
            }
        }
    }

    private var sourceList: some View {
        List {
            ForEach(sourceStore.sources) { source in
                HStack {
                    Button {
                        editingSource = source
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .foregroundColor(source.enabled ? .green : .gray)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(source.searchURL)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { source.enabled },
                        set: { _ in sourceStore.toggle(source) }
                    ))
                    .labelsHidden()
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    sourceStore.delete(sourceStore.sources[index])
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("还没有书源")
                .font(.title3)
            Text("点击右上角 + 手动添加，或导入 JSON 书源。")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}