import Foundation

enum AppConfig {
    /// 正式 HTTPS API；本地调试时可改为电脑局域网地址。
    static let apiBaseURL = "https://dm.kingome.shop/api"
    static let requestTimeout: TimeInterval = 2.5
    static let redirectCacheInterval: TimeInterval = 30
}
