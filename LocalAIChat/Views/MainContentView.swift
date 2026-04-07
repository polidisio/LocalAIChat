import SwiftUI

struct MainContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showSettings: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ConversationListView(viewModel: viewModel)
                .frame(width: 260)

            Divider()

            ChatContentView(viewModel: viewModel, showSettings: $showSettings)
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .newChatRequested)) { _ in
            viewModel.createNewChat()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openChatRequested)) { notification in
            if let chatId = notification.object as? UUID,
               let chat = viewModel.chats.first(where: { $0.id == chatId }) {
                viewModel.selectChat(chat)
            }
        }
        .task {
            await viewModel.testConnection()
        }
    }
}