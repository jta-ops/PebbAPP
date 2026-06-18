import SwiftUI
import UserNotifications

struct AccountView: View {
    @StateObject private var api = PebbAPI.shared
    @Environment(\.dismiss) private var dismiss
    @State private var confirmSignOut = false
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined
    @State private var showUpgrade = false
    @AppStorage("pebb_appearance") private var appearance = "dark"

    var body: some View {
        ZStack {
            Color(hex: "0B0A12").ignoresSafeArea()

            Circle()
                .fill(Color(hex: "7C6FCD").opacity(0.18))
                .frame(width: 500, height: 500)
                .blur(radius: 110)
                .offset(y: -180)

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 12) {
                        if let acct = api.account {
                            if (acct.tier ?? "").isEmpty {
                                upgradeCard
                            }
                            planCard(acct)
                            channelsCard(acct)
                        } else {
                            ProgressView()
                                .tint(Color(hex: "7C6FCD"))
                                .padding(.vertical, 60)
                        }
                        usageStatsCard
                        notificationsCard
                        appearanceCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }

            VStack {
                Spacer()
                Button(action: { confirmSignOut = true }) {
                    Text("Sign out")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "F87171"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .liquidGlass(cornerRadius: 16, tint: Color(hex: "F87171"), tintOpacity: 0.06)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .task {
            try? await api.loadAccount()
            await refreshNotifStatus()
        }
        .alert("Sign out?", isPresented: $confirmSignOut) {
            Button("Cancel", role: .cancel) {}
            Button("Sign out", role: .destructive) { api.signOut(); dismiss() }
        } message: {
            Text("You'll need to log in again to use Pebb.")
        }
        .sheet(isPresented: $showUpgrade) { UpgradeView() }
    }

    private func refreshNotifStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notifStatus = settings.authorizationStatus
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text("Account")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: "EDEBF7"))
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "A09CBA"))
                    .frame(width: 36, height: 36)
                    .liquidGlass(cornerRadius: 18)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    // MARK: - Upgrade card (free tier only)
    private var upgradeCard: some View {
        Button { UIImpactFeedbackGenerator(style: .medium).impactOccurred(); showUpgrade = true } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Upgrade to Plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "EDEBF7"))
                    Text("Unlimited messages · Priority AI · Early features")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "A09CBA"))
                }
                Spacer()
                Text("⚡")
                    .font(.system(size: 28))
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [Color(hex: "7C6FCD").opacity(0.35), Color(hex: "4F46E5").opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "9B8FE8").opacity(0.45), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Plan card
    private func planCard(_ info: AccountInfo) -> some View {
        let tier = info.tier ?? ""
        let tierName = info.tier_name ?? (tier.isEmpty ? "Free" : tier.capitalized)
        let icon = tier.isEmpty ? "💬" : (tier == "plus" ? "⚡" : tier == "pro" ? "🚀" : tier == "max" ? "🌟" : "💎")
        let accentColor = tier.isEmpty ? Color(hex: "6E6A8A") : Color(hex: "34D399")

        return HStack(spacing: 14) {
            Text(icon)
                .font(.system(size: 28))
                .frame(width: 52, height: 52)
                .liquidGlass(cornerRadius: 16, tint: accentColor, tintOpacity: 0.08)

            VStack(alignment: .leading, spacing: 4) {
                Text("Plan")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "6E6A8A"))
                    .textCase(.uppercase)
                Text(tierName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(hex: "EDEBF7"))
            }
            Spacer()
            Text(tier.isEmpty ? "free" : "active")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .glassPill(tint: accentColor)
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20, tint: Color(hex: "7C6FCD"), tintOpacity: 0.04)
    }

    // MARK: - Channels card
    private func channelsCard(_ info: AccountInfo) -> some View {
        VStack(spacing: 0) {
            sectionHeader("Channels")
            glassChannelRow(icon: "📱", label: "Phone", value: info.phone, isLast: false)
            glassChannelRow(icon: "✉️", label: "Email", value: info.email, isLast: false)
            glassChannelRow(
                icon: "💬", label: "Telegram",
                value: info.tg_chats?.isEmpty == false ? "\(info.tg_chats!.count) linked" : nil,
                isLast: false
            )
            glassChannelRow(icon: "🎮", label: "Discord", value: info.discord, isLast: true)
        }
        .liquidGlass(cornerRadius: 20)
    }

    // MARK: - Usage stats card
    private var usageStatsCard: some View {
        VStack(spacing: 0) {
            sectionHeader("Usage")
            HStack(spacing: 0) {
                statItem(value: "\(api.messagesSent)", label: "Messages")
                Divider().frame(height: 36).overlay(Color.white.opacity(0.06))
                statItem(value: "\(BookmarksStore.shared.articles.count)", label: "Bookmarks")
                Divider().frame(height: 36).overlay(Color.white.opacity(0.06))
                statItem(value: api.account?.tier_name ?? "Free", label: "Plan")
            }
            .padding(.vertical, 16)
        }
        .liquidGlass(cornerRadius: 20)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "EDEBF7"))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "6E6A8A"))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Notifications card
    private var notificationsCard: some View {
        VStack(spacing: 0) {
            sectionHeader("Notifications")
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "F59E0B"))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "F59E0B").opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Push Notifications")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "EDEBF7"))
                    Text(notifStatusLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "6E6A8A"))
                }
                Spacer()
                notifActionButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .liquidGlass(cornerRadius: 20)
    }

    @ViewBuilder
    private var notifActionButton: some View {
        switch notifStatus {
        case .authorized, .ephemeral, .provisional:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: "34D399"))
        case .denied:
            Button("Open Settings") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color(hex: "7C6FCD"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "7C6FCD").opacity(0.15))
            .clipShape(Capsule())
        default:
            Button("Enable") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Task {
                    try? await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .badge, .sound])
                    await refreshNotifStatus()
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color(hex: "7C6FCD"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "7C6FCD").opacity(0.15))
            .clipShape(Capsule())
        }
    }

    private var notifStatusLabel: String {
        switch notifStatus {
        case .authorized, .ephemeral, .provisional: return "Enabled"
        case .denied: return "Blocked — tap to open Settings"
        default: return "Not yet enabled"
        }
    }

    // MARK: - Appearance card
    private var appearanceCard: some View {
        VStack(spacing: 0) {
            sectionHeader("Appearance")
            HStack(spacing: 8) {
                ForEach([("Dark", "moon.fill", "dark"), ("System", "circle.lefthalf.filled", "system")], id: \.0) { label, icon, value in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        appearance = value
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(label)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(appearance == value ? .white : Color(hex: "A09CBA"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(appearance == value ? Color(hex: "7C6FCD") : Color.white.opacity(0.05))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(appearance == value ? 0 : 0.1), lineWidth: 1))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appearance)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .liquidGlass(cornerRadius: 20)
    }

    // MARK: - Helpers
    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private func glassChannelRow(icon: String, label: String, value: String?, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 18))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "6E6A8A"))
                    Text(value ?? "not linked")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(value != nil ? Color(hex: "EDEBF7") : Color(hex: "4B5563"))
                }
                Spacer()
                if value != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "34D399"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Upgrade Sheet
struct UpgradeView: View {
    @Environment(\.dismiss) private var dismiss

    private let features: [(String, String, String)] = [
        ("Unlimited messages", "No daily cap on AI conversations", "infinity"),
        ("Priority AI", "Faster responses, always first in queue", "bolt.fill"),
        ("Early access", "Try new Pebb features before anyone else", "sparkles"),
        ("Multi-channel sync", "iPhone, Telegram, Discord — all in one", "arrow.triangle.branch"),
    ]

    var body: some View {
        ZStack {
            Color(hex: "0B0A12").ignoresSafeArea()
            Circle()
                .fill(Color(hex: "7C6FCD").opacity(0.22))
                .frame(width: 500, height: 500)
                .blur(radius: 100)
                .offset(y: -120)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "A09CBA"))
                            .frame(width: 36, height: 36)
                            .liquidGlass(cornerRadius: 18)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                Text("⚡")
                    .font(.system(size: 64))
                    .padding(.bottom, 8)

                Text("Pebb Plus")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "EDEBF7"))

                Text("Everything you need, nothing you don't.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "6E6A8A"))
                    .padding(.top, 6)
                    .padding(.bottom, 32)

                VStack(spacing: 10) {
                    ForEach(features, id: \.0) { title, subtitle, icon in
                        HStack(spacing: 14) {
                            Image(systemName: icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(hex: "9B8FE8"))
                                .frame(width: 36, height: 36)
                                .background(Color(hex: "7C6FCD").opacity(0.15))
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(hex: "EDEBF7"))
                                Text(subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "6E6A8A"))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .liquidGlass(cornerRadius: 16, tint: Color(hex: "7C6FCD"), tintOpacity: 0.03)
                        .padding(.horizontal, 20)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if let url = URL(string: "https://pebb.dev/upgrade") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Upgrade to Plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "A78BFA"), Color(hex: "7C6FCD")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color(hex: "7C6FCD").opacity(0.5), radius: 20)
                    }
                    Button("Maybe later") { dismiss() }
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "6E6A8A"))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}
