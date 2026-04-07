import SwiftUI

struct ChatContentView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
                .background(Color.white.opacity(0.2))
            messagesView
            Divider()
                .background(Color.gray.opacity(0.3))
            inputView
        }
        .frame(minWidth: 400)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            if let chat = viewModel.selectedChat {
                Text(chat.displayTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            } else {
                Text("LocalAIChat")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            HStack(spacing: 10) {
                if let responseTime = viewModel.responseTime {
                    Text(String(format: "%.1fs", responseTime))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(4)
                }

                Circle()
                    .fill(viewModel.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white)
                }

                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .background(headerBlue)
    }

    private var messagesView: some View {
        Group {
            if let chat = viewModel.selectedChat {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(chat.messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    onCopy: { viewModel.copyMessageToClipboard(message) },
                                    onDelete: { viewModel.deleteMessage(message, from: chat) }
                                )
                                .id(message.id)
                            }

                            if viewModel.isLoading && !viewModel.streamedResponse.isEmpty {
                                MessageBubbleView(
                                    message: Message(role: "assistant", content: viewModel.streamedResponse),
                                    onCopy: {},
                                    onDelete: {}
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(chatBackgroundGray)
                    .onChange(of: chat.messages.count) { _, _ in
                        if let lastMessage = chat.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.streamedResponse) { _, _ in
                        withAnimation {
                            proxy.scrollTo("streaming", anchor: .bottom)
                        }
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.side")
                        .font(.system(size: 56))
                        .foregroundColor(.gray)
                    Text("Select a chat or create a new one")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Button("New Chat") {
                        viewModel.createNewChat()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(chatBackgroundGray)
            }
        }
    }

    private var inputView: some View {
        HStack(spacing: 12) {
            TextField("Ask something...", text: $viewModel.inputText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(10)
                .onSubmit {
                    Task { await viewModel.sendMessage() }
                }

            Button(action: {
                Task { await viewModel.sendMessage() }
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(viewModel.inputText.isEmpty ? sendButtonDisabledBlue : sendButtonBlue)
                    .cornerRadius(10)
            }
            .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
        .background(inputBackgroundGray)
    }
}

private let headerBlue = Color(red: 0.145, green: 0.388, blue: 0.922)
private let chatBackgroundGray = Color(red: 0.961, green: 0.961, blue: 0.961)
private let inputBackgroundGray = Color(red: 0.933, green: 0.933, blue: 0.933)
private let userBubbleBlue = Color(red: 0.231, green: 0.510, blue: 0.965)
private let assistantBubbleBlue = Color(red: 0.231, green: 0.510, blue: 0.965).opacity(0.15)
private let assistantTextBlue = Color(red: 0.078, green: 0.153, blue: 0.435)
private let sendButtonBlue = Color(red: 0.145, green: 0.388, blue: 0.922)
private let sendButtonDisabledBlue = Color(red: 0.6, green: 0.7, blue: 0.85)

struct MessageBubbleView: View {
    let message: Message
    let onCopy: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.isSystem ? "System" : (message.isUser ? "You" : "Assistant"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)

                Text(message.content)
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(messageBackground)
                    .foregroundColor(message.isUser ? .white : assistantTextBlue)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser { Spacer(minLength: 60) }
        }
        .contextMenu {
            Button("Copy") { onCopy() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }

    private var messageBackground: Color {
        if message.isUser { return userBubbleBlue }
        if message.isSystem { return Color(red: 0.996, green: 0.953, blue: 0.780) }
        return assistantBubbleBlue
    }
}