import Foundation
import AppKit

@MainActor
class ChatViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var selectedChat: Chat?
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var streamedResponse: String = ""
    @Published var errorMessage: String?
    @Published var isConnected: Bool = false
    @Published var responseTime: TimeInterval?
    @Published var responseStartTime: Date?

    @Published var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: "serverURL") }
    }
    @Published var selectedModel: String {
        didSet { UserDefaults.standard.set(selectedModel, forKey: "selectedModel") }
    }
    @Published var availableModels: [String] = []

    private let ollamaService = OllamaService()
    private var streamingTask: Task<Void, Never>?

    init() {
        self.serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? "http://localhost:11434"
        self.selectedModel = UserDefaults.standard.string(forKey: "selectedModel") ?? ""
        loadChatsFromDatabase()
        Task {
            await testConnection()
        }
    }

    private func loadChatsFromDatabase() {
        chats = DatabaseManager.shared.loadChats()
        if let lastChat = chats.first {
            selectedChat = lastChat
        }
    }

    func testConnection() async {
        isConnected = false
        errorMessage = nil
        availableModels = []

        do {
            let connected = try await ollamaService.testConnection(to: serverURL)
            if connected {
                isConnected = true
                let models = try await ollamaService.fetchModels(from: serverURL)
                availableModels = models.map { $0.name }
                if selectedModel.isEmpty, let first = availableModels.first {
                    selectedModel = first
                }
            }
        } catch {
            errorMessage = "Cannot connect: \(error.localizedDescription)"
        }
    }

    func createNewChat() {
        let newChat = Chat()
        selectedChat = newChat
        chats.insert(newChat, at: 0)
        saveCurrentChat()
    }

    func selectChat(_ chat: Chat) {
        selectedChat = chat
    }

    func deleteChat(_ chat: Chat) {
        do {
            try DatabaseManager.shared.deleteChat(chat.id)
            chats.removeAll { $0.id == chat.id }
            if selectedChat?.id == chat.id {
                selectedChat = chats.first
            }
        } catch {
            errorMessage = "Failed to delete chat: \(error.localizedDescription)"
        }
    }

    func renameChat(_ chat: Chat, newTitle: String) {
        guard let index = chats.firstIndex(where: { $0.id == chat.id }) else { return }
        chats[index].title = newTitle
        chats[index].updatedAt = Date()
        saveChat(chats[index])
        if selectedChat?.id == chat.id {
            selectedChat = chats[index]
        }
    }

    func sendMessage() async {
        guard !selectedModel.isEmpty else {
            errorMessage = "Please select a model in Settings first"
            return
        }
        
        guard let chat = selectedChat else {
            createNewChat()
            await sendMessage()
            return
        }

        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        let userMessage = Message(role: "user", content: trimmedInput)
        appendMessage(userMessage, to: chat)

        inputText = ""
        isLoading = true
        streamedResponse = ""
        errorMessage = nil
        responseStartTime = Date()
        responseTime = nil

        streamingTask = Task {
            do {
                let fullResponse = try await fetchStreamingResponse(prompt: trimmedInput)
                let assistantMessage = Message(role: "assistant", content: fullResponse)
                appendMessage(assistantMessage, to: chat)
                if let startTime = responseStartTime {
                    responseTime = Date().timeIntervalSince(startTime)
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = "Error: \(error.localizedDescription)"
                }
            }
            isLoading = false
            responseStartTime = nil
        }
    }

    private func fetchStreamingResponse(prompt: String) async throws -> String {
        var fullResponse = ""
        var chunkCount = 0

        let stream: AsyncThrowingStream<String, Error> = await ollamaService.streamResponse(model: selectedModel, prompt: prompt, serverURL: serverURL)
        for try await chunk in stream {
            streamedResponse += chunk
            fullResponse += chunk
            chunkCount += 1
            print("Chunk \(chunkCount): \(chunk)")
        }
        
        print("Total chunks: \(chunkCount), Full response: \(fullResponse)")
        return fullResponse
    }

    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        Task {
            await ollamaService.cancelCurrentRequest()
        }
        isLoading = false
        streamedResponse = ""
    }

    func copyMessageToClipboard(_ message: Message) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
    }

    func deleteMessage(_ message: Message, from chat: Chat) {
        guard var chatIndex = chats.firstIndex(where: { $0.id == chat.id }) else { return }
        chats[chatIndex].messages.removeAll { $0.id == message.id }
        chats[chatIndex].updatedAt = Date()
        saveChat(chats[chatIndex])

        if selectedChat?.id == chat.id {
            selectedChat = chats[chatIndex]
        }
    }

    private func appendMessage(_ message: Message, to chat: Chat) {
        guard let index = chats.firstIndex(where: { $0.id == chat.id }) else { return }
        chats[index].messages.append(message)
        chats[index].updatedAt = Date()

        if selectedChat?.id == chat.id {
            selectedChat = chats[index]
        }

        saveCurrentChat()
    }

    private func saveCurrentChat() {
        guard let chat = selectedChat else { return }
        saveChat(chat)
    }

    private func saveChat(_ chat: Chat) {
        do {
            try DatabaseManager.shared.saveChat(chat)
            for message in chat.messages {
                try DatabaseManager.shared.saveMessage(message, chatId: chat.id)
            }
        } catch {
            print("Save chat error: \(error)")
        }
    }
}