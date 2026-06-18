import SwiftUI

struct LiquidGlass: ViewModifier {
    var cornerRadius: CGFloat = 20
    var tint: Color = .white
    var tintOpacity: Double = 0.04
    var shadowOpacity: Double = 0.25

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    tint.opacity(tintOpacity)
                }
                .allowsHitTesting(false)
            )
            .environment(\.colorScheme, .dark)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.13), .white.opacity(0.03), .clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.45)
                    ))
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(LinearGradient(
                        colors: [.white.opacity(0.26), .white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(shadowOpacity), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, tint: Color = .white, tintOpacity: Double = 0.04) -> some View {
        modifier(LiquidGlass(cornerRadius: cornerRadius, tint: tint, tintOpacity: tintOpacity))
    }
}

struct GlassPillModifier: ViewModifier {
    var tint: Color
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(tint.opacity(0.12))
                }
                .allowsHitTesting(false)
            )
            .environment(\.colorScheme, .dark)
            .overlay(
                Capsule().fill(LinearGradient(colors: [.white.opacity(0.16), .clear], startPoint: .top, endPoint: .center))
                    .allowsHitTesting(false)
            )
            .overlay(
                Capsule().stroke(LinearGradient(colors: [tint.opacity(0.45), tint.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    .allowsHitTesting(false)
            )
    }
}

extension View {
    func glassPill(tint: Color = .white) -> some View {
        modifier(GlassPillModifier(tint: tint))
    }
}

// MARK: - Real Pebb logo mark (replaces all drawn/symbol logos)
struct PebbLogoMark: View {
    var size: CGFloat = 30
    var corner: CGFloat = 9
    var body: some View {
        Image("PebbLogo")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
    }
}
