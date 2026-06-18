import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.15
    @State private var logoRotation: Double = -360
    @State private var wordmarkOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 22
    @State private var progressWidth: CGFloat = 0
    @State private var pulse = false
    @State private var glowRadius: CGFloat = 80

    var body: some View {
        ZStack {
            Color(hex: "0B0A12").ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(Color(hex: "7C6FCD").opacity(0.22))
                .frame(width: 500, height: 500)
                .blur(radius: glowRadius)
                .offset(y: -140)
                .scaleEffect(pulse ? 1.12 : 1.0)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulse)

            VStack(spacing: 30) {
                // Logo orb
                ZStack {
                    Image("PebbLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 114, height: 114)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                        .shadow(color: Color(hex: "7C6FCD").opacity(0.55), radius: 36, y: 12)
                }
                .scaleEffect(logoScale)
                .rotationEffect(.degrees(logoRotation))

                // Wordmark
                VStack(spacing: 9) {
                    Text("Pebb")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.white, Color(hex: "D4CFFF")],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .tracking(-1.5)

                    Text("your ai · always on")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "6E6A8A"))
                        .tracking(2.5)
                        .textCase(.uppercase)
                }
                .opacity(wordmarkOpacity)
                .offset(y: wordmarkOffset)
            }

            // Progress bar
            VStack {
                Spacer()
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 100, height: 2)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            colors: [Color(hex: "7C6FCD"), Color(hex: "C4BBFF")],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: progressWidth, height: 2)
                }
                .padding(.bottom, 52)
                .opacity(wordmarkOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.58)) {
                logoScale = 1.0
                logoRotation = 0
            }
            withAnimation(.easeOut(duration: 0.6)) {
                glowRadius = 100
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.52)) {
                wordmarkOpacity = 1
                wordmarkOffset = 0
            }
            withAnimation(.easeInOut(duration: 2.3).delay(0.65)) {
                progressWidth = 100
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                pulse = true
            }
        }
    }
}
