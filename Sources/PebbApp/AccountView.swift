import SwiftUI

struct AccountView: View {
    @StateObject private var api = PebbAPI.shared
    @Environment(\.dismiss) private var dismiss
    @State private var confirmSignOut = false

    var body: some View {
        ZStack {
            Color(hex: "0B0A12").ignoresSafeArea()

            // Ambient glow behind glass
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
                            planCard(acct)
                            channelsCard(acct)
                        } else {
                            ProgressView()
                                .tint(Color(hex: "7C6FCD"))
                                .padding(.vertical, 60)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }

            // Floating sign-out at bottom
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
        .task { try? await api.loadAccount() }
        .alert("Sign out?", isPresented: $confirmSignOut) {
            Button("Cancel", role: .cancel) {}
            Button("Sign out", role: .destructive) { api.signOut(); dismiss() }
        } message: {
            Text("You'll need to log in again to use Pebb.")
        }
    }

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
