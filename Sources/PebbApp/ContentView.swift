import SwiftUI

struct ContentView: View {
    @StateObject private var session = PebbSession.shared

    var body: some View {
        if session.phone.isEmpty {
            OnboardingView()
        } else {
            ChatView()
        }
    }
}
