import SwiftUI

struct OnboardingView: View {
    @StateObject private var session = PebbSession.shared
    @State private var phone = ""
    @FocusState private var focused: Bool
    @State private var stage: Int = 0   // 0=hidden 1=logo 2=text 3=input 4=button
    @State private var buttonPressed = false
    @State private var logoRotate = false

    var digits: String { phone.filter { $0.isNumber } }
    var canContinue: Bool { digits.count >= 9 }

    var body: some View {
        ZStack {
            AnimatedBackground()

            VStack(spacing: 0) {
                Spacer()

                // ── Logo ─────────────────────────────────────────────────
                ZStack {
                    // Outer breathe ring
                    Circle()
                        .stroke(Color(hex: "7C6FCD").opacity(0.12), lineWidth: 1)
                        .frame(width: 160, height: 160)
                        .scaleEffect(logoRotate ? 1.08 : 0.95)
                        .opacity(logoRotate ? 0.6 : 1)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: logoRotate)

                    Circle()
                        .stroke(Color(hex: "A78BFA").opacity(0.08), lineWidth: 1)
                        .frame(width: 130, height: 130)
                        .scaleEffect(logoRotate ? 0.95 : 1.06)
                        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: logoRotate)

                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 106, height: 106)
                        .overlay(
                            Circle().stroke(
                                LinearGradient(
                                    colors: [Color(hex: "C4BBFF").opacity(0.6), Color(hex: "5B4FA8").opacity(0.2)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                        )
                        .shadow(color: Color(hex: "7C6FCD").opacity(0.45), radius: 28, y: 8)

                    Text("P")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "E8E2FF"), Color(hex: "A78BFA"), Color(hex: "7C6FCD")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(hex: "7C6FCD").opacity(0.6), radius: 12)
                }
                .scaleEffect(stage >= 1 ? 1 : 0.4)
                .opacity(stage >= 1 ? 1 : 0)
                .padding(.bottom, 30)
                .onAppear { logoRotate = true }

                // ── Wordmark ──────────────────────────────────────────────
                VStack(spacing: 6) {
                    Text("Pebb")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "D4CFFF")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(hex: "7C6FCD").opacity(0.3), radius: 8, y: 3)

                    Text("your ai · always on")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "6B7280"))
                }
                .opacity(stage >= 2 ? 1 : 0)
                .offset(y: stage >= 2 ? 0 : 14)

                // ── Input card ────────────────────────────────────────────
                VStack(spacing: 14) {
                    HStack {
                        Text("enter your number to get started")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "9CA3AF"))
                        Spacer()
                        if digits.count >= 9 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "22C55E"))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: digits.count >= 9)

                    HStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Text("🇦🇺")
                                .font(.system(size: 20))
                            Text("+61")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "C4BBFF"))
                        }
                        .padding(.horizontal, 16)

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "7C6FCD").opacity(0.5), Color(hex: "4F46E5").opacity(0.2)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 1, height: 30)

                        TextField("4XX XXX XXX", text: $phone)
                            .focused($focused)
                            .keyboardType(.phonePad)
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                            .tint(Color(hex: "A78BFA"))
                            .padding(.horizontal, 14)
                    }
                    .frame(height: 60)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.ultraThinMaterial)
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(hex: "7C6FCD").opacity(focused ? 0.08 : 0.02))
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: focused
                                        ? [Color(hex: "A78BFA").opacity(0.8), Color(hex: "7C6FCD").opacity(0.4)]
                                        : [Color(hex: "7C6FCD").opacity(0.25), Color(hex: "4F46E5").opacity(0.1)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(
                        color: Color(hex: "7C6FCD").opacity(focused ? 0.3 : 0.06),
                        radius: focused ? 14 : 4
                    )
                    .animation(.spring(response: 0.32, dampingFraction: 0.8), value: focused)
                }
                .padding(.horizontal, 28)
                .padding(.top, 44)
                .opacity(stage >= 3 ? 1 : 0)
                .offset(y: stage >= 3 ? 0 : 18)

                // ── CTA ───────────────────────────────────────────────────
                Button {
                    guard canContinue else { return }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.16, dampingFraction: 0.35)) { buttonPressed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.5)) { buttonPressed = false }
                        session.setPhone("+61" + digits)
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                canContinue
                                    ? LinearGradient(
                                        colors: [Color(hex: "B8ACFF"), Color(hex: "7C6FCD"), Color(hex: "5448B0")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color(hex: "1A1A28"), Color(hex: "1A1A28")],
                                        startPoint: .top, endPoint: .bottom
                                    )
                            )
                            .shadow(
                                color: Color(hex: "7C6FCD").opacity(canContinue ? 0.55 : 0),
                                radius: buttonPressed ? 5 : 18,
                                y: buttonPressed ? 2 : 7
                            )

                        // Shimmer
                        if canContinue {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.08), .clear],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                        }

                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(hex: "C4BBFF").opacity(canContinue ? 0.3 : 0), lineWidth: 1)

                        HStack(spacing: 8) {
                            Text("start chatting")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(canContinue ? .white : Color(hex: "4B5563"))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(canContinue ? .white.opacity(0.75) : Color(hex: "4B5563"))
                        }
                    }
                    .frame(height: 58)
                    .scaleEffect(
                        buttonPressed
                            ? CGSize(width: 0.95, height: 0.87)
                            : CGSize(width: canContinue ? 1.0 : 0.97, height: 1)
                    )
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .disabled(!canContinue)
                .opacity(stage >= 4 ? 1 : 0)
                .offset(y: stage >= 4 ? 0 : 18)
                .animation(.spring(response: 0.28, dampingFraction: 0.65), value: canContinue)
                .animation(.spring(response: 0.16, dampingFraction: 0.35), value: buttonPressed)

                Text("pebb texts from +61 489 934 800 · free to start")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "374151"))
                    .padding(.top, 14)
                    .opacity(stage >= 4 ? 1 : 0)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.7).delay(0.05))  { stage = 1 }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.22)) { stage = 2 }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.38)) { stage = 3 }
            withAnimation(.spring(response: 0.5,  dampingFraction: 0.78).delay(0.50)) { stage = 4 }
        }
        .onTapGesture { focused = false }
    }
}
