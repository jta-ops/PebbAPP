import SwiftUI

// MARK: - Chat view

struct ChatView: View {
    @StateObject private var session = PebbSession.shared
    @State private var input = ""
    @FocusState private var inputFocused: Bool
    @State private var showScrollToBottom = false
    @State private var showSettings = false
    @State private var particleBurst: CGPoint? = nil

    var body: some View {
        ZStack {
            AnimatedBackground()

            VStack(spacing: 0) {
                GlassNavBar(showSettings: $showSettings)
                    .zIndex(2)

                ZStack(alignment: .bottomTrailing) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                Spacer().frame(height: 8)

                                if session.messages.isEmpty {
                                    WelcomeCard { suggestion in
                                        input = suggestion
                                        inputFocused = true
                                    }
                                    .padding(.top, 16)
                                    .transition(.scale(scale: 0.88).combined(with: .opacity))
                                }

                                ForEach(Array(session.messages.enumerated()), id: \.element.id) { idx, msg in
                                    MessageBubble(
                                        message: msg,
                                        prevRole: idx > 0 ? session.messages[idx-1].role : nil,
                                        nextRole: idx < session.messages.count - 1 ? session.messages[idx+1].role : nil
                                    )
                                    .id(msg.id)
                                    .transition(
                                        msg.role == .user
                                        ? .asymmetric(
                                            insertion: .push(from: .trailing).combined(with: .opacity),
                                            removal: .opacity
                                        )
                                        : .asymmetric(
                                            insertion: .push(from: .leading).combined(with: .opacity),
                                            removal: .opacity
                                        )
                                    )
                                }

                                if session.isTyping {
                                    TypingIndicator()
                                        .id("typing")
                                        .padding(.top, 4)
                                        .transition(.push(from: .leading).combined(with: .opacity))
                                }

                                Color.clear.frame(height: 16).id("bottom")
                            }
                            .padding(.horizontal, 12)
                            .animation(.spring(response: 0.42, dampingFraction: 0.82), value: session.messages.count)
                            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: session.isTyping)
                        }
                        .onChange(of: session.messages.count) {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                proxy.scrollTo("bottom")
                                showScrollToBottom = false
                            }
                        }
                        .onChange(of: session.isTyping) {
                            withAnimation { proxy.scrollTo("bottom") }
                        }
                        .onTapGesture { inputFocused = false }
                    }

                    // Scroll to bottom FAB
                    if showScrollToBottom {
                        ScrollToBottomFAB()
                            .padding(.trailing, 16)
                            .padding(.bottom, 12)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                GlassComposer(input: $input, focused: _inputFocused) {
                    guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let text = input
                    input = ""
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    Task { await session.send(text) }
                }
            }

            // Particle burst overlay
            if let pt = particleBurst {
                ParticleBurst(origin: pt)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }
}

// MARK: - Scroll to bottom button

struct ScrollToBottomFAB: View {
    @State private var pressed = false
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
            }
        } label: {
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "C4BBFF"))
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(hex: "7C6FCD").opacity(0.4), lineWidth: 1))
                .shadow(color: Color(hex: "7C6FCD").opacity(0.3), radius: 8)
                .scaleEffect(pressed ? 0.88 : 1)
        }
    }
}

// MARK: - Particle burst

struct Particle: Identifiable {
    let id = UUID()
    var offset: CGSize
    var opacity: Double
    var scale: CGFloat
    var color: Color
    var rotation: Double
}

struct ParticleBurst: View {
    let origin: CGPoint
    @State private var particles: [Particle] = []
    @State private var done = false

    let colors: [Color] = [
        Color(hex: "7C6FCD"), Color(hex: "A78BFA"), Color(hex: "C4BBFF"),
        Color(hex: "818CF8"), Color(hex: "E0DAFF")
    ]

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: 5, height: 5)
                    .scaleEffect(p.scale)
                    .opacity(p.opacity)
                    .offset(p.offset)
                    .rotationEffect(.degrees(p.rotation))
            }
        }
        .position(origin)
        .onAppear { burst() }
    }

    func burst() {
        particles = (0..<20).map { _ in
            Particle(
                offset: .zero,
                opacity: 1,
                scale: CGFloat.random(in: 0.6...1.4),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360)
            )
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            for i in particles.indices {
                let angle = Double.random(in: 0...(2 * .pi))
                let dist = CGFloat.random(in: 30...90)
                particles[i].offset = CGSize(
                    width: cos(angle) * dist,
                    height: sin(angle) * dist
                )
                particles[i].rotation += Double.random(in: -180...180)
            }
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            for i in particles.indices { particles[i].opacity = 0 }
        }
    }
}

