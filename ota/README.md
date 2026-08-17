# OTA 在线安装（方案三）

本目录是「小说阅读器」App 的 OTA（itms-services）在线安装配置。

## 重要前提
OTA 在线安装**只支持以下两种签名**，其他签名装不上：

| 签名类型 | 描述文件特征 | OTA |
|---|---|---|
| 企业证书签名 | `ProvisionsAllDevices = true` | 支持（需在手机信任证书） |
| Ad Hoc 分发签名 | 含你的设备 UDID，`get-task-allow = false` | 支持 |
| 免费个人 Apple ID | `get-task-allow = true`，7 天有效 | **不支持** |

> ⚠️ 免费个人 Apple ID 签名的 IPA 走 OTA 会提示“无法安装应用程序”，只能用
> USB/Finder/爱思助手（USB 或已配对的 WiFi）安装。

## 使用方法
1. 用**企业证书**或**Ad Hoc** 重新签名 `NovelReader`，得到 `.ipa`
2. 上传到 GitHub Release：
   - 打开 https://github.com/wbw2005/iosbook/releases/new
   - 附件命名为 **`NovelReader.ipa`**（大小写一致）
3. 核对 `ota/manifest.plist` 中的 `bundle-identifier` 是否与重新签名后的 IPA 一致：
   - 查看 IPA 内 `Payload/<App>.app/Info.plist` 的 `CFBundleIdentifier`
   - 不一致就改 manifest 再提交
4. 手机 Safari 打开安装地址：

```
itms-services://?action=download-manifest&url=https://raw.githubusercontent.com/wbw2005/iosbook/master/ota/manifest.plist
```

5. 弹窗点「安装」
6. 企业签名还需：设置 → 通用 → VPN 与设备管理 → 信任开发者证书
7. Ad Hoc 需确认描述文件已包含本机 UDID

## 常用地址
- 安装地址（含 itms-services 协议）：
  `itms-services://?action=download-manifest&url=https://raw.githubusercontent.com/wbw2005/iosbook/master/ota/manifest.plist`
- Manifest 文件：https://raw.githubusercontent.com/wbw2005/iosbook/master/ota/manifest.plist
- IPA 下载：https://github.com/wbw2005/iosbook/releases/latest/download/NovelReader.ipa