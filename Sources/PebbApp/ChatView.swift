import SwiftUI
import PhotosUI

struct ChatView: View {
    @StateObject private var api = PebbAPI.shared
    @StateObject private var voice = VoiceRecorder()
    @State private var input = ""
    @State private var showAccount = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            AnimatedChatBackground()
            VStack(spacing: 0) {
                topBar
                messagesList
            }
            .safeAreaInset(edge: .bottom) { inputBar }
        }
        .sheet(isPresented: $showAccount) { AccountView() }
        .task { try? await api.loadHistory() }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            HStack(spacing: 9) {
                PebbLogoMark(size: 30, corner: 9)
                Text("Pebb")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "EDEBF7"))
            }
            Spacer()
            Button { showAccount = true } label: {
                VStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "C4C0E0"))
                            .frame(width: 16, height: 1.5)
                    }
                }
                .padding(10)
                .frame(width: 38, height: 38)
                .background(Color(hex: "1E1C30"))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color(hex: "FFFFFF").opacity(0.1), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 11))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .overlay(Divider().overlay(Color(hex: "FFFFFF").opacity(0.07)), alignment: .bottom)
    }

    // MARK: - Messages List
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if api.messages.isEmpty && !api.isTyping {
                    chatEmptyState
                } else {
                    LazyVStack(spacing: 4) {
                        ForEach(api.messages) { msg in
                            MessageRow(message: msg)
                                .id(msg.id)
                        }
                        if api.isTyping {
                            TypingIndicator()
                                .id("typing")
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    \.padding(\.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .onTapGesture { hideKeyboard() }
            .refreshable { try? await api.loadHistory() }
            .onChange(of: api.messages.count) {
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onChange(of: api.isTyping) {
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        VStack(spacing: 8) {
            if voice.isRecording { recordingBar }
            if let data = selectedImageData, let uiimg = UIImage(data: data) {
                HStack {
                    Spacer()
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiimg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        Button {
                            selectedImageData = nil
                            selectedPhoto = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color(hex: "F87171"))
                                .background(Circle().fill(.white))
                        }
                        .offset(x: 6, y: -6)
                    }
                }
            }

            HStack(alignment: .bottom, spacing: 8) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "6E6A8A"))
                        .frame(width: 40, height: 40)
                        .background(Color(hex: "1E1C30"))
                        .overlay(Circle().stroke(Color(hex: "FFFFFF").opacity(0.1), lineWidth: 1))
                        .clipShape(Circle())
                }
                .onChange(of: selectedPhoto) { _, new in
                    Task {
                        if let data = try? await new?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                        }
                    }
                }

                TextField("Message Pebb…", text: $input)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "EDEBF7"))
                    \.padding(\.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(minHeight: 40)
                    .background(Color(hex: "1E1C30"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                inputFocused
                                    ? Color(hex: "7C6FCD").opacity(0.7)
                                    : Color(hex: "7C6FCD").opacity(0.25),
                                lineWidth: 1.5
                            )
                            .animation(.easeInOut(duration: 0.2), value: inputFocused)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($inputFocused)
                    .onSubmit { send() }
                    .submitLabel(.send)

                if canSend {
                    Button(action: send) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(Color.white)
                            .frame(width: 40, height: 40)
                            .background(LinearGradient(colors: [Color(hex: "A78BFA"), Color(hex: "7C6FCD")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Circle())
                            .shadow(color: Color(hex: "7C6FCD").opacity(0.55), radius: 16)
                            .scaleEffect(1.07)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    micButton
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: canSend)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .overlay(Divider().overlay(Color(hex: "FFFFFF").opacity(0.07)), alignment: .top)
    }

    // Hold-to-record mic button
    private var micButton: some View {
        Image(systemName: voice.isRecording ? "stop.fill" : "mic.fill")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(voice.isRecording ? .white : Color(hex: "9B8FE8"))
            .frame(width: 40, height: 40)
            .background(
                voice.isRecording
                    ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "F87171"), Color(hex: "DC2626")], startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color(hex: "1E1C30"))
            )
            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
            .clipShape(Circle())
            .scaleEffect(voice.isRecording ? 1.12 : 1)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !voice.isRecording { startRecording() } }
                    .onEnded { _ in finishRecording() }
            )
    }

    // Recording status bar with live waveform
    private var recordingBar: some View {
        HStack(spacing: 12) {
            Button { voice.cancel() } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "F87171"))
            }
            Circle().fill(Color(hex: "F87171")).frame(width: 8, height: 8)
                .opacity(voice.level > 0.1 ? 1 : 0.4)
            HStack(spacing: 2) {
                ForEach(Array(voice.levels.enumerated()), id: \.offset) { _, lvl in
                    Capsule()
                        .fill(Color(hex: "9B8FE8"))
                        .frame(width: 2.5, height: max(3, lvl * 26))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 26)
            Text(voice.durationLabel)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "EDEBF7"))
        }
        \.padding(\.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "1E1C30"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func startRecording() {
        voice.requestPermission { granted in
            guard granted else { return }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { voice.start() }
        }
    }

    private func finishRecording() {
        guard voice.isRecording else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let label = "Voice message · \(voice.durationLabel)"
        let url = voice.stop()
        guard url != nil else { return }
        Task { try? await api.sendMessage(label, isVoice: true) }
    }

    private let suggestions = ["Summarise today's news", "Help me write something", "Give me a fun fact"]

    private var chatEmptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)
            PebbLogoMark(size: 68, corner: 20)
                .shadow(color: Color(hex: "7C6FCD").opacity(0.45), radius: 24)
            Text("What's on your mind?")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "EDEBF7"))
            Text("Ask Pebb anything, or try a suggestion")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6E6A8A"))
            VStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { s in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        input = s
                        inputFocused = true
                    } label: {
                        Text(s)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "C4BBFF"))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .liquidGlass(cornerRadius: 14, tint: Color(hex: "7C6FCD"), tintOpacity: 0.06)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImageData != nil
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || selectedImageData != nil else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        input = ""
        let imgData = selectedImageData
        selectedImageData = nil
        selectedPhoto = nil
        Task { try? await api.sendMessage(text, imageData: imgData) }
    }
}

