import SwiftUI
import PhotosUI

struct ChatView: View {
    @StateObject private var api = PebbAPI.shared
    @State private var input = ""
    @State private var showAccount = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?

    var body: some View {
        VStack(spacing: 0) {
            topBar
            messagesList
        }
        .safeAreaInset(edge: .bottom) {
            inputBar
        }
        .background(Color(hex: "0B0A12"))
        .task { try? await api.loadHistory() }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 9) {
                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "7C6FCD"))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: "1E1C30"))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                Text("Pebb")
                    .font(.custom("Fraunces", size: 19).weight(.bold))
                    .foregroundColor(Color(hex: "EDEBF7"))
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
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color(hex: "FFFFFF").opacity(0.12), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 11))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Color(hex: "0B0A12").opacity(0.82))
        .overlay(Divider().overlay(Color(hex: "FFFFFF").opacity(0.07)), alignment: .bottom)
    }

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
            .onChange(of: api.messages.count) {
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onChange(of: api.isTyping) {
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

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
                                .foregroundColor(Color(hex: "F87171"))
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
                        .foregroundColor(Color(hex: "6E6A8A"))
                        .frame(width: 40, height: 40)
                        .background(Color(hex: "1E1C30"))
                        .overlay(Circle().stroke(Color(hex: "FFFFFF").opacity(0.12), lineWidth: 1))
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
                    .foregroundColor(Color(hex: "EDEBF7"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(minHeight: 40)
                    .background(Color(hex: "1E1C30"))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "7C6FCD").opacity(0.4), lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .onSubmit { send() }
                    .submitLabel(.send)

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(canSend ? Color(hex: "7C6FCD") : Color(hex: "252340"))
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "7C6FCD").opacity(canSend ? 0.4 : 0), radius: 12)
                }
                .disabled(!canSend)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(Color(hex: "0B0A12").opacity(0.95))
        .overlay(Divider().overlay(Color(hex: "FFFFFF").opacity(0.07)), alignment: .top)
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImageData != nil
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        input = ""
        let imgData = selectedImageData
        selectedImageData = nil
        selectedPhoto = nil
        Task { try? await api.sendMessage(text, imageData: imgData) }
    }
}

// MARK: - Message Row
struct MessageRow: View {
    let message: ChatMessage
    @State private var appear = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer(minLength: 60) }
            if !message.isUser {
                Image(systemName: "sparkle")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "7C6FCD"))
                    .frame(width: 24, height: 24)
                    .background(Color(hex: "1E1C30"))
                    .clipShape(Circle())
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.system(size: 14.5))
                    .foregroundColor(message.isUser ? .white : Color(hex: "EDEBF7"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isUser ? Color(hex: "7C6FCD") : Color(hex: "1E1C30"))
                    .clipShape(bubbleShape)
                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)

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
            .scaleEffect(appear ? 1 : 0.9)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.05)) { appear = true }
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
            topLeadingRadius: message.isUser ? r : r,
            bottomLeadingRadius: message.isUser ? r : tip,
            bottomTrailingRadius: message.isUser ? tip : r,
            topTrailingRadius: message.isUser ? r : r
        )
    }
}

// MARK: - Keyboard dismiss
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
                .foregroundColor(Color(hex: "7C6FCD"))
                .frame(width: 24, height: 24)
                .background(Color(hex: "1E1C30"))
                .clipShape(Circle())

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: "7C6FCD"))
                        .frame(width: 7, height: 7)
                        .offset(y: bounce ? -5 : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.45).repeatForever().delay(Double(i) * 0.14), value: bounce)
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
