import SwiftUI

struct SafariDestination: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

@MainActor
final class AppState: ObservableObject {
    @Published var home = FixtureStore.home()
    @Published var redirectPrompt: RedirectConfig?
    @Published var safariDestination: SafariDestination?
    @Published var redirectDiagnostic = "诊断：等待后台配置"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var notice: String?
    @Published var favorites: [Comic] = []
    @Published var history: [Comic] = []
    @Published var ratings: [Int: Int] = [:]
    @Published var appRating = 0
    @Published var searchHistory: [String] = []

    private var cachedRedirect = RedirectConfig.disabled
    private var redirectFetchedAt = Date.distantPast
    private var redirectTask: Task<RedirectConfig, Never>?

    init() {
        let defaults = UserDefaults.standard
        favorites = Self.read([Comic].self, key: "favorites") ?? []
        history = Self.read([Comic].self, key: "history") ?? []
        ratings = (defaults.dictionary(forKey: "comicRatings") as? [String: Int])?.reduce(into: [:]) { result, item in
            if let id = Int(item.key) { result[id] = item.value }
        } ?? [:]
        appRating = defaults.integer(forKey: "appRating")
        searchHistory = defaults.stringArray(forKey: "searchHistory") ?? []
        cachedRedirect = Self.read(RedirectConfig.self, key: "redirectConfig") ?? .disabled
        Task { await self.loadInitial() }
    }

    func loadInitial() async {
        await refreshHome()
        await prepareRedirectPrompt()
    }

    func refreshHome(category: String = "全部") async {
        home = FixtureStore.home(category: category)
        errorMessage = nil
        isLoading = false
    }

    func ranked(_ mode: SortMode, category: String = "全部") async -> [Comic] {
        FixtureStore.sorted(mode, category: category)
    }

    func search(_ keyword: String) async -> [Comic] {
        let value = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return [] }
        searchHistory = [value] + searchHistory.filter { $0 != value }
        searchHistory = Array(searchHistory.prefix(10))
        UserDefaults.standard.set(searchHistory, forKey: "searchHistory")
        return FixtureStore.search(value)
    }

    func clearSearchHistory() {
        searchHistory = []
        UserDefaults.standard.removeObject(forKey: "searchHistory")
    }

    func detail(id: Int) async -> Comic? {
        FixtureStore.comic(id: id)
    }

    func refreshRedirect(force: Bool = false) async -> RedirectConfig {
        if !force, Date().timeIntervalSince(redirectFetchedAt) < AppConfig.redirectCacheInterval {
            return cachedRedirect
        }
        if let redirectTask { return await redirectTask.value }
        let task = Task<RedirectConfig, Never> {
            do {
                let config = try await APIClient.shared.redirect()
                Self.save(config, key: "redirectConfig")
                return config
            } catch {
                // 离线或后台不可用时留在 APP 内，保证包内漫画和图片正常访问。
                return .disabled
            }
        }
        redirectTask = task
        cachedRedirect = await task.value
        redirectFetchedAt = Date()
        redirectTask = nil
        return cachedRedirect
    }

    /// 主页加载后只展示公告，不自动跳转；用户点击确认才打开外链。
    private func prepareRedirectPrompt() async {
        let config = await refreshRedirect(force: true)
        guard config.enabled else {
            redirectDiagnostic = "诊断：后台未开启跳转或接口读取失败"
            return
        }
        guard Self.validRedirectURL(config.url) != nil else {
            redirectDiagnostic = "诊断错误：后台链接无效"
            notice = "跳转链接无效，请联系管理员检查配置"
            return
        }
        redirectPrompt = config
        redirectDiagnostic = "诊断：公告已显示，等待点击确认"
    }

    func confirmRedirect() {
        redirectDiagnostic = "诊断：1/4 确认按钮已执行"
        guard let config = redirectPrompt else {
            redirectDiagnostic = "诊断错误：确认时公告配置为空"
            return
        }
        redirectPrompt = nil
        guard let url = Self.validRedirectURL(config.url) else {
            redirectDiagnostic = "诊断错误：确认时链接无效"
            notice = "跳转链接无效，请联系管理员检查配置"
            return
        }
        redirectDiagnostic = "诊断：2/4 链接有效，等待展示 Safari"
        Task { @MainActor [weak self] in
            // 等公告完全关闭后，再由根页面全屏展示 Safari，兼容 iOS 15。
            try? await Task.sleep(nanoseconds: 650_000_000)
            self?.redirectDiagnostic = "诊断：3/4 已请求展示 Safari"
            self?.safariDestination = SafariDestination(url: url)
        }
    }

    private static func validRedirectURL(_ value: String) -> URL? {
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host?.isEmpty == false else { return nil }
        return url
    }

    func toggleFavorite(_ comic: Comic) {
        if let index = favorites.firstIndex(where: { $0.id == comic.id }) {
            favorites.remove(at: index)
            notice = "已移出书架"
        } else {
            favorites.insert(comic, at: 0)
            notice = "已加入书架"
        }
        Self.save(favorites, key: "favorites")
    }

    func isFavorite(_ id: Int) -> Bool {
        favorites.contains { $0.id == id }
    }

    func recordHistory(_ comic: Comic) {
        history.removeAll { $0.id == comic.id }
        history.insert(comic, at: 0)
        history = Array(history.prefix(60))
        Self.save(history, key: "history")
    }

    func clearHistory() {
        history = []
        Self.save(history, key: "history")
    }

    func rate(_ comic: Comic, score: Int) {
        ratings[comic.id] = score
        var stored = UserDefaults.standard.dictionary(forKey: "comicRatings") as? [String: Int] ?? [:]
        stored[String(comic.id)] = score
        UserDefaults.standard.set(stored, forKey: "comicRatings")
        notice = "评分成功"
    }

    func rateApp(_ score: Int) {
        appRating = score
        UserDefaults.standard.set(score, forKey: "appRating")
        notice = "感谢你的评价"
    }

    private static func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: key) }
    }

    private static func read<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