// MARK: - Animated morphing background

struct AnimatedBackground: View {
    @State private var t: CGFloat = 0
    let timer = Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(hex: "060610").ignoresSafeArea()

            // Stars
            StarField()

            // Blob 1 — primary purple
            AnimBlob(
                color: Color(hex: "7C6FCD"),
                opacity: 0.55,
                size: 420,
                offset: CGSize(width: -90, height: -300),
                blur: 55,
                speed: 9,
                t: t
            )

            // Blob 2 — blue
            AnimBlob(
                color: Color(hex: "4338CA"),
                opacity: 0.3,
                size: 340,
                offset: CGSize(width: 130, height: 80),
                blur: 60,
                speed: 13,
                t: t
            )

            // Blob 3 — soft lavender
            AnimBlob(
                color: Color(hex: "A78BFA"),
                opacity: 0.2,
                size: 300,
                offset: CGSize(width: -50, height: 350),
                blur: 50,
                speed: 17,
                t: t
            )

            // Blob 4 — accent
            AnimBlob(
                color: Color(hex: "6366F1"),
                opacity: 0.18,
                size: 260,
                offset: CGSize(width: 160, height: -100),
                blur: 45,
                speed: 7,
                t: t
            )
        }
        .onReceive(timer) { _ in t += 0.008 }
    }
}

struct AnimBlob: View {
    let color: Color
    let opacity: Double
    let size: CGFloat
    let offset: CGSize
    let blur: CGFloat
    let speed: CGFloat
    let t: CGFloat

    var body: some View {
        let dx = sin(t * speed * 0.07) * 30
        let dy = cos(t * speed * 0.05) * 25
        return BlobShape(seed: speed, t: t)
            .fill(
                RadialGradient(
                    colors: [color.opacity(opacity), color.opacity(0)],
                    center: .center, startRadius: 0, endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .offset(x: offset.width + dx, y: offset.height + dy)
            .blur(radius: blur)
    }
}

struct BlobShape: Shape {
    let seed: CGFloat
    let t: CGFloat
    var animatableData: CGFloat { t }

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        let steps = 80
        var points: [CGPoint] = []
        for i in 0...steps {
            let angle = CGFloat(i) / CGFloat(steps) * .pi * 2
            let n1 = sin(angle * 2 + t * 0.9 + seed) * 0.13
            let n2 = cos(angle * 3 - t * 0.7 + seed * 0.5) * 0.09
            let n3 = sin(angle * 5 + t * 1.1 - seed * 0.3) * 0.05
            let n4 = cos(angle * 7 - t * 0.4) * 0.03
            let rad = r * (1 + n1 + n2 + n3 + n4)
            points.append(CGPoint(x: cx + cos(angle) * rad, y: cy + sin(angle) * rad))
        }
        var path = Path()
        guard points.count > 1 else { return path }
        path.move(to: points[0])
        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let cp = CGPoint(x: (prev.x + curr.x) / 2, y: (prev.y + curr.y) / 2)
            path.addQuadCurve(to: cp, control: prev)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Star field

struct StarField: View {
    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
        let speed: Double
    }

    @State private var stars: [Star] = (0..<80).map { _ in
        Star(
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 0.8...2.2),
            opacity: Double.random(in: 0.1...0.5),
            speed: Double.random(in: 1.5...4)
        )
    }
    @State private var twinkle = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(stars) { s in
                    Circle()
                        .fill(.white)
                        .frame(width: s.size, height: s.size)
                        .position(x: s.x * geo.size.width, y: s.y * geo.size.height)
                        .opacity(twinkle ? s.opacity : s.opacity * 0.3)
                        .animation(
                            .easeInOut(duration: s.speed).repeatForever(autoreverses: true),
                            value: twinkle
                        )
                }
            }
        }
        .onAppear { twinkle = true }
    }
}

// MARK: - Nav bar

