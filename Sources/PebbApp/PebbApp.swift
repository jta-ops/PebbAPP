import SwiftUI
import UserNotifications

@main
struct PebbApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("pebb_appearance") private var appearance = "dark"

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "system": return nil
        case "light": return .light
        default: return .dark
        }
    }
}

// MARK: - App Delegate (push notification actions)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()
        return true
    }

    private func registerNotificationCategories() {
        let replyAction = UNTextInputNotificationAction(
            identifier: "PEBB_REPLY",
            title: "Reply",
            options: [.foreground],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Message Pebb…"
        )
        let openAction = UNNotificationAction(
            identifier: "PEBB_OPEN",
            title: "Open Chat",
            options: [.foreground]
        )
        let messageCategory = UNNotificationCategory(
            identifier: "PEBB_MESSAGE",
            actions: [replyAction, openAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([messageCategory])
    }

    // Show banner + sound even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle reply action from notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "PEBB_REPLY",
           let textResponse = response as? UNTextInputNotificationResponse,
           !textResponse.userText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task {
                try? await PebbAPI.shared.sendMessage(textResponse.userText)
                completionHandler()
            }
        } else {
            completionHandler()
        }
    }
}

// MARK: - Root
struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showSplash = false
            }
        }
    }
}
