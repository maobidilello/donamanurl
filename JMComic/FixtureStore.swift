import Foundation

enum FixtureStore {
    static let comics: [Comic] = {
        guard let url = Bundle.main.url(forResource: "comics", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let comics = try? JSONDecoder().decode([Comic].self, from: data) else {
            return []
        }
        return comics.map { item in
            var comic = item
            if (1...17).contains(comic.id) {
                let ext = comic.id <= 9 ? "png" : "jpg"
                comic.cover = "/uploads/covers/review-\(comic.id).\(ext)"
            }
            return comic
        }
    }()

    static let categories = ["修真", "冒险", "后宫", "恋爱", "搞笑"].enumerated().map {
        ComicCategory(id: $0.offset + 1, name: $0.element, sort: $0.offset + 1)
    }

    static let banners = [
        ComicBanner(id: 1, title: "精选推荐一", image: "/uploads/covers/review-banner1.png", comicID: 1, sort: 1, enabled: 1),
        ComicBanner(id: 2, title: "精选推荐二", image: "/uploads/covers/review-banner2.jpg", comicID: 2, sort: 2, enabled: 1),
    ]

    static func home(category: String = "全部") -> HomeResponse {
        let filtered = category == "全部" ? comics : comics.filter { $0.category == category }
        return HomeResponse(
            banners: banners,
            categories: categories,
            hot: filtered.sorted { $0.popularity > $1.popularity },
            topRated: filtered.sorted { $0.score > $1.score },
            recent: filtered.sorted { $0.updateTime > $1.updateTime },
            completed: filtered.filter { $0.status == "已完结" }.sorted { $0.score > $1.score },
            daily: comics.first { $0.isDaily == 1 } ?? filtered.first
        )
    }

    static func sorted(_ mode: SortMode, category: String = "全部") -> [Comic] {
        let items = category == "全部" ? comics : comics.filter { $0.category == category }
        switch mode {
        case .hot: return items.sorted { $0.popularity > $1.popularity }
        case .rating: return items.sorted { $0.score > $1.score }
        case .update: return items.sorted { $0.updateTime > $1.updateTime }
        }
    }

    static func comic(id: Int) -> Comic? {
        guard var comic = comics.first(where: { $0.id == id }) else { return nil }
        let current = Int(comic.latestChapter.filter(\.isNumber)) ?? 100
        comic.chapters = (0..<12).map {
            Chapter(id: $0 + 1, title: "第\(max(1, current - $0))话", sort: max(1, current - $0))
        }
        return comic
    }

    static func search(_ keyword: String) -> [Comic] {
        let value = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !value.isEmpty else { return [] }
        return comics.filter { "\($0.title)\($0.author)".lowercased().contains(value) }
    }
}
