import SwiftUI
import UIKit
import UserNotifications

struct NotifyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var swing = false
    @State private var isRequesting = false

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
                    .rotationEffect(.degrees(swing ? -10 : 10))
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: swing)
                    .onAppear { swing = true }

                Text("Stay in the loop")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "EDEBF7"))
                    .padding(.top, 28)

                Text("Get notified when Pebb messages you — even when the app is closed.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "6E6A8A"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 10)
                    .padding(.horizontal, 40)

                Spacer()

                VStack(spacing: 0) {
                    Button(action: enableNotifs) {
                        HStack(spacing: 8) {
                            if isRequesting { ProgressView().tint(.white) }
                            Text(isRequesting ? "Enabling…" : "Enable notifications")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "7C6FCD"))
                        .clipShape(Capsule())
                        .foregroundStyle(Color.white)
                    }
                    .disabled(isRequesting)

                    Button("Skip for now") { dismiss() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "6E6A8A"))
                        .padding(.top, 14)
                }
                .padding(.horizontal, 40)

                Spacer().frame(height: 40)
            }
        }
    }

    private func enableNotifs() {
        isRequesting = true
        Task {
            try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
                dismiss()
            }
        }
    }
}