struct GlassNavBar: View {
    @Binding var showSettings: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color(hex: "7C6FCD").opacity(0.05))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "7C6FCD").opacity(0.5), Color(hex: "4F46E5").opacity(0.2)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(height: 0.5)
                }

            HStack(spacing: 12) {
                // Pulsing avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: "7C6FCD").opacity(0.15))
                        .frame(width: pulse ? 54 : 48, height: pulse ? 54 : 48)
                        .blur(radius: 4)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulse)

                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().stroke(
                                LinearGradient(
                                    colors: [Color(hex: "C4BBFF").opacity(0.6), Color(hex: "7C6FCD").opacity(0.25)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                        )
                        .shadow(color: Color(hex: "7C6FCD").opacity(0.4), radius: 10)

                    Text("P")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "E0DAFF"), Color(hex: "A78BFA")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                }
                .onAppear { pulse = true }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Pebb")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.white)
                    HStack(spacing: 5) {
                        OnlineDot()
                        Text("always on · ai")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }
                }

                Spacer()

                GlassIconButton(icon: "gearshape") { showSettings = true }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(height: 66)
    }
}

struct OnlineDot: View {
    @State private var ring = false
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "22C55E").opacity(0.4), lineWidth: 1.5)
                .frame(width: ring ? 14 : 8, height: ring ? 14 : 8)
                .opacity(ring ? 0 : 1)
                .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: ring)
            Circle()
                .fill(Color(hex: "22C55E"))
                .frame(width: 7, height: 7)
                .shadow(color: Color(hex: "22C55E").opacity(0.8), radius: 4)
        }
        .onAppear { ring = true }
    }
}

struct GlassIconButton: View {
    let icon: String
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { pressed = false }
            }
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "C4BBFF"))
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(hex: "7C6FCD").opacity(0.3), lineWidth: 1))
                .shadow(color: Color(hex: "7C6FCD").opacity(0.2), radius: 6)
                .scaleEffect(
                    pressed
                        ? CGSize(width: 0.84, height: 1.16)
                        : CGSize(width: 1, height: 1)
                )
        }
    }
}

// MARK: - Welcome card

struct WelcomeCard: View {
    let onSuggestion: (String) -> Void
    @State private var appear = false

    let suggestions = ["set a goal 🎯", "search the web 🔍", "make me an app 🛠", "what can you do?"]

    var body: some View {
        VStack(spacing: 16) {
            // Avatar with glow
            ZStack {
                Circle()
                    .fill(Color(hex: "7C6FCD").opacity(0.12))
                    .frame(width: 100, height: 100)
                    .blur(radius: 16)
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 84, height: 84)
                    .overlay(
                        Circle().stroke(
                            LinearGradient(
                                colors: [Color(hex: "C4BBFF").opacity(0.5), Color(hex: "7C6FCD").opacity(0.2)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                    )
                    .shadow(color: Color(hex: "7C6FCD").opacity(0.35), radius: 20, y: 6)
                Text("P")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "E0DAFF"), Color(hex: "A78BFA")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
            .scaleEffect(appear ? 1 : 0.55)
            .opacity(appear ? 1 : 0)

            VStack(spacing: 6) {
                Text("hey, i'm pebb")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.white)
                Text("your ai — track goals, search the web, build apps\nor just talk. i'm always on.")
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "9CA3AF"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 10)

            // Suggestion chips
            FlowLayout(spacing: 8) {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { i, s in
                    SuggestionChip(label: s, delay: Double(i) * 0.07) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSuggestion(s.components(separatedBy: " ").dropLast().joined(separator: " "))
                    }
                }
            }
            .padding(.horizontal, 20)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 8)
        }
        .padding(.vertical, 28)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.08)) { appear = true }
        }
    }
}

struct SuggestionChip: View {
    let label: String
    let delay: Double
    let action: () -> Void
    @State private var appear = false
    @State private var pressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
            }
            action()
        } label: {
            Text(label)
                .fixedSize(horizontal: true, vertical: false)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "C4BBFF"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .overlay(
                    Capsule().stroke(Color(hex: "7C6FCD").opacity(0.4), lineWidth: 1)
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "7C6FCD").opacity(0.2), radius: 6)
                .scaleEffect(pressed ? 0.93 : (appear ? 1 : 0.7))
                .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.3 + delay)) {
                appear = true
            }
        }
    }
}

// MARK: - Simple flow layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.size.height }.max() ?? 0 }.reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowWidth = row.map { $0.size.width }.reduce(0, +) + spacing * CGFloat(max(row.count - 1, 0))
            var x = bounds.minX + (bounds.width - rowWidth) / 2
            let rowH = row.map { $0.size.height }.max() ?? 0
            for item in row {
                item.view.place(at: CGPoint(x: x, y: y + (rowH - item.size.height) / 2), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += rowH + spacing
        }
    }

    private struct Item { let view: LayoutSubview; let size: CGSize }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Item]] {
        let maxW = proposal.width ?? 320
        var rows: [[Item]] = [[]]
        var rowW: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(ProposedViewSize(width: maxW, height: nil))
            if rowW + s.width + (rows.last!.isEmpty ? 0 : spacing) > maxW && !rows.last!.isEmpty {
                rows.append([])
                rowW = 0
            }
            rows[rows.count - 1].append(Item(view: v, size: s))
            rowW += s.width + spacing
        }
        return rows
    }
}

