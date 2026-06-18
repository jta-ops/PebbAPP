import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var api = PebbAPI.shared
    @State private var showNotify = false
    @State private var selectedTab = 0
    @State private var tabScales: [CGFloat] = [1, 1]

    var body: some View {
        Group {
            if !api.isLoggedIn {
                OnboardingView()
                    .transition(.opacity)
            } else {
                mainTabView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: api.isLoggedIn)
        .sheet(isPresented: $showNotify) {
            NotifyView()
        }
        .onChange(of: api.isLoggedIn) { _, loggedIn in
            if loggedIn {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    DispatchQueue.main.async {
                        if settings.authorizationStatus != .authorized {
                            showNotify = true
                        }
                    }
                }
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(0)
            NewsTabView()
                .tabItem {
                    Label("News", systemImage: "newspaper.fill")
                }
                .tag(1)
        }
        .tint(Color(hex: "7C6FCD"))
        .onChange(of: selectedTab) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
