import Foundation

struct APIEnvelope<T: Decodable>: Decodable {
    let code: Int
    let msg: String
    let data: T?
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "接口地址无效"
        case .invalidResponse: "接口返回格式不正确"
        case .server(let message): message
        }
    }
}

/// 后台只提供跳转配置；漫画、图片、收藏和历史均在 APP 包内或本机处理。
final class APIClient {
    static let shared = APIClient()
    private let decoder = JSONDecoder()
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AppConfig.requestTimeout
        configuration.timeoutIntervalForResource = AppConfig.requestTimeout
        session = URLSession(configuration: configuration)
    }

    func redirect() async throws -> RedirectConfig {
        guard let url = URL(string: AppConfig.apiBaseURL + "/redirect") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        let envelope = try decoder.decode(APIEnvelope<RedirectConfig>.self, from: data)
        guard http.statusCode < 400, envelope.code == 0, let result = envelope.data else {
            throw APIError.server(envelope.msg)
        }
        return result
    }
}
