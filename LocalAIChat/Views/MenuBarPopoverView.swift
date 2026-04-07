import SwiftUI

struct MenuBarPopoverView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            recentChatsSection
            Divider()
            actionsSection
        }
        .frame(width: 280)
        .padding(.vertical, 8)
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: "brain.head.side")
                .font(.title2)
                .foregroundColor(.accentColor)
            Text("LLMBox")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var recentChatsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent Chats")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            if viewModel.recentChats.isEmpty {
                Text("No recent chats")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.recentChats) { chat in
                    Button(action: { viewModel.openChat(chat) }) {
                        HStack {
                            Image(systemName: "message.fill")
                                .font(.caption)
                            Text(chat.displayTitle)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering {
                            NSApp.orderedWindows.first { $0.isKeyWindow }?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    private var actionsSection: some View {
        VStack(spacing: 4) {
            Button(action: { viewModel.newChat() }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("New Chat")
                    Spacer()
                    Text("⌘N")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Button(action: { viewModel.showWindow() }) {
                HStack {
                    Image(systemName: "macwindow")
                    Text("Show Window")
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.vertical, 4)

            Button(action: { viewModel.quit() }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit")
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
    }
}