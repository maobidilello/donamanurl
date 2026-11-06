# 包子极速版 · 苹果原生客户端

基于 SwiftUI 的 iPhone 纯离线工程。客户端无需注册、无需登录，不请求远程接口；收藏、浏览记录、搜索历史和评分仅保存在本机。

## 功能

- 首页轮播、分类筛选、热门／高分／最近更新／每日／完结推荐。
- 人气、评分、更新榜单，以及保留当前分类的“查看更多”列表。
- 作品名称与作者搜索、搜索历史、作品详情、章节入口。
- 本机收藏与浏览记录、作品评分、个人中心、内置用户协议和隐私政策。
- 18 部内置漫画作品、18 张 AI 原创封面和 1 张横幅均随 APP 打包，断网也能正常浏览。
- 启动轮换页、远程接口、远程配置、网页跳转和外部浏览器打开功能均已移除。

> 当前版本提供漫画资料浏览；章节页仅显示内置的通用示例短文，不包含第三方漫画正文。

## 内容素材

漫画封面和横幅由开发者使用 AI 工具原创生成，应用图标为本地绘制的原创书本图形。作品数据位于 `BoleReader/Resources/books.json`，所有内容均从包内读取，不依赖第三方图片、远程素材或漫画服务。

## 环境要求

- macOS，Xcode 16 或兼容版本。
- iOS 15.0 及以上模拟器或 iPhone。
- 真机运行需要可用的 Apple 签名；发布需要 Apple Developer Program 账号。

工程无第三方 Swift 包依赖，不需要 CocoaPods、Swift Package Manager 或后端服务。

## 在 Mac 上运行

1. 用 Xcode 打开 `JMComic.xcodeproj`，选择共享 Scheme `BoleReader`。
2. 在 Signing & Capabilities 中选择开发团队。当前 Bundle ID 为 `com.bole.reader`。
3. 选择 iPhone 模拟器或已连接设备，执行 Product → Run。

当前工程由 Windows 环境维护，本机无法进行 macOS／Xcode 编译、模拟器或真机验证。云端工作流负责未签名编译检查；发布前仍应在不同系统版本的设备上验收。

## 离线与发布说明

- APP 不包含远程配置、远程内容切换、网页跳转或外部浏览器打开功能。
- Debug 和 Release 均未开放任意网络加载；所有页面只读取包内数据与本机存储。
- 应用评分当前为本机功能演示，不会写入 App Store 评价。
- `com.bole.reader` 是新的 Bundle ID。若用于 App Store，必须先在开发者后台和 App Store Connect 建立与之匹配的新 App ID、描述文件和商店档案，不能上传到旧 Bundle ID 的应用。
- 公开隐私政策、技术支持页和商店文案必须与当前版本一致，并在发布前确认所有素材与文案的使用权。

## GitHub 云端编译

将本目录作为 GitHub 仓库根目录后，打开 Actions → iOS Offline Build → Run workflow，或推送 `main` 分支触发。工作流直接编译原始源码，不做代码混淆，也不自动签名上传。

构建成功后可在 Artifacts 下载 `BoleReader-unsigned-ipa`，其中包含 `包子极速版-1.0.5-110-unsigned.ipa`。该 IPA 未签名，不能直接安装或提交 App Store。

## 静态检查

在整个工作区根目录执行：

```bash
python tools/check_ios_project.py
```

该脚本检查源文件、离线约束、基础括号结构、JSON、图片资源、应用图标、审核文案和 Xcode 配置。它不是 Swift 编译器，不能替代 Xcode 构建、模拟器或真机测试。

## 目录

```text
JMComic/
├── JMComic.xcodeproj/                 # Xcode 工程容器
└── BoleReader/
    ├── BoleReaderApp.swift            # 应用入口
    ├── AppState.swift                 # 离线状态、收藏与历史
    ├── FixtureStore.swift             # 包内作品数据
    ├── *View.swift                    # 原生页面
    ├── Components.swift               # 卡片、图片与通用组件
    ├── Assets.xcassets/               # 图标和 20 组本地图片
    └── Resources/books.json           # 18 部内置演示作品资料
```
