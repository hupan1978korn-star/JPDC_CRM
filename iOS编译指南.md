# JPDC CRM iOS 编译指南

**适用机型**：iPhone 11+（iOS 14+）

---

## 前置条件
- macOS 12+（必须，Windows 无法编译 iOS）
- Xcode 15+（App Store 下载）
- Flutter SDK 3.24（官网 https://flutter.dev 下载）
- CocoaPods：在终端执行 `sudo gem install cocoapods`

---

## 步骤

### 1. 解压源码
将 `JPDC_CRM_iOS_Source.zip` 解压到 Mac 桌面，得到文件夹 `tmp_flutter`

### 2. 安装依赖
```bash
cd ~/Desktop/tmp_flutter
flutter pub get
cd ios
pod install
cd ..
```

### 3. 打开 Xcode 项目
```bash
open ios/Runner.xcworkspace   # ⚠️ 注意是 .xcworkspace，不是 .xcodeproj
```

### 4. 配置签名
- Xcode 菜单 → Runner → Signing & Capabilities
- Team 选择你的 Apple ID（没有？免费注册一个 Apple ID 即可，不需要开发者账号）
- Bundle Identifier 改为唯一值，如 `com.yourname.jodccrm`

### 5. 连接 iPhone 编译
- 用数据线连接 iPhone
- 选择设备：Xcode 顶部 → 设备列表 → 选你的 iPhone
- 按 `⌘R`（Run）
- 首次运行需在 iPhone 设置 → 通用 → VPN与设备管理 → 信任证书

### 6. 导出 .ipa（可选，用于分发给其他人）
- Xcode 菜单 → Product → Archive
- 选 "Distribute App" → "Development" → 导出 .ipa

---

## 常见问题

| 问题 | 解决 |
|------|------|
| `pod: command not found` | `sudo gem install cocoapods -n /usr/local/bin` |
| 签名报错 | 免费 Apple ID 最多 3 个 App，检查是否已满 |
| `No valid signing identities` | Xcode → Preferences → Accounts → 登录你的 Apple ID → 点 "Download Manual Profiles" |

---

## 数据源说明
- App 内置默认连接 `http://192.168.8.46:8001`（公司内网）
- 安装后可在 App 内 Settings 页修改服务器地址
- 确保 iPhone 与后端服务器在同一 WiFi 网络

---

**编译成功后，你得到的是 .ipa 文件，可通过多种方式安装到 iPhone**：
- Xcode 直接安装（连数据线）
- 企业签名平台分发
- TestFlight（需要付费开发者账号 $99/年）
- 第三方签名服务（如 蒲公英 / fir.im）
