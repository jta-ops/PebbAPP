import SwiftUI

struct NotifyView: View {
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color(hex: "0B0A12").ignoresSafeArea()
            Circle()
                .fill(Color(hex: "7C6FCD").opacity(0.18))
                .frame(width: 500, height: 500)
                .blur(radius: 100)
                .offset(y: -80)

            VStack(spacing: 0) {
                Spacer()

                Text("🔔")
                    .font(.system(size: 72))
                    .rotationEffect(.degrees(isLoading ? -8 : 8))
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isLoading)
                    .onAppear { isLoading = true }

                Text("Stay in the loop")
                    .font(.custom("Fraunces", size: 28).weight(.bold))
                    .foregroundColor(Color(hex: "EDEBF7"))
                    .padding(.top, 28)

                Text("Get notified when Pebb messages you — even when the app is closed.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6E6A8A"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 10)
                    .padding(.horizontal, 40)

                Spacer()

                VStack(spacing: 0) {
                    Button(action: enableNotifs) {
                        HStack(spacing: 8) {
                            if isLoading { ProgressView().tint(.white) }
                            Text(isLoading ? "Enabling…" : "Enable notifications")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "7C6FCD"))
                        .clipShape(Capsule())
                        .foregroundColor(.white)
                    }
                    .disabled(isLoading)

                    Button("Skip for now") {
                        withAnimation { PebbAPI.shared.isLoggedIn = true }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "6E6A8A"))
                    .padding(.top, 12)
                }
                .padding(.horizontal, 40)

                Spacer().frame(height: 40)
            }
        }
    }

    private func enableNotifs() {
        isLoading = true
        Task {
            try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
                withAnimation { PebbAPI.shared.isLoggedIn = true }
            }
            isLoading = false
        }
    }
}
