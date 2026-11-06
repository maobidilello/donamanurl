import Foundation

enum FixtureStore {
    static let books: [Book] = {
        guard let url = Bundle.main.url(forResource: "books", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let books = try? JSONDecoder().decode([Book].self, from: data) else {
            return []
        }
        return books
    }()

    static let categories = ["科幻", "都市", "奇幻", "治愈", "武侠", "冒险", "悬疑"].enumerated().map {
        BookCategory(id: $0.offset + 1, name: $0.element, sort: $0.offset + 1)
    }

    static let banners = [
        BookBanner(id: 1, title: "精选推荐一", image: "review-banner1", bookID: 1, sort: 1, enabled: 1),
        BookBanner(id: 2, title: "精选推荐二", image: "review-banner2", bookID: 2, sort: 2, enabled: 1),
    ]

    static func home(category: String = "全部") -> HomeResponse {
        let filtered = category == "全部" ? books : books.filter { $0.category == category }
        return HomeResponse(
            banners: banners,
            categories: categories,
            hot: filtered.sorted { $0.popularity > $1.popularity },
            topRated: filtered.sorted { $0.score > $1.score },
            recent: filtered.sorted { $0.updateTime > $1.updateTime },
            completed: filtered.filter { $0.status == "已完结" }.sorted { $0.score > $1.score },
            daily: books.first { $0.isDaily == 1 } ?? filtered.first
        )
    }

    static func sorted(_ mode: SortMode, category: String = "全部") -> [Book] {
        let items = category == "全部" ? books : books.filter { $0.category == category }
        switch mode {
        case .hot: return items.sorted { $0.popularity > $1.popularity }
        case .rating: return items.sorted { $0.score > $1.score }
        case .update: return items.sorted { $0.updateTime > $1.updateTime }
        }
    }

    static func book(id: Int) -> Book? {
        guard var book = books.first(where: { $0.id == id }) else { return nil }
        let current = Int(book.latestChapter.filter(\.isNumber)) ?? 100
        book.chapters = (0..<12).map {
            Chapter(id: $0 + 1, title: "第\(max(1, current - $0))话", sort: max(1, current - $0))
        }
        return book
    }

    static func search(_ keyword: String) -> [Book] {
        let value = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !value.isEmpty else { return [] }
        return books.filter { "\($0.title)\($0.author)".lowercased().contains(value) }
    }
}
