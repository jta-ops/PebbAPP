import AppIntents
import SwiftUI

/// "Hey Siri, ask Pebb …" — sends a message to Pebb and speaks the reply.
@available(iOS 16.0, *)
struct AskPebbIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Pebb"
    static var description = IntentDescription("Send a question to Pebb and get an answer.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Message", requestValueDialog: "What do you want to ask Pebb?")
    var message: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let reply = await PebbAPI.shared.askOneShot(message)
        return .result(dialog: IntentDialog(stringLiteral: reply))
    }
}

/// "Hey Siri, open Pebb chat"
@available(iOS 16.0, *)
struct OpenPebbChatIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Pebb Chat"
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

@available(iOS 16.0, *)
struct PebbShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskPebbIntent(),
            phrases: [
                "Ask \(.applicationName) something",
                "Ask \(.applicationName)",
                "Chat with \(.applicationName)"
            ],
            shortTitle: "Ask Pebb",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: OpenPebbChatIntent(),
            phrases: ["Open \(.applicationName)", "Open \(.applicationName) chat"],
            shortTitle: "Open Pebb",
            systemImageName: "message.fill"
        )
    }
}
