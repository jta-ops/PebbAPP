import Foundation
import UIKit

// MARK: - Message
enum MessageStatus: Equatable { case sending, sent, delivered, failed }

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: String
    var content: String
    let imageURL: String?
    let timestamp: String
    var status: MessageStatus
    var isVoice: Bool
    var isStreaming: Bool

    var isUser: Bool { role == "user" }

    init(role: String, content: String, imageURL: String? = nil,
         status: MessageStatus = .delivered, isVoice: Bool = false, isStreaming: Bool = false) {
        self.role = role
        self.content = content
        self.imageURL = imageURL
        self.status = status
        self.isVoice = isVoice
        self.isStreaming = isStreaming
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        self.timestamp = f.string(from: Date())
    }
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
struct NewsArticle: Codable, Identifiable, Hashable {
    static func == (lhs: NewsArticle, rhs: NewsArticle) -> Bool { lhs.slug == rhs.slug }
    func hash(into hasher: inout Hasher) { hasher.combine(slug) }
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
        didSet {
            UserDefaults.standard.set(token, forKey: "pebb_token")
            // mirror into the App Group so the Share Extension can post on our behalf
            UserDefaults(suiteName: "group.dev.pebb.app")?.set(token, forKey: "pebb_token")
        }
    }
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var account: AccountInfo?
    @Published var isLoggedIn: Bool = false

    private init() {
        token = UserDefaults.standard.string(forKey: "pebb_token") ?? ""
        isLoggedIn = !token.isEmpty
    }

    /// Completes the onboarding wizard (mock auth). Persists a session token so
    /// login survives relaunches and the notification sheet doesn't bounce the
    /// user back to the wizard.
    @MainActor
    func completeMockLogin(name: String = "") {
        if token.isEmpty {
            token = "demo-" + UUID().uuidString
        }
        if !name.isEmpty {
            UserDefaults.standard.set(name, forKey: "pebb_name")
        }
        isLoggedIn = true
    }

    var displayName: String { UserDefaults.standard.string(forKey: "pebb_name") ?? "" }
    var messagesSent: Int { UserDefaults.standard.integer(forKey: "pebb_msg_count") }

    var greeting: String {
        let n = displayName
        return n.isEmpty ? "hey! what's on your mind? 💜" : "hey \(n)! what's on your mind? 💜"
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
        // Don't auto-sign-out on 401 — demo/mock sessions have no real token and
        // would otherwise bounce the user straight back to onboarding.
        if (resp as? HTTPURLResponse)?.statusCode == 401 {
            if messages.isEmpty {
                messages = [ChatMessage(role: "assistant", content: greeting)]
            }
            return
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        if let msgs = json["messages"] as? [[String: Any]] {
            messages = msgs.map { m in
                ChatMessage(role: m["role"] as? String ?? "", content: m["content"] as? String ?? "", imageURL: m["image"] as? String)
            }
        }
        if messages.isEmpty {
            messages = [ChatMessage(role: "assistant", content: greeting)]
        }
    }

    @MainActor
    func sendMessage(_ text: String, imageData: Data? = nil, isVoice: Bool = false) async throws {
        let userMsg = ChatMessage(role: "user", content: text, status: .sending, isVoice: isVoice)
        messages.append(userMsg)
        let userIdx = messages.count - 1
        UserDefaults.standard.set(messagesSent + 1, forKey: "pebb_msg_count")
        isTyping = true
        LiveActivityManager.shared.startThinking()

        do {
            var imageUrl: String? = nil
            if let imgData = imageData {
                imageUrl = try await uploadImage(imgData)
            }
            // user message accepted by server
            if messages.indices.contains(userIdx) { messages[userIdx].status = .sent }

            let url = URL(string: "\(baseURL)/webchat/api/chat")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            var body: [String: Any] = ["token": token, "message": text]
            if let imageUrl { body["image"] = imageUrl }
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, resp) = try await URLSession.shared.data(for: req)
            isTyping = false
            if messages.indices.contains(userIdx) { messages[userIdx].status = .delivered }
            if (resp as? HTTPURLResponse)?.statusCode == 401 {
                await streamIn("you're in demo mode — connect your number in Account to chat for real 💜")
                return
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            if let replies = json["messages"] as? [String] {
                for reply in replies {
                    await streamIn(reply)
                }
                if let last = replies.last {
                    LiveActivityManager.shared.finishThinking(preview: last)
                    LiveActivityManager.shared.updateWidgetData(lastMessage: last)
                }
            }
        } catch {
            isTyping = false
            if messages.indices.contains(userIdx) { messages[userIdx].status = .failed }
            LiveActivityManager.shared.endAll()
            await streamIn("couldn't reach pebb — check your connection and try again")
        }
    }

    /// Reveals an assistant message character-by-character (typewriter effect).
    @MainActor
    func streamIn(_ fullText: String) async {
        messages.append(ChatMessage(role: "assistant", content: "", isStreaming: true))
        let idx = messages.count - 1
        var shown = ""
        // chunk by a few chars for speed; slower for short replies so it's visible
        let chars = Array(fullText)
        let step = max(1, chars.count / 240)
        var i = 0
        while i < chars.count {
            let end = min(i + step, chars.count)
            shown += String(chars[i..<end])
            if messages.indices.contains(idx) { messages[idx].content = shown }
            i = end
            try? await Task.sleep(nanoseconds: 14_000_000)
        }
        if messages.indices.contains(idx) { messages[idx].isStreaming = false }
    }

    /// One-shot chat used by the Siri "Ask Pebb" intent — returns the reply text.
    @MainActor
    func askOneShot(_ text: String) async -> String {
        do {
            let url = URL(string: "\(baseURL)/webchat/api/chat")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["token": token, "message": text])
            let (data, _) = try await URLSession.shared.data(for: req)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            if let replies = json["messages"] as? [String], let first = replies.first {
                return first
            }
            return "I couldn't get an answer right now."
        } catch {
            return "I couldn't reach Pebb. Check your connection."
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
        if let top = resp.articles.first {
            LiveActivityManager.shared.updateWidgetData(
                headline: top.title, category: top.category, source: top.source
            )
        }
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