// MARK: - Message bubble

struct MessageBubble: View {
    let message: Message
    let prevRole: Message.Role?
    let nextRole: Message.Role?
    @State private var appear = false
    @State private var pressed = false
    @State private var showTime = false

    var isUser: Bool { message.role == .user }
    var isFirst: Bool { prevRole != message.role }
    var isLast: Bool { nextRole != message.role }

    let topR: CGFloat = 20
    let bottomR: CGFloat = 20
    let tipR: CGFloat = 6

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                Group {
                    if isLast {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().stroke(Color(hex: "7C6FCD").opacity(0.45), lineWidth: 1)
                                )
                                .shadow(color: Color(hex: "7C6FCD").opacity(0.3), radius: 6)
                            Text("P")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "E0DAFF"), Color(hex: "A78BFA")],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                        }
                    } else {
                        Color.clear.frame(width: 30)
                    }
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
                // Bubble
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pressed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) { pressed = false }
                    }
                    withAnimation { showTime.toggle() }
                } label: {
                    Text(message.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(isUser ? Color(hex: "F0EDFF") : Color(hex: "E5E5F0"))
                        .font(.system(size: 15.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if isUser {
                                    LinearGradient(
                                        colors: [Color(hex: "9D8FF5"), Color(hex: "7C6FCD"), Color(hex: "5E52C0")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                    .opacity(0.95)
                                } else {
                                    ZStack {
                                        Rectangle().fill(.ultraThinMaterial)
                                        Color(hex: "7C6FCD").opacity(0.07)
                                    }
                                }
                            }
                        )
                        .clipShape(
                            UnevenRoundedRect(
                                tl: isUser && !isFirst ? topR : topR,
                                tr: !isUser && !isFirst ? topR : topR,
                                bl: isUser && !isLast ? bottomR : (isUser ? tipR : bottomR),
                                br: !isUser && !isLast ? bottomR : (!isUser ? tipR : bottomR)
                            )
                        )
                        .overlay(
                            UnevenRoundedRect(
                                tl: isUser && !isFirst ? topR : topR,
                                tr: !isUser && !isFirst ? topR : topR,
                                bl: isUser && !isLast ? bottomR : (isUser ? tipR : bottomR),
                                br: !isUser && !isLast ? bottomR : (!isUser ? tipR : bottomR)
                            )
                            .stroke(
                                isUser
                                    ? Color(hex: "A78BFA").opacity(0.35)
                                    : Color(hex: "7C6FCD").opacity(0.18),
                                lineWidth: 0.8
                            )
                        )
                        .shadow(
                            color: isUser
                                ? Color(hex: "7C6FCD").opacity(0.4)
                                : Color.black.opacity(0.25),
                            radius: isUser ? 12 : 4,
                            x: 0, y: isUser ? 4 : 2
                        )
                }
                .buttonStyle(.plain)
                .scaleEffect(
                    pressed
                        ? CGSize(width: 0.96, height: 0.96)
                        : CGSize(width: 1, height: 1)
                )

                if showTime {
                    Text(timeString(message.timestamp))
                        .fixedSize(horizontal: true, vertical: false)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: "4B5563"))
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .scaleEffect(appear ? 1 : 0.82)
            .opacity(appear ? 1 : 0)

            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.vertical, isFirst ? 4 : 1)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) { appear = true }
        }
    }

    func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

struct UnevenRoundedRect: Shape {
    var tl, tr, bl, br: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        p.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        p.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - Typing indicator

struct TypingIndicator: View {
    @State private var bounce = false
    @State private var appear = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(.ultraThinMaterial).frame(width: 30, height: 30)
                    .overlay(Circle().stroke(Color(hex: "7C6FCD").opacity(0.4), lineWidth: 1))
                Text("P").font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "C4BBFF"))
            }
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "C4BBFF"), Color(hex: "7C6FCD")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 7, height: 7)
                        .offset(y: bounce ? -5 : 0)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.45)
                                .repeatForever()
                                .delay(Double(i) * 0.14),
                            value: bounce
                        )
                        .shadow(color: Color(hex: "7C6FCD").opacity(0.5), radius: 3)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "7C6FCD").opacity(0.2), lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
            .scaleEffect(appear ? 1 : 0.8)
            .opacity(appear ? 1 : 0)
            Spacer(minLength: 60)
        }
        .onAppear {
            bounce = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { appear = true }
        }
    }
}

