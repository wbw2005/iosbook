import SwiftUI

struct SourceImportView: View {
    @EnvironmentObject private var sourceStore: SourceStore
    @Environment(\.dismiss) private var dismiss

    @State private var jsonText = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                TextEditor(text: $jsonText)
                    .font(.system(.footnote, design: .monospaced))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3))
                    )
                    .padding()

                Text("支持单个书源 JSON 或书源数组 JSON")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("导入书源")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入") {
                        importSources()
                    }
                    .disabled(jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("导入失败", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func importSources() {
        guard let data = jsonText.data(using: .utf8) else { return }

        if let sources = try? JSONDecoder().decode([BookSource].self, from: data) {
            for source in sources {
                sourceStore.add(source)
            }
            dismiss()
            return
        }

        if let source = try? JSONDecoder().decode(BookSource.self, from: data) {
            sourceStore.add(source)
            dismiss()
            return
        }

        errorMessage = "JSON 格式不正确，请检查字段。"
    }
}