import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var home = FixtureStore.home()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var notice: String?
    @Published var favorites: [Comic] = []
    @Published var history: [Comic] = []
    @Published var ratings: [Int: Int] = [:]
    @Published var appRating = 0
    @Published var searchHistory: [String] = []

    init() {
        let defaults = UserDefaults.standard
        favorites = Self.read([Comic].self, key: "favorites") ?? []
        history = Self.read([Comic].self, key: "history") ?? []
        ratings = (defaults.dictionary(forKey: "comicRatings") as? [String: Int])?.reduce(into: [:]) { result, item in
            if let id = Int(item.key) { result[id] = item.value }
        } ?? [:]
        appRating = defaults.integer(forKey: "appRating")
        searchHistory = defaults.stringArray(forKey: "searchHistory") ?? []
        Task { await self.loadInitial() }
    }

    func loadInitial() async {
        await refreshHome()
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
