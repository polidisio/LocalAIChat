import SwiftUI

struct ChatContentView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var showSettings: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            messagesView
            Divider()
            inputView
        }
        .frame(minWidth: 400)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "brain.head.side")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("LocalAI")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    
                    Text(viewModel.isConnected ? "Online" : "Offline")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let responseTime = viewModel.responseTime {
                Text(String(format: "%.1fs", responseTime))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var messagesView: some View {
        Group {
            if let chat = viewModel.selectedChat {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(chat.messages) { message in
                                MessageBubble(
                                    content: message.content,
                                    isUser: message.isUser,
                                    timestamp: message.timestamp
                                )
                                .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                TypingIndicatorView()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(NSColor.textBackgroundColor))
                    .onChange(of: chat.messages.count) { _, _ in
                        if let lastMessage = chat.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.streamedResponse) { _, _ in
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            } else {
                EmptyChatView()
            }
        }
    }
    
    private var inputView: some View {
        HStack(spacing: 12) {
            TextField("Ask anything...", text: $viewModel.inputText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onSubmit {
                    Task { await viewModel.sendMessage() }
                }
            
            SendButton(isEnabled: !viewModel.inputText.isEmpty && !viewModel.isLoading) {
                Task { await viewModel.sendMessage() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
