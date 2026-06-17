import SwiftUI

// Liquid Glass card effect — frosted translucent surface with specular rim
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
            )
            .environment(\.colorScheme, .dark)
            .overlay(
                // Specular highlight — bright band at the top edge
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.14), .white.opacity(0.04), .clear],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.45)
                        )
                    )
            )
            .overlay(
                // Glass rim stroke — brighter at top-left, fades to dim
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.28), .white.opacity(0.07), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(shadowOpacity), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, tint: Color = .white, tintOpacity: Double = 0.04) -> some View {
        self.modifier(LiquidGlass(cornerRadius: cornerRadius, tint: tint, tintOpacity: tintOpacity))
    }
}

// Inline glass pill — for tags, badges, category chips
struct GlassPillModifier: ViewModifier {
    var tint: Color
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(tint.opacity(0.12))
                }
            )
            .environment(\.colorScheme, .dark)
            .overlay(
                Capsule().fill(
                    LinearGradient(colors: [.white.opacity(0.18), .clear], startPoint: .top, endPoint: .center)
                )
            )
            .overlay(
                Capsule().stroke(
                    LinearGradient(colors: [tint.opacity(0.5), tint.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
            )
    }
}

extension View {
    func glassPill(tint: Color = .white) -> some View {
        self.modifier(GlassPillModifier(tint: tint))
    }
}
