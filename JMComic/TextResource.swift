import Foundation

enum TextResource {
    static func load(_ name: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "内容暂未配置"
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var subtitle: String { load("Subtitle") }
    static var about: String { load("About") }
    static var userAgreement: String { load("UserAgreement") }
    static var privacy: String { load("Privacy") }
}
