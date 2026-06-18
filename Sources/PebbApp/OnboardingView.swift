import SwiftUI
import UIKit

struct OnboardingView: View {
    @StateObject private var api = PebbAPI.shared
    @State private var step = 0
    @State private var direction: Int = 1

    // Step 1
    @State private var phone = ""
    @State private var phoneError = ""
    @State private var sendingCode = false

    // Step 2
    @State private var code = ""
    @State private var verifying = false
    @State private var codeError = ""
    @FocusState private var codeFocused: Bool

    // Step 3
    @State private var name = ""

    // Step 4 — use cases (multi)
    @State private var useCases: Set<String> = []

    // Step 5 — level (single)
    @State private var level = ""

    // Step 6 — topics (chips)
    @State private var topics: Set<String> = []

    let totalSteps = 8

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                progressDots.padding(.top, 64).padding(.bottom, 20)
                ZStack {
                    if step == 0 { stepWelcome.stepTransition(step, 0, direction) }
                    if step == 1 { stepPhone.stepTransition(step, 1, direction) }
                    if step == 2 { stepCode.stepTransition(step, 2, direction) }
                    if step == 3 { stepName.stepTransition(step, 3, direction) }
                    if step == 4 { stepUseCases.stepTransition(step, 4, direction) }
                    if step == 5 { stepLevel.stepTransition(step, 5, direction) }
                    if step == 6 { stepTopics.stepTransition(step, 6, direction) }
                    if step == 7 { stepDone.stepTransition(step, 7, direction) }
                }
                Spacer()
            }
        }
    }

    // MARK: - Background
    private var background: some View {
        ZStack {
            Color(hex: "0B0A12")
            Circle()
                .fill(Color(hex: "7C6FCD").opacity(0.18))
                .frame(width: 600, height: 600)
                .blur(radius: 120)
                .offset(y: -320)
        }
        .ignoresSafeArea()
    }

    // MARK: - Progress
    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i == step ? Color(hex: "7C6FCD") : (i < step ? Color(hex: "C4BBFF").opacity(0.4) : Color.white.opacity(0.12)))
                    .frame(width: i == step ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: step)
            }
        }
    }

    // MARK: - Navigation
    private func next() {
        direction = 1
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) { step += 1 }
    }
    private func back() {
        direction = -1
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) { step -= 1 }
    }

    // MARK: - Step 0: Welcome
    private var stepWelcome: some View {
        WizardCard {
            PebbLogoMark(size: 72, corner: 22)
                .shadow(color: Color(hex: "7C6FCD").opacity(0.4), radius: 20)
                .padding(.bottom, 4)

            Text("Hey, let's set up Pebb")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "EDEBF7"))
                .tracking(-0.5)

            Text("Your AI — always in your pocket. This takes about a minute.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 8)

            WizardButton("Let's go →") { next() }
        }
    }

    // MARK: - Step 1: Phone
    private var stepPhone: some View {
        WizardCard {
            backButton
            Text("📱").font(.system(size: 40)).padding(.bottom, 4)
            Text("What's your number?")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "EDEBF7"))
            Text("We'll use this to reach you.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .padding(.bottom, 8)

            WizardField(label: "Phone number") {
                TextField("+61 400 000 000", text: $phone)
                    .keyboardType(.phonePad)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "EDEBF7"))
            }

            if !phoneError.isEmpty {
                Text(phoneError)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "F87171"))
            }

            WizardButton(sendingCode ? "Sending…" : "Send code", loading: sendingCode) {
                sendCode()
            }
        }
    }

    // MARK: - Step 2: Code
    private var stepCode: some View {
        WizardCard {
            backButton
            Text("🔐").font(.system(size: 40)).padding(.bottom, 4)
            Text("Enter your code")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "EDEBF7"))
            Text("Texted to \(phone.isEmpty ? "your number" : phone)")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .padding(.bottom, 4)

            WizardField(label: "6-digit code") {
                TextField("123456", text: $code)
                    .keyboardType(.numberPad)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "EDEBF7"))
                    .multilineTextAlignment(.center)
                    .focused($codeFocused)
                    .onChange(of: code) { _, v in
                        code = String(v.filter(\.isNumber).prefix(6))
                    }
            }

            if !codeError.isEmpty {
                Text(codeError)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "F87171"))
            }

            WizardButton(verifying ? "Verifying…" : "Verify →", loading: verifying) {
                verifyCode()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { codeFocused = true }
        }
    }

    // MARK: - Step 3: Name
    private var stepName: some View {
        WizardCard {
            Text("👋").font(.system(size: 40)).padding(.bottom, 4)
            Text("What should we call you?")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "EDEBF7"))
            Text("Pebb will personalise your experience.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .padding(.bottom, 8)

            WizardField(label: "Your name") {
                TextField("Alex", text: $name)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "EDEBF7"))
                    .autocorrectionDisabled()
            }

            WizardButton("Next →") { next() }
            WizardGhostButton("Skip") { next() }
        }
    }

    // MARK: - Step 4: Use Cases
    private var stepUseCases: some View {
        WizardCard {
            Text("🎯").font(.system(size: 40)).padding(.bottom, 4)
            Text("What do you want Pebb for?")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "EDEBF7"))
            Text("Pick everything that applies.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .padding(.bottom, 8)

            VStack(spacing: 10) {
                WizardChoice(icon: "💬", title: "Quick answers", desc: "Ask anything, get an instant reply", selected: useCases.contains("answers")) {
                    toggle(&useCases, "answers")
                }
                WizardChoice(icon: "✅", title: "Tasks & reminders", desc: "Stay on top of what matters", selected: useCases.contains("tasks")) {
                    toggle(&useCases, "tasks")
                }
                WizardChoice(icon: "📰", title: "Daily briefings", desc: "News and updates every morning", selected: useCases.contains("news")) {
                    toggle(&useCases, "news")
                }
                WizardChoice(icon: "🧠", title: "Everything", desc: "I want it all", selected: useCases.contains("all")) {
                    toggle(&useCases, "all")
                }
            }
            .padding(.bottom, 4)

            WizardButton("Next →") { next() }
        }
    }

    // MARK: - Step 5: Level
    private var stepLevel: some View {
        WizardCard {
            Text("⚡").font(.system(size: 40)).padding(.bottom, 4)
            Text("How active are you with AI?")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "EDEBF7"))
                .multilineTextAlignment(.center)
            Text("Helps us set your defaults.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .padding(.bottom, 8)

            VStack(spacing: 10) {
                WizardChoice(icon: "🌱", title: "Just starting out", desc: "New to AI assistants", selected: level == "beginner") {
                    level = "beginner"; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { next() }
                }
                WizardChoice(icon: "🔥", title: "Regular user", desc: "I use AI a few times a week", selected: level == "regular") {
                    level = "regular"; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { next() }
                }
                WizardChoice(icon: "🚀", title: "Power user", desc: "AI is part of my daily workflow", selected: level == "power") {
                    level = "power"; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { next() }
                }
            }
        }
    }

    // MARK: - Step 6: Topics
    private var stepTopics: some View {
        WizardCard {
            Text("🗂").font(.system(size: 40)).padding(.bottom, 4)
            Text("Topics you care about")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "EDEBF7"))
            Text("Tailor your daily news and suggestions.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .padding(.bottom, 8)

            let allTopics = ["Tech","World news","Business","Sports","Science","Health","Entertainment","Politics","Finance","AI & future"]
            FlowLayout(spacing: 8) {
                ForEach(allTopics, id: \.self) { t in
                    Button {
                        if topics.contains(t) { topics.remove(t) } else { topics.insert(t) }
                    } label: {
                        Text(t)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(topics.contains(t) ? Color(hex: "C4BBFF") : Color(hex: "A09CBA"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(topics.contains(t) ? Color(hex: "7C6FCD").opacity(0.18) : Color.white.opacity(0.05))
                            .overlay(
                                Capsule().stroke(topics.contains(t) ? Color(hex: "7C6FCD").opacity(0.7) : Color.white.opacity(0.1), lineWidth: 1.5)
                            )
                            .clipShape(Capsule())
                            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: topics.contains(t))
                    }
                }
            }
            .padding(.bottom, 4)

            WizardButton("Almost there →") { next() }
            WizardGhostButton("Skip") { next() }
        }
    }

    // MARK: - Step 7: Done
    private var stepDone: some View {
        WizardCard {
            Text("🎉").font(.system(size: 50)).padding(.bottom, 4)
            Text("You're all set!")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "EDEBF7"))
            Text("Here's a summary of your setup.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                summaryRow("Phone", phone.isEmpty ? "—" : phone)
                summaryRow("Name", name.isEmpty ? "—" : name)
                summaryRow("Goals", useCases.isEmpty ? "Not set" : useCases.joined(separator: ", "))
                summaryRow("Level", level.isEmpty ? "Not set" : level, last: true)
            }
            .liquidGlass(cornerRadius: 16)
            .padding(.bottom, 8)

            WizardButton("Open Pebb →") {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                api.completeMockLogin(name: name)
            }
        }
    }

    private func summaryRow(_ label: String, _ value: String, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "6E6A8A"))
                    .textCase(.uppercase)
                    .frame(width: 60, alignment: .leading)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "EDEBF7"))
                    .lineLimit(1)
                Spacer()
                Text("✓")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "34D399"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            if !last {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.horizontal, 14)
            }
        }
    }

    // MARK: - Back button
    private var backButton: some View {
        Button { UIImpactFeedbackGenerator(style: .light).impactOccurred(); back() } label: {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                Text("Back")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(Color(hex: "6E6A8A"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    // MARK: - Auth
    private func sendCode() {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { phoneError = "Enter your phone number"; return }
        phoneError = ""
        sendingCode = true
        Task {
            do {
                _ = try await api.requestCode(phone: trimmed)
                sendingCode = false
                next()
            } catch {
                sendingCode = false
                phoneError = "Couldn't send code — check your number and try again"
            }
        }
    }

    private func verifyCode() {
        guard code.count == 6 else { codeError = "Enter the 6-digit code"; return }
        codeError = ""
        verifying = true
        Task {
            do {
                _ = try await api.verifyCode(phone: phone.trimmingCharacters(in: .whitespacesAndNewlines), code: code)
                verifying = false
                next()
            } catch {
                verifying = false
                codeError = (error as NSError).localizedDescription
            }
        }
    }

    private func toggle(_ set: inout Set<String>, _ val: String) {
        if set.contains(val) { set.remove(val) } else { set.insert(val) }
    }
}

// MARK: - Reusable Wizard Components

struct WizardCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            content
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, 32)
        .liquidGlass(cornerRadius: 28, tint: Color(hex: "7C6FCD"), tintOpacity: 0.04)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}

struct WizardField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .textCase(.uppercase)
                .tracking(1)
            content
                .padding(13)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.1), lineWidth: 1.5))
                .clipShape(RoundedRectangle(cornerRadius: 13))
        }
        .frame(maxWidth: .infinity)
    }
}

