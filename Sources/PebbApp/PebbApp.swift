import SwiftUI

@main
struct PebbApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

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
