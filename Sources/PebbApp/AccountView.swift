import SwiftUI

struct AccountView: View {
    @StateObject private var api = PebbAPI.shared
    @Environment(\.dismiss) private var dismiss
    @State private var confirmSignOut = false

    var body: some View {
        ZStack {
            Color(hex: "141320").ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider().overlay(Color(hex: "FFFFFF").opacity(0.07))
                bodyContent
                Spacer()
                Divider().overlay(Color(hex: "FFFFFF").opacity(0.07))
                footer
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .task { try? await api.loadAccount() }
    }

    private var header: some View {
        HStack {
            Text("Account")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "EDEBF7"))
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "6E6A8A"))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "1E1C30"))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    private var bodyContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let acct = api.account {
                    planRow(acct)
                    sectionTitle("Channels")
                    channelRow(icon: "📱", label: "Phone", value: acct.phone ?? "not linked", linked: acct.phone != nil)
                    channelRow(icon: "✉️", label: "Email", value: acct.email ?? "not linked", linked: acct.email != nil)
                    channelRow(icon: "💬", label: "Telegram", value: acct.tg_chats?.isEmpty == false ? "\(acct.tg_chats!.count) linked" : nil, linked: acct.tg_chats?.isEmpty == false)
                    channelRow(icon: "🎮", label: "Discord", value: acct.discord ?? nil, linked: acct.discord != nil)
                } else {
                    ProgressView()
                        .tint(Color(hex: "7C6FCD"))
                        .padding(.vertical, 40)
                }
            }
        }
    }

    private var footer: some View {
        Button(action: { confirmSignOut = true }) {
            Text("Sign out")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "F87171"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "F87171").opacity(0.3), lineWidth: 1.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .alert("Sign out?", isPresented: $confirmSignOut) {
            Button("Cancel", role: .cancel) {}
            Button("Sign out", role: .destructive) {
                api.signOut()
                dismiss()
            }
        } message: {
            Text("You'll need to log in again to use Pebb.")
        }
    }

    private func planRow(_ info: AccountInfo) -> some View {
        let tier = info.tier ?? ""
        let tierName = info.tier_name ?? (tier.isEmpty ? "Free" : tier)
        let icon = tier.isEmpty ? "💬" : (tier == "plus" ? "⚡" : tier == "pro" ? "🚀" : tier == "max" ? "🌟" : "💎")
        let badge = info.sub_until ?? (tier.isEmpty ? "free" : "active")

        return HStack(spacing: 14) {
            Text(icon).font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text("Plan").font(.system(size: 13)).foregroundColor(Color(hex: "6E6A8A"))
                Text(tierName).font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "EDEBF7"))
            }
            Spacer()
            Text(badge)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(tier.isEmpty ? Color(hex: "6E6A8A") : Color(hex: "34D399"))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background((tier.isEmpty ? Color(hex: "6E6A8A") : Color(hex: "34D399")).opacity(0.12))
                .overlay(Capsule().stroke((tier.isEmpty ? Color(hex: "6E6A8A") : Color(hex: "34D399")).opacity(0.2), lineWidth: 1))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(Divider().overlay(Color(hex: "FFFFFF").opacity(0.07)), alignment: .bottom)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Color(hex: "6E6A8A"))
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    private func channelRow(icon: String, label: String, value: String?, linked: Bool) -> some View {
        HStack(spacing: 14) {
            Text(icon).font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 13)).foregroundColor(Color(hex: "6E6A8A"))
                Text(value ?? "not linked")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(linked ? Color(hex: "EDEBF7") : Color(hex: "6E6A8A"))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(Divider().overlay(Color(hex: "FFFFFF").opacity(0.07)), alignment: .bottom)
    }
}
