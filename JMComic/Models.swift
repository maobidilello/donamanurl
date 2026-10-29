import Foundation

struct Comic: Identifiable, Codable, Hashable {
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

struct ComicCategory: Identifiable, Codable, Hashable {
    let id: Int
    var name: String
    var sort: Int
}

struct ComicBanner: Identifiable, Codable, Hashable {
    let id: Int
    var title: String
    var image: String
    var comicID: Int
    var sort: Int
    var enabled: Int

    enum CodingKeys: String, CodingKey {
        case id, title, image, sort, enabled
        case comicID = "comic_id"
    }

    var assetName: String {
        URL(fileURLWithPath: image).deletingPathExtension().lastPathComponent
    }
}

struct HomeResponse: Codable {
    var banners: [ComicBanner]
    var categories: [ComicCategory]
    var hot: [Comic]
    var topRated: [Comic]
    var recent: [Comic]
    var completed: [Comic]
    var daily: Comic?
}

struct ComicListResponse: Codable {
    var list: [Comic]
    var total: Int
    var page: Int
    var pageSize: Int?
}

struct RedirectConfig: Codable {
    var enabled: Bool
    var url: String

    static let disabled = RedirectConfig(enabled: false, url: "")
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