// MARK: - Animated Background
struct AnimatedChatBackground: View {
    @State private var phase1 = false
    @State private var phase2 = false

    var body: some View {
        ZStack {
            Color(hex: "0B0A12")
            Circle()
                .fill(Color(hex: "7C6FCD").opacity(0.07))
                .frame(width: 380, height: 380)
                .blur(radius: 80)
                .offset(x: phase1 ? 80 : -50, y: phase1 ? -100 : -200)
            Circle()
                .fill(Color(hex: "4F46E5").opacity(0.05))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: phase2 ? -70 : 60, y: phase2 ? 160 : 60)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) { phase1 = true }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true).delay(2)) { phase2 = true }
        }
    }
}

// MARK: - Message Row
struct MessageRow: View {
    let message: ChatMessage
    @State private var appear = false
    @State private var showTime = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer(minLength: 60) }
            if !message.isUser {
                PebbLogoMark(size: 24, corner: 12)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                bubbleContent
                    .fixedSize(horizontal: false, vertical: true)
                    \.padding(\.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        message.isUser
                            ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "9B8FE8"), Color(hex: "7C6FCD")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(.ultraThinMaterial)
                    )
                    .environment(\.colorScheme, .dark)
                    .overlay(
                        message.isUser ? nil :
                        bubbleShape.fill(
                            LinearGradient(
                                colors: [.white.opacity(0.12), .clear],
                                startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.5)
                            )
                        )
                    )
                    .overlay(
                        message.isUser ? nil :
                        bubbleShape.stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.22), .white.opacity(0.06)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    )
                    .clipShape(bubbleShape)
                    .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 3)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showTime.toggle()
                        }
                    }
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }

                if showTime {
                    Text(message.timestamp)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: "4B5563"))
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }

                if message.isUser {
                    statusLabel
                        .transition(.opacity)
                }

                if let img = message.imageURL {
                    AsyncImage(url: URL(string: img)) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .frame(maxWidth: 200)
                }
            }
            .opacity(appear ? 1 : 0)
            .scaleEffect(appear ? 1 : 0.88)
            .offset(y: appear ? 0 : 12)
            .onAppear {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.7).delay(0.04)) { appear = true }
            }

            if message.isUser { Spacer().frame(width: 24) }
            else { Spacer(minLength: 60) }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var bubbleContent: some View {
        if message.isVoice {
            VoiceBubble(text: message.content, isUser: message.isUser)
        } else if message.isUser {
            Text(message.content)
                .font(.system(size: 14.5))
                .foregroundStyle(Color.white)
        } else {
            HStack(alignment: .bottom, spacing: 4) {
                MarkdownText(text: message.content)
                if message.isStreaming {
                    StreamingCaret()
                }
            }
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch message.status {
        case .sending:
            Label("Sending", systemImage: "clock")
                .labelStyle(.iconOnly)
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: "6E6A8A"))
        case .sent:
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(hex: "6E6A8A"))
        case .delivered:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: "9B8FE8"))
        case .failed:
            Label("Failed", systemImage: "exclamationmark.circle.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color(hex: "F87171"))
        }
    }

    private var bubbleShape: UnevenRoundedRectangle {
        let r: CGFloat = 20
        let tip: CGFloat = 6
        return UnevenRoundedRectangle(
            topLeadingRadius: r,
            bottomLeadingRadius: message.isUser ? r : tip,
            bottomTrailingRadius: message.isUser ? tip : r,
            topTrailingRadius: r
        )
    }
}

// MARK: - Streaming caret (blinking)
struct StreamingCaret: View {
    @State private var on = true
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color(hex: "9B8FE8"))
            .frame(width: 2, height: 15)
            .opacity(on ? 1 : 0.15)
            .padding(.bottom, 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever()) { on.toggle() }
            }
    }
}

// MARK: - Voice message bubble
struct VoiceBubble: View {
    let text: String
    let isUser: Bool
    @State private var animate = false
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "waveform")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isUser ? .white : Color(hex: "9B8FE8"))
                .symbolEffect(.variableColor.iterative, options: .repeating, isActive: animate)
            Text(text.isEmpty ? "Voice message" : text)
                .font(.system(size: 14))
                .foregroundStyle(isUser ? .white : Color(hex: "EDEBF7"))
        }
        .onAppear { animate = true }
    }
}

// MARK: - Keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var bounce = false
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            PebbLogoMark(size: 24, corner: 12)

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: "7C6FCD"))
                        .frame(width: 7, height: 7)
                        .scaleEffect(bounce ? 1.3 : 0.8)
                        .offset(y: bounce ? -8 : 0)
                        .animation(
                            .spring(response: 0.28, dampingFraction: 0.45)
                                .repeatForever()
                                .delay(Double(i) * 0.14),
                            value: bounce
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "1E1C30"))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            Spacer(minLength: 60)
        }
        .onAppear { bounce = true }
    }
}
