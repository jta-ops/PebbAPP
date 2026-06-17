import SwiftUI

struct OnboardingView: View {
    @StateObject private var api = PebbAPI.shared
    @State private var tab: AuthTab = .phone
    @State private var phone = ""
    @State private var email = ""
    @State private var code = ""
    @State private var showOTP = false
    @State private var showEmailSent = false
    @State private var errorMsg = ""
    @State private var isLoading = false
    @State private var pulse = false
    @State private var btnPressed = false
    @FocusState private var codeFocused: Bool

    enum AuthTab: Hashable { case phone, email }

    var body: some View {
        ZStack {
            pulsingBackground
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    logoSection
                    Spacer().frame(height: 36)
                    loginCard
                        .frame(maxWidth: 400)
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Background
    private var pulsingBackground: some View {
        ZStack {
            Color(hex: "0B0A12")
            Circle()
                .fill(Color(hex: "7C6FCD").opacity(pulse ? 0.22 : 0.13))
                .frame(width: 600, height: 600)
                .blur(radius: 120)
                .offset(y: -300)
                .scaleEffect(pulse ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: pulse)
        }
        .ignoresSafeArea()
        .onAppear { pulse = true }
    }

    // MARK: - Logo
    private var logoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkle")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color(hex: "7C6FCD"))
                .frame(width: 80, height: 80)
                .background(Color(hex: "141320"))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(hex: "7C6FCD").opacity(0.3), lineWidth: 1))
                .shadow(color: Color(hex: "7C6FCD").opacity(0.4), radius: 24)

            Text("Pebb")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "EDEBF7"))

            Text("Your personal AI, always within reach.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Login Card
    private var loginCard: some View {
        VStack(spacing: 0) {
            tabRow
            if !showOTP && !showEmailSent {
                inputSection
            } else if showOTP {
                otpSection
            } else {
                emailSentSection
            }
        }
        .liquidGlass(cornerRadius: 28, tint: Color(hex: "7C6FCD"), tintOpacity: 0.04)
    }

    // MARK: - Tab Row
    private var tabRow: some View {
        HStack(spacing: 4) {
            ForEach([AuthTab.phone, .email], id: \.self) { t in
                Button {
                    tab = t
                    reset()
                } label: {
                    Text(t == .phone ? "Phone" : "Email")
                        .fixedSize(horizontal: true, vertical: false)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(tab == t ? Color(hex: "EDEBF7") : Color(hex: "6E6A8A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(tab == t ? Color(hex: "252340") : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                }
            }
        }
        .padding(4)
        .background(Color(hex: "1E1C30"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 22)
    }

    // MARK: - Input Section
    @ViewBuilder
    private var inputSection: some View {
        VStack(spacing: 12) {
            if tab == .phone {
                VStack(alignment: .leading, spacing: 6) {
                    label("Phone number")
                    TextField("+61 400 000 000", text: $phone)
                        .keyboardType(.phonePad)
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "EDEBF7"))
                        .padding(13)
                        .background(Color(hex: "1E1C30"))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(hex: "FFFFFF").opacity(0.1), lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    label("Email address")
                    TextField("you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "EDEBF7"))
                        .padding(13)
                        .background(Color(hex: "1E1C30"))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(hex: "FFFFFF").opacity(0.1), lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                }
            }

            errorView

            ctaButton(
                label: isLoading ? "Sending…" : (tab == .phone ? "Send code" : "Send magic link"),
                action: sendCode
            )
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    // MARK: - OTP Section
    @ViewBuilder
    private var otpSection: some View {
        VStack(spacing: 12) {
            Text("code sent to \(tab == .phone ? phone : email)")
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 6) {
                label("6-digit code")
                TextField("000000", text: $code)
                    .keyboardType(.numberPad)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "EDEBF7"))
                    .multilineTextAlignment(.center)
                    .padding(13)
                    .background(Color(hex: "1E1C30"))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(hex: "FFFFFF").opacity(0.1), lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                    .focused($codeFocused)
                    .onChange(of: code) { _, val in
                        if val.count >= 6 && !isLoading { verifyCode() }
                    }
            }

            errorView

            ctaButton(
                label: isLoading ? "Verifying…" : "Continue",
                action: verifyCode
            )

            Button("← different \(tab == .phone ? "number" : "email")") {
                reset()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color(hex: "6E6A8A"))
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                codeFocused = true
            }
        }
    }

    // MARK: - Email Sent
    private var emailSentSection: some View {
        VStack(spacing: 16) {
            Text("✉️").font(.system(size: 40))
            Text("check your inbox — tap the link in the email to sign in.")
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Button("use a different email") { reset() }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "6E6A8A"))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
    }

    // MARK: - Helpers
    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color(hex: "6E6A8A"))
            .textCase(.uppercase)
    }

    @ViewBuilder
    private var errorView: some View {
        if !errorMsg.isEmpty {
            Text(errorMsg)
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "F87171"))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    private func ctaButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading { ProgressView().tint(.white) }
                Text(label)
                    .fixedSize(horizontal: true, vertical: false)
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "7C6FCD"))
            .clipShape(Capsule())
            .foregroundStyle(Color.white)
            .scaleEffect(btnPressed ? 0.96 : 1.0)
        }
        .disabled(isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { btnPressed = true } }
                .onEnded { _ in withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { btnPressed = false } }
        )
    }

    private func reset() {
        code = ""
        errorMsg = ""
        isLoading = false
        showOTP = false
        showEmailSent = false
    }

    private func sendCode() {
        guard !isLoading else { return }
        errorMsg = ""
        isLoading = true
        Task {
            do {
                if tab == .phone {
                    let _ = try await api.requestCode(phone: phone)
                    showOTP = true
                } else {
                    let _ = try await api.requestEmailCode(email: email)
                    showEmailSent = true
                }
            } catch {
                errorMsg = "couldn't send — check your details"
            }
            isLoading = false
        }
    }

    private func verifyCode() {
        guard !isLoading, code.count >= 6 else { return }
        errorMsg = ""
        isLoading = true
        Task {
            do {
                if tab == .phone {
                    let _ = try await api.verifyCode(phone: phone, code: code)
                } else {
                    let _ = try await api.verifyEmailCode(email: email, code: code)
                }
            } catch {
                errorMsg = error.localizedDescription
                isLoading = false
            }
        }
    }
}
