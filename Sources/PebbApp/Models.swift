import Foundation

struct Message: Identifiable, Equatable {
    let id: UUID
    let role: Role
    let text: String
    let timestamp: Date

    enum Role { case user, assistant }

    init(role: Role, text: String) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.timestamp = Date()
    }
}

// Pebb API — phone number stored in UserDefaults on first launch
class PebbSession: ObservableObject {
    static let shared = PebbSession()

    @Published var phone: String = UserDefaults.standard.string(forKey: "pebb_phone") ?? ""
    @Published var messages: [Message] = []
    @Published var isTyping = false

    private let baseURL = "https://pebb.dev"

    func setPhone(_ p: String) {
        phone = p
        UserDefaults.standard.set(p, forKey: "pebb_phone")
    }

    @MainActor
    func send(_ text: String) async {
        let userMsg = Message(role: .user, text: text)
        messages.append(userMsg)
        isTyping = true

        do {
            let reply = try await callAPI(text: text)
            let parts = reply.components(separatedBy: "---").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            for part in parts {
                messages.append(Message(role: .assistant, text: part))
            }
        } catch {
            messages.append(Message(role: .assistant, text: "sorry, couldn't reach pebb — check your connection"))
        }
        isTyping = false
    }

    private func callAPI(text: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/chat") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["phone": phone, "message": text, "channel": "ios"]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 30
        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["reply"] as? String ?? "..."
    }
}
