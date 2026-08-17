import SwiftUI

struct SourceEditView: View {
    @EnvironmentObject private var sourceStore: SourceStore
    @Environment(\.dismiss) private var dismiss

    @State private var model: BookSource

    init(source: BookSource?) {
        _model = State(initialValue: source ?? BookSource(name: "", searchURL: ""))
    }

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("名称", text: $model.name)
                    TextField("搜索 URL（用 {keyword} 代替关键词）", text: $model.searchURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    Toggle("启用", isOn: $model.enabled)
                }

                Section("搜索 JSON 路径") {
                    TextField("书籍列表路径", text: $model.bookListPath)
                        .autocapitalization(.none)
                    TextField("书名路径", text: $model.bookNamePath)
                        .autocapitalization(.none)
                    TextField("作者路径", text: $model.bookAuthorPath)
                        .autocapitalization(.none)
                    TextField("书籍 URL 路径", text: $model.bookUrlPath)
                        .autocapitalization(.none)
                    TextField("书籍 URL 前缀", text: $model.bookUrlPrefix)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section("目录 JSON 路径") {
                    TextField("目录 URL（用 {bookUrl} 代替书籍 URL）", text: Binding(
                        get: { model.catalogURL ?? "" },
                        set: { model.catalogURL = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    TextField("章节列表路径", text: $model.catalogListPath)
                        .autocapitalization(.none)
                    TextField("章节标题路径", text: $model.catalogTitlePath)
                        .autocapitalization(.none)
                    TextField("章节 URL 路径", text: $model.catalogUrlPath)
                        .autocapitalization(.none)
                    TextField("章节 URL 前缀", text: $model.catalogUrlPrefix)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section("正文") {
                    TextField("正文 URL（用 {chapterUrl} 代替章节 URL）", text: Binding(
                        get: { model.contentURL ?? "" },
                        set: { model.contentURL = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    Picker("正文类型", selection: $model.contentType) {
                        Text("JSON").tag("json")
                        Text("纯文本").tag("text")
                    }
                    .pickerStyle(.segmented)
                    TextField("正文内容路径（JSON 时）", text: $model.contentPath)
                        .autocapitalization(.none)
                    TextField("编码（UTF-8 / GB18030）", text: $model.contentCharset)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle(model.name.isEmpty ? "新建书源" : model.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.searchURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        var saved = model
        saved.name = saved.name.trimmingCharacters(in: .whitespacesAndNewlines)
        saved.searchURL = saved.searchURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if sourceStore.sources.contains(where: { $0.id == saved.id }) {
            sourceStore.update(saved)
        } else {
            sourceStore.add(saved)
        }
        dismiss()
    }
}