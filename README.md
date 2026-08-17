# NovelReader

iOS 小说阅读器，SwiftUI 编写，支持：

- 本地 TXT 导入与章节解析
- JSON 书源搜索、目录、正文阅读
- GitHub Actions 编译产出 unsigned IPA
- 爱思助手签名安装

## 使用

```bash
brew install xcodegen
xcodegen generate
open NovelReader.xcodeproj
```

## GitHub Actions

推送后运行 **Build Unsigned IPA**，下载 `NovelReader-unsigned.ipa`，用爱思助手签名安装。

详见 `docs/爱思助手签名.md`。