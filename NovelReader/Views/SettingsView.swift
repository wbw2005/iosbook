import SwiftUI

struct SettingsView: View {
    @AppStorage("readerFontSize") private var fontSize = 18.0
    @AppStorage("readerLineSpacing") private var lineSpacing = 8.0
    @AppStorage("readerTheme") private var readerTheme = "system"

    var body: some View {
        NavigationView {
            Form {
                Section("阅读设置") {
                    HStack {
                        Text("字号")
                        Spacer()
                        Slider(value: $fontSize, in: 12...32, step: 1)
                            .frame(width: 180)
                        Text("\(Int(fontSize))")
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                    }

                    HStack {
                        Text("行距")
                        Spacer()
                        Slider(value: $lineSpacing, in: 0...20, step: 1)
                            .frame(width: 180)
                        Text("\(Int(lineSpacing))")
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                    }

                    Picker("主题", selection: $readerTheme) {
                        Text("跟随系统").tag("system")
                        Text("白色").tag("light")
                        Text("羊皮纸").tag("sepia")
                        Text("夜间").tag("dark")
                    }
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    Text("本地导入支持 TXT；在线阅读需要自己添加可用书源。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("设置")
        }
    }
}