import Foundation
import UIKit

// MARK: - Message
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: String
    let content: String
    let imageURL: String?

    var isUser: Bool { role == "user" }
}

// MARK: - Account Info
struct AccountInfo: Codable {
    var phone: String?
    var email: String?
    var tier: String?
    var tier_name: String?
    var sub_until: String?
    var stripe_customer: String?
    var tg_chats: [TGChannel]?
    var discord: String?
    var discord_servers: [DiscordServer]?
}

struct TGChannel: Codable {
    let chat_id: String?
    let title: String?
}

struct DiscordServer: Codable {
    let id: String
    let name: String?
    let active: Bool?
}

// MARK: - News Article
struct NewsArticle: Codable, Identifiable {
    var id: String { slug }
    let slug: String
    let title: String
    let summary: String
    let category: String
    let source: String
    let source_url: String
    let published_at: String
    let image_url: String
    let image_prompt: String?
    let content_html: String?
    let content_text: String?
    let sources: [String]?
}

struct NewsListResponse: Codable {
    let articles: [NewsArticle]
}

// MARK: - API Client
class PebbAPI: ObservableObject {
    static let shared = PebbAPI()

    private let baseURL = "https://pebb.dev"

    @Published var token: String {
        didSet { UserDefaults.standard.set(token, forKey: "pebb_token") }
    }
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var account: AccountInfo?
    @Published var isLoggedIn: Bool = false

    private init() {
        token = UserDefaults.standard.string(forKey: "pebb_token") ?? ""
        isLoggedIn = !token.isEmpty
    }

    // MARK: - Auth
    @MainActor
    func requestCode(phone: String) async throws -> [String: Any] {
        let url = URL(string: "\(baseURL)/webchat/api/request-code")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["phone": phone])
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    @MainActor
    func verifyCode(phone: String, code: String) async throws -> String {
        let url = URL(string: "\(baseURL)/webchat/api/verify")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["phone": phone, "code": code])
        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        if let t = json["token"] as? String {
            self.token = t
            self.isLoggedIn = true
            return t
        }
        throw NSError(domain: "pebb", code: 401, userInfo: [NSLocalizedDescriptionKey: json["error"] as? String ?? "wrong code"])
    }

    @MainActor
    func requestEmailCode(email: String) async throws -> [String: Any] {
        let url = URL(string: "\(baseURL)/webchat/api/request-email-code")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    @MainActor
    func verifyEmailCode(email: String, code: String) async throws -> String {
        let url = URL(string: "\(baseURL)/webchat/api/verify-email")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "code": code])
        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        if let t = json["token"] as? String {
            self.token = t
            self.isLoggedIn = true
            return t
        }
        throw NSError(domain: "pebb", code: 401, userInfo: [NSLocalizedDescriptionKey: json["error"] as? String ?? "wrong code"])
    }

    // MARK: - Chat
    @MainActor
    func loadHistory() async throws {
        let url = URL(string: "\(baseURL)/webchat/api/history")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["token": token])
        let (data, resp) = try await URLSession.shared.data(for: req)
        if (resp as? HTTPURLResponse)?.statusCode == 401 { signOut(); return }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        if let msgs = json["messages"] as? [[String: Any]] {
            messages = msgs.map { m in
                ChatMessage(role: m["role"] as? String ?? "", content: m["content"] as? String ?? "", imageURL: m["image"] as? String)
            }
        }
        if messages.isEmpty {
            messages = [ChatMessage(role: "assistant", content: "hey! what's on your mind? 💜", imageURL: nil)]
        }
    }

    @MainActor
    func sendMessage(_ text: String, imageData: Data? = nil) async throws {
        let userMsg = ChatMessage(role: "user", content: text, imageURL: nil)
        messages.append(userMsg)
        isTyping = true

        var imageUrl: String? = nil
        if let imgData = imageData {
            imageUrl = try await uploadImage(imgData)
        }

        let url = URL(string: "\(baseURL)/webchat/api/chat")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "token": token,
            "message": text,
            "image": imageUrl ?? "",
        ])
        let (data, resp) = try await URLSession.shared.data(for: req)
        if (resp as? HTTPURLResponse)?.statusCode == 401 { signOut(); return }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        isTyping = false
        if let replies = json["messages"] as? [String] {
            for reply in replies {
                messages.append(ChatMessage(role: "assistant", content: reply, imageURL: nil))
            }
        }
    }

    @MainActor
    private func uploadImage(_ data: Data) async throws -> String {
        let url = URL(string: "\(baseURL)/webchat/api/upload")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        let boundary = UUID().uuidString
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"token\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(token)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body
        let (respData, _) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any] ?? [:]
        return json["url"] as? String ?? ""
    }

    // MARK: - News
    @Published var newsArticles: [NewsArticle] = []
    @Published var isLoadingNews = false

    @MainActor
    func loadNews() async throws {
        isLoadingNews = true
        defer { isLoadingNews = false }
        let url = URL(string: "\(baseURL)/news/api/list")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let resp = try JSONDecoder().decode(NewsListResponse.self, from: data)
        newsArticles = resp.articles
    }

    @MainActor
    func loadArticle(slug: String) async throws -> NewsArticle {
        let url = URL(string: "\(baseURL)/news/api/article/\(slug)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(NewsArticle.self, from: data)
    }

    // MARK: - Account
    @MainActor
    func loadAccount() async throws {
        let url = URL(string: "\(baseURL)/account/api/info?s=\(token)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        account = try JSONDecoder().decode(AccountInfo.self, from: data)
    }

    @MainActor
    func signOut() {
        Task {
            let url = URL(string: "\(baseURL)/account/api/signout")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONSerialization.data(withJSONObject: ["session": token])
            try? await URLSession.shared.data(for: req)
        }
        token = ""
        isLoggedIn = false
        messages = []
        account = nil
    }
}
