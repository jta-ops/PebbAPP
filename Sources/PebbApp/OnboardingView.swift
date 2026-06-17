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

    enum AuthTab { case phone, email }

    var body: some View {
        ZStack {
            Color(hex: "0B0A12").ignoresSafeArea()
            radialGlow

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    logoSection
                    Spacer().frame(height: 36)
                    loginCard
                    Spacer()
                }
                .padding(.horizontal, 28)
            }
        }
    }

    private var radialGlow: some View {
        Circle()
            .fill(Color(hex: "7C6FCD").opacity(0.22))
            .frame(width: 600, height: 600)
            .blur(radius: 120)
            .offset(y: -300)
    }

    private var logoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkle")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color(hex: "7C6FCD"))
                .frame(width: 76, height: 76)
                .background(Color(hex: "141320"))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: "7C6FCD").opacity(0.3), lineWidth: 1))
                .shadow(color: Color(hex: "7C6FCD").opacity(0.35), radius: 20)

            Text("Pebb")
                .font(.custom("Fraunces", size: 30).weight(.bold))
                .foregroundColor(Color(hex: "EDEBF7"))

            Text("Your personal AI, always within reach.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6E6A8A"))
                .multilineTextAlignment(.center)
        }
    }

    private var loginCard: some View {
        VStack(spacing: 0) {
            tabRow

            if !showOTP && !showEmailSent {
                inputSection
            } else if showOTP {
                otpSection
            } else if showEmailSent {
                emailSentSection
            }
        }
        .background(Color(hex: "141320"))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(hex: "FFFFFF").opacity(0.12), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private var tabRow: some View {
        HStack(spacing: 4) {
            Button { tab = .phone; reset() } label: {
                Text("Phone")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tab == .phone ? Color(hex: "EDEBF7") : Color(hex: "6E6A8A"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(tab == .phone ? Color(hex: "252340") : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            Button { tab = .email; reset() } label: {
                Text("Email")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tab == .email ? Color(hex: "EDEBF7") : Color(hex: "6E6A8A"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(tab == .email ? Color(hex: "252340") : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            }
        }
        .padding(4)
        .background(Color(hex: "1E1C30"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 22)
    }

    @ViewBuilder
    private var inputSection: some View {
        VStack(spacing: 12) {
            if tab == .phone {
                VStack(alignment: .leading, spacing: 6) {
                    label("Phone number")
                    TextField("+61 400 000 000", text: $phone)
                        .keyboardType(.phonePad)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "EDEBF7"))
                        .padding(13)
                        .background(Color(hex: "1E1C30"))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(hex: "FFFFFF").opacity(0.12), lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    label("Email address")
                    TextField("you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "EDEBF7"))
                        .padding(13)
                        .background(Color(hex: "1E1C30"))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(hex: "FFFFFF").opacity(0.12), lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                }
            }

            errorText

            Button(action: sendCode) {
                HStack(spacing: 8) {
                    if isLoading { ProgressView().tint(.white) }
                    Text(isLoading ? "Sending…" : (tab == .phone ? "Send code" : "Send magic link"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "7C6FCD"))
                .clipShape(Capsule())
                .foregroundColor(.white)
            }
            .disabled(isLoading)
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    @ViewBuilder
    private var otpSection: some View {
        VStack(spacing: 12) {
            Text("code sent to \(tab == .phone ? phone : email)")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "6E6A8A"))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 6) {
                label("6-digit code")
                TextField("000000", text: $code)
                    .keyboardType(.numberPad)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "EDEBF7"))
                    .multilineTextAlignment(.center)
                    .padding(13)
                    .background(Color(hex: "1E1C30"))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(hex: "FFFFFF").opacity(0.12), lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }

            errorText

            Button(action: verifyCode) {
                HStack(spacing: 8) {
                    if isLoading { ProgressView().tint(.white) }
                    Text(isLoading ? "Verifying…" : "Continue")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "7C6FCD"))
                .clipShape(Capsule())
                .foregroundColor(.white)
            }
            .disabled(isLoading)

            Button("← different \(tab == .phone ? "number" : "email")") {
                reset(); showOTP = false; showEmailSent = false
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color(hex: "6E6A8A"))
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    private var emailSentSection: some View {
        VStack(spacing: 16) {
            Text("✉️")
                .font(.system(size: 40))
            Text("check your inbox — tap the link in the email to sign in.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6E6A8A"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button("use a different email") {
                reset(); showEmailSent = false
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color(hex: "6E6A8A"))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color(hex: "6E6A8A"))
            .textCase(.uppercase)
    }

    private var errorText: some View {
        Text(errorMsg)
            .font(.system(size: 12))
            .foregroundColor(Color(hex: "F87171"))
            .frame(minHeight: 16)
    }

    private func reset() {
        code = ""
        errorMsg = ""
        isLoading = false
        showOTP = false
        showEmailSent = false
    }

    private func sendCode() {
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
                errorMsg = ""
            } catch {
                errorMsg = "couldn't send — check your details"
            }
            isLoading = false
        }
    }

    private func verifyCode() {
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
            }
            isLoading = false
        }
    }
}