struct WizardButton: View {
    let label: String
    var loading: Bool = false
    let action: () -> Void
    init(_ label: String, loading: Bool = false, action: @escaping () -> Void) {
        self.label = label; self.loading = loading; self.action = action
    }
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                if loading { ProgressView().tint(.white).scaleEffect(0.8) }
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .fixedSize()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(LinearGradient(colors: [Color(hex: "9B8FE8"), Color(hex: "7C6FCD")], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(Capsule())
            .foregroundStyle(Color.white)
            .shadow(color: Color(hex: "7C6FCD").opacity(0.4), radius: 12, y: 4)
        }
        .disabled(loading)
    }
}

struct WizardGhostButton: View {
    let label: String
    let action: () -> Void
    init(_ label: String, action: @escaping () -> Void) {
        self.label = label; self.action = action
    }
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
    }
}

struct WizardChoice: View {
    let icon: String
    let title: String
    let desc: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 12) {
                Text(icon).font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "EDEBF7"))
                    Text(desc).font(.system(size: 12)).foregroundStyle(Color(hex: "6E6A8A"))
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(selected ? Color(hex: "7C6FCD") : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if selected {
                        Circle().fill(Color(hex: "7C6FCD")).frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(selected ? Color(hex: "7C6FCD").opacity(0.1) : Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? Color(hex: "7C6FCD").opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
        }
    }
}

// MARK: - Flow Layout (wrapping chips)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 0
        var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > w && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            rowH = max(rowH, s.height); x += s.width + spacing
        }
        return CGSize(width: w, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX && x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            rowH = max(rowH, s.height); x += s.width + spacing
        }
    }
}

// MARK: - Step transition modifier
extension View {
    func stepTransition(_ current: Int, _ target: Int, _ direction: Int) -> some View {
        self
            .transition(.asymmetric(
                insertion: .move(edge: direction > 0 ? .trailing : .leading).combined(with: .opacity),
                removal:   .move(edge: direction > 0 ? .leading  : .trailing).combined(with: .opacity)
            ))
            .id(target)
    }
}