// MARK: - Glass Composer

struct GlassComposer: View {
    @Binding var input: String
    @FocusState var focused: Bool
    let onSend: () -> Void
    @State private var pressed = false

    var canSend: Bool { !input.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color(hex: "7C6FCD").opacity(0.04))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "7C6FCD").opacity(0.4), Color(hex: "4F46E5").opacity(0.15)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)

            HStack(alignment: .bottom, spacing: 10) {
                ZStack(alignment: .leading) {
                    if input.isEmpty {
                        Text("message pebb…")
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(Color(hex: "4B5563"))
                            .font(.system(size: 16))
                            .padding(.leading, 16)
                            .padding(.bottom, 12)
                    }
                    TextEditor(text: $input)
                        .focused($focused)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.white)
                        .tint(Color(hex: "A78BFA"))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(minHeight: 44, maxHeight: 130)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(hex: "7C6FCD").opacity(focused ? 0.1 : 0.03))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: focused
                                            ? [Color(hex: "A78BFA").opacity(0.7), Color(hex: "7C6FCD").opacity(0.4)]
                                            : [Color(hex: "7C6FCD").opacity(0.2), Color(hex: "4F46E5").opacity(0.1)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color(hex: "7C6FCD").opacity(focused ? 0.3 : 0.05), radius: focused ? 12 : 4)
                )
                .animation(.spring(response: 0.32, dampingFraction: 0.8), value: focused)

                // Send button
                Button {
                    guard canSend else { return }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.16, dampingFraction: 0.35)) { pressed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.5)) { pressed = false }
                    }
                    onSend()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                canSend
                                    ? LinearGradient(
                                        colors: [Color(hex: "B8ACFF"), Color(hex: "7C6FCD"), Color(hex: "5448B0")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color(hex: "1E1E2E"), Color(hex: "1E1E2E")],
                                        startPoint: .top, endPoint: .bottom
                                    )
                            )
                            .shadow(
                                color: Color(hex: "7C6FCD").opacity(canSend ? 0.55 : 0),
                                radius: pressed ? 3 : 14,
                                y: pressed ? 1 : 5
                            )

                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(Color.white)
                            .offset(y: pressed ? 2 : 0)
                    }
                    .frame(width: 44, height: 44)
                    .scaleEffect(
                        pressed
                            ? CGSize(width: 0.8, height: 1.22)
                            : CGSize(width: 1, height: 1)
                    )
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.45), value: canSend)
                .animation(.spring(response: 0.16, dampingFraction: 0.35), value: pressed)
                .disabled(!canSend)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
    }
}

// MARK: - Settings sheet

struct SettingsSheet: View {
    @StateObject private var session = PebbSession.shared
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            Color(hex: "07070D").ignoresSafeArea()
            AnimatedBackground().opacity(0.5)

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "4B5563"))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                Text("Settings")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                VStack(spacing: 12) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Phone Number")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: "9CA3AF"))
                            Text(session.phone)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GlassCard {
                        Button {
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            withAnimation { confirmReset = true }
                        } label: {
                            HStack {
                                Text("Clear Chat History")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color(hex: "F87171"))
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundStyle(Color(hex: "F87171"))
                            }
                        }
                    }

                    if confirmReset {
                        GlassCard {
                            VStack(spacing: 12) {
                                Text("Clear all messages?")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: "D1D5DB"))
                                HStack(spacing: 10) {
                                    Button("Cancel") {
                                        withAnimation { confirmReset = false }
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(hex: "9CA3AF"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: "1E1E2E"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                    Button("Clear") {
                                        withAnimation { session.messages = [] }
                                        confirmReset = false
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: "DC2626"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                    }

                    GlassCard {
                        Button {
                            withAnimation { session.setPhone("") }
                            dismiss()
                        } label: {
                            HStack {
                                Text("Sign Out")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color(hex: "9CA3AF"))
                                Spacer()
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundStyle(Color(hex: "9CA3AF"))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: confirmReset)

                Spacer()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "7C6FCD").opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Hex color

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        self.init(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255
        )
    }
}
