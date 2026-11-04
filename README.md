# 啵乐漫画极速版 · 苹果原生客户端

基于 SwiftUI 的 iPhone 纯离线工程。客户端无需注册、无需登录，不请求远程接口；收藏、浏览记录、搜索历史和评分仅保存在本机。

## 功能

- 首页轮播、分类筛选、热门／高分／最近更新／每日／完结推荐。
- 人气、评分、更新榜单，以及保留当前分类的“查看更多”列表。
- 漫画名称与作者搜索、搜索历史、漫画详情、章节入口。
- 本机收藏与浏览记录、漫画评分、个人中心、内置用户协议和隐私政策。
- 18 部漫画、全部封面和 2 张横幅均随 APP 打包，断网也能正常浏览；启动轮换页及图片已全部移除。

> 章节正文阅读器尚未实现。章节入口会明确提示正文等待作者更新，没有伪造漫画正文。

## 环境要求

- macOS，Xcode 16 或兼容版本。
- iOS 15.0 及以上模拟器或 iPhone。
- 真机运行需要可用的 Apple 签名；发布需要 Apple Developer Program 账号。

工程无第三方 Swift 包依赖，不需要 CocoaPods、Swift Package Manager 或后端服务。

## 在 Mac 上运行

1. 用 Xcode 打开 `JMComic.xcodeproj`。
2. 在 Signing & Capabilities 中选择开发团队。Bundle ID 为 `com.jmantang.comic`。
3. 选择 iPhone 模拟器或已连接设备，执行 Product → Run。

当前工程由 Windows 环境维护，本机无法进行 macOS／Xcode 编译、模拟器或真机验证。云端工作流负责编译和签名；发布前仍应在不同系统版本的设备上验收。

## 离线与发布说明

- APP 不包含远程配置、远程内容切换、网页跳转或外部浏览器打开功能。
- Debug 和 Release 均未开放任意网络加载；所有页面只读取包内数据与本机存储。
- 应用评分当前为本机功能演示，不会写入 App Store 评价。
- 上架前仍须确认漫画名称、封面、简介及宣传素材的内容授权，并确保隐私说明和实际行为一致。

## GitHub 云端编译

将本目录作为 GitHub 仓库根目录后，打开 Actions → iOS Offline Build → Run workflow。工作流直接编译原始源码，不做代码混淆。

构建成功后可在 Artifacts 下载 `JMComic-unsigned-ipa`。该 IPA 未签名，安装或提交前必须使用自己的证书签名。App Store 签名上传由 iOS App Store Sign and Upload 工作流完成。

## 静态检查

在项目根目录执行：

```bash
python tools/check_ios_project.py
```

该脚本检查源文件、离线约束、基础括号结构、JSON、图片资源、应用图标和 Xcode 配置。它不是 Swift 编译器，不能替代 Xcode 构建、模拟器或真机测试。

## 目录

```text
JMComic/
├── JMComic.xcodeproj/          # Xcode 工程
└── JMComic/
    ├── JMComicApp.swift        # 应用入口
    ├── AppState.swift          # 离线状态、收藏与历史
    ├── FixtureStore.swift      # 包内漫画数据
    ├── *View.swift             # 原生页面
    ├── Components.swift        # 卡片、图片与通用组件
    ├── Assets.xcassets/        # 图标和本地图片
    └── Resources/comics.json   # 18 部内置漫画资料
```
