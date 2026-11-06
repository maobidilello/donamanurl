import Foundation

struct Book: Identifiable, Codable, Hashable {
    let id: Int
    var title: String
    var author: String
    var cover: String
    var category: String
    var description: String
    var status: String
    var score: Double
    var popularity: Int64
    var favorites: Int64
    var latestChapter: String
    var updateTime: String
    var recommended: Int
    var isDaily: Int
    var chapters: [Chapter]?

    enum CodingKeys: String, CodingKey {
        case id, title, author, cover, category, description, status, score, popularity, favorites, chapters
        case latestChapter = "latest_chapter"
        case updateTime = "update_time"
        case recommended
        case isDaily = "is_daily"
    }

    var assetName: String {
        URL(fileURLWithPath: cover).deletingPathExtension().lastPathComponent
    }
}

struct Chapter: Identifiable, Codable, Hashable {
    let id: Int
    var title: String
    var sort: Int
}

struct BookCategory: Identifiable, Codable, Hashable {
    let id: Int
    var name: String
    var sort: Int
}

struct BookBanner: Identifiable, Codable, Hashable {
    let id: Int
    var title: String
    var image: String
    var bookID: Int
    var sort: Int
    var enabled: Int

    enum CodingKeys: String, CodingKey {
        case id, title, image, sort, enabled
        case bookID = "book_id"
    }

    var assetName: String {
        URL(fileURLWithPath: image).deletingPathExtension().lastPathComponent
    }
}

struct HomeResponse: Codable {
    var banners: [BookBanner]
    var categories: [BookCategory]
    var hot: [Book]
    var topRated: [Book]
    var recent: [Book]
    var completed: [Book]
    var daily: Book?
}

struct BookListResponse: Codable {
    var list: [Book]
    var total: Int
    var page: Int
    var pageSize: Int?
}

enum SortMode: String, CaseIterable, Identifiable {
    case hot, rating, update
    var id: String { rawValue }
    var title: String {
        switch self {
        case .hot: "人气"
        case .rating: "评分"
        case .update: "更新"
        }
    }
}
