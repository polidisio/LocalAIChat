import SwiftUI

private let sidebarBlue = Color(red: 0.118, green: 0.251, blue: 0.686)
private let sidebarBlueDark = Color(red: 0.078, green: 0.153, blue: 0.435)

struct ConversationListView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var editingChat: Chat?
    @State private var newTitle: String = ""

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            chatListSection
        }
        .frame(minWidth: 240, maxWidth: 300)
        .sheet(item: $editingChat) { chat in
            RenameChatSheet(chat: chat, newTitle: $newTitle) { updated in
                viewModel.renameChat(chat, newTitle: updated)
                editingChat = nil
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "brain.head.side")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            Text("Chats")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Button(action: { viewModel.createNewChat() }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .buttonStyle(.plain)
        }
        .frame(height: 48)
        .padding(.horizontal, 16)
        .background(sidebarBlueDark)
    }

    private var chatListSection: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(viewModel.chats) { chat in
                    ConversationRowView(
                        chat: chat,
                        isSelected: viewModel.selectedChat?.id == chat.id,
                        onSelect: { viewModel.selectChat(chat) },
                        onRename: { editingChat = chat; newTitle = chat.title },
                        onDelete: { viewModel.deleteChat(chat) }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .background(sidebarBlue)
    }
}

struct ConversationRowView: View {
    let chat: Chat
    let isSelected: Bool
    let onSelect: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "message.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? sidebarBlue : .white.opacity(0.7))
                .frame(width: 20)

            Text(chat.displayTitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isSelected ? Color.white.opacity(0.15) : Color.clear)
        .overlay(
            Rectangle()
                .fill(isSelected ? Color.white : Color.clear)
                .frame(width: 3),
            alignment: .leading
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .contextMenu {
            Button("Rename") { onRename() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}

struct RenameChatSheet: View {
    let chat: Chat
    @Binding var newTitle: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Rename Chat")
                .font(.system(size: 17, weight: .semibold))

            TextField("Chat name", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            HStack(spacing: 16) {
                Button("Cancel") { dismiss() }
                Button("Save") { onSave(newTitle) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}