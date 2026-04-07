import Foundation
import AppKit

@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var recentChats: [Chat] = []

    var onShowWindow: () -> Void
    var onNewChat: () -> Void
    var onQuit: () -> Void

    init(onShowWindow: @escaping () -> Void, onNewChat: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onShowWindow = onShowWindow
        self.onNewChat = onNewChat
        self.onQuit = onQuit
        loadRecentChats()
    }

    func loadRecentChats() {
        let allChats = DatabaseManager.shared.loadChats()
        recentChats = Array(allChats.prefix(5))
    }

    func showWindow() {
        onShowWindow()
    }

    func newChat() {
        onNewChat()
    }

    func quit() {
        onQuit()
    }

    func openChat(_ chat: Chat) {
        NotificationCenter.default.post(name: .openChatRequested, object: chat.id)
        onShowWindow()
    }
}

extension Notification.Name {
    static let openChatRequested = Notification.Name("openChatRequested")
}