# JM 漫天堂 · 苹果原生客户端

基于 SwiftUI 的 iPhone 原生工程，连接项目现有的 ThinkPHP 8 API。客户端无需注册、无需用户登录；收藏、浏览记录、搜索历史和评分优先保存在本机。

## 功能

- 首页轮播、分类筛选、热门／高分／最近更新／每日／完结推荐。
- 人气、评分、更新榜单，以及保留当前分类的“查看更多”列表。
- 漫画名称与作者搜索、搜索历史、漫画详情、章节入口。
- 本机收藏与浏览记录、漫画评分、个人中心、用户协议和隐私政策。
- 支持后台“跳转设置”：进入主页后读取开关和链接，开启时显示“官方公告”弹窗，点击“确认”才通过系统浏览器打开链接。
- 跳转配置缓存 30 秒，下拉刷新时可主动更新；网络失败时不显示弹窗，保证包内内容正常访问。
- 18 部漫画、全部封面和 2 张横幅均随 APP 打包，断网也能正常浏览；启动轮换页及图片已全部移除。
- 搜索、榜单、详情、章节、收藏和历史全部在本机处理，后台只保留跳转配置接口。

> 章节正文阅读器尚未实现。章节入口会明确提示正文待上传，没有伪造漫画正文。

## 环境要求

- macOS，Xcode 16 或兼容版本。
- iOS 15.0 及以上模拟器或 iPhone，已兼容截图设备的 iOS 15.5。
- 真机运行需要可用的 Apple 签名；发布需要 Apple Developer Program 账号。
- 后端要求见项目根目录 `README.md`。

工程无第三方 Swift 包依赖，不需要 CocoaPods 或 Swift Package Manager 下载依赖。

## 在 Mac 上运行

1. 用 Xcode 打开 `JMComic.xcodeproj`。
2. 打开 `JMComic/AppConfig.swift`，确认 `apiBaseURL` 为正式 HTTPS API 域名；该地址只用于 `/redirect`。
3. 在 Xcode 的 Signing & Capabilities 中选择开发团队。当前 Bundle ID 为 `com.jmantang.comic`，如与已有账号冲突可修改。
4. 选择 iPhone 模拟器或已连接设备，执行 Product → Run。

当前工程由 Windows 环境交付，未在 macOS／Xcode 中编译，未进行模拟器或真机验证。首次在 Xcode 打开后，应先处理编译器或签名工具实际给出的错误，再进行界面验收。漫画与图片不依赖后端，可在断网模拟器或设备上直接验证。

## 跳转配置联调

1. 登录 ThinkPHP + Layui 管理后台，打开“跳转设置”。
2. 填写以 `https://` 或 `http://` 开头的有效链接，开启并保存。
3. 冷启动并进入主页后读取最新配置，开启状态下显示“官方公告”弹窗，不会自动跳转。
4. 用户点击“确认”后才通过系统浏览器打开链接；后台关闭时不会显示弹窗。

配置获取失败或设备离线时不显示弹窗；从未取得配置时也默认关闭。无效链接或系统无法打开链接时会显示提示，不影响包内内容。

## 网络与发布说明

- 仅 Debug 配置开启了本地 HTTP 调试所需的 ATS 例外，便于连接开发机。
- Release 未开放任意 HTTP。正式上架必须使用 HTTPS，不要把开发环境的 HTTP 例外带到生产版本。
- 如果后台配置的跳转网页使用 HTTP，生产环境同样应改为 HTTPS。
- 上架前请补充真实隐私政策、内容授权、账号与证书配置，并按苹果审核要求检查外链内容和业务合规性。
- 应用评分当前为本机功能演示，不会写入 App Store 评价。

## GitHub 混淆与云端编译

将本目录作为 GitHub 仓库根目录后，打开仓库的 Actions → iOS Obfuscated Build → Run workflow。默认先编译原始源码，再在工作副本中混淆 Swift 标识符并重新编译，不会覆盖仓库里的原始源码。

构建成功后可在 Artifacts 下载：

- `JMComic-unsigned-ipa`：未签名 IPA，必须使用你自己的证书重新签名后才能安装或提交。
- `JMComic-obfuscation-map-and-source`：混淆后的 Swift 源码及 `conversionMap.txt`。映射表用于解析该版本的崩溃日志，应与对应 IPA 一起保存。

也可以在工作流中关闭 `obfuscate`，仅验证原始源码构建。混淆工具依赖 SourceKit；若原始构建成功而混淆构建失败，应根据日志检查混淆结果，不要把未经重新编译和真机验证的混淆版本直接发布。

## 静态检查

在项目根目录执行：

```bash
python tools/check_ios_project.py
```

该脚本检查源文件、基础括号结构、JSON、图片资源、应用图标和 Xcode 配置。它不是 Swift 编译器，不能替代 Xcode 构建、模拟器或真机测试。

## 目录

```text
JMComic/
├── JMComic.xcodeproj/          # Xcode 工程
└── JMComic/
    ├── JMComicApp.swift        # 应用入口
    ├── AppState.swift          # 全局状态、跳转、收藏与历史
    ├── APIClient.swift         # ThinkPHP API
    ├── FixtureStore.swift      # 离线演示数据
    ├── *View.swift             # 原生页面
    ├── Components.swift        # 卡片、图片与通用组件
    ├── Assets.xcassets/        # 图标和本地图片
    └── Resources/comics.json   # 18 部演示漫画
```
