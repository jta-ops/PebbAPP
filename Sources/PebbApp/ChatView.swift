import SwiftUI
import PhotosUI

struct ChatView: View {
    @StateObject private var api = PebbAPI.shared
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
                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "7C6FCD"))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: "1E1C30"))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
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
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
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
                    .padding(.horizontal, 14)
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

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Color.white)
                        .frame(width: 40, height: 40)
                        .background(
                            canSend
                                ? LinearGradient(colors: [Color(hex: "A78BFA"), Color(hex: "7C6FCD")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color(hex: "252340"), Color(hex: "252340")], startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "7C6FCD").opacity(canSend ? 0.55 : 0), radius: canSend ? 16 : 0)
                        .scaleEffect(canSend ? 1.07 : 0.88)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: canSend)
                }
                .disabled(!canSend)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .overlay(Divider().overlay(Color(hex: "FFFFFF").opacity(0.07)), alignment: .top)
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
                Image(systemName: "sparkle")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "7C6FCD"))
                    .frame(width: 24, height: 24)
                    .background(Color(hex: "1E1C30"))
                    .clipShape(Circle())
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.system(size: 14.5))
                    .foregroundStyle(message.isUser ? Color.white : Color(hex: "EDEBF7"))
                    .padding(.horizontal, 14)
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
            Image(systemName: "sparkle")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "7C6FCD"))
                .frame(width: 24, height: 24)
                .background(Color(hex: "1E1C30"))
                .clipShape(Circle())

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
