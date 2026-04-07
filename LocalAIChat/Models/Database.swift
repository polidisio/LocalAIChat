import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?

    private let chatsTable = Table("chats")
    private let messagesTable = Table("messages")

    private let id = Expression<String>("id")
    private let title = Expression<String>("title")
    private let createdAt = Expression<Double>("created_at")
    private let updatedAt = Expression<Double>("updated_at")
    private let role = Expression<String>("role")
    private let content = Expression<String>("content")
    private let timestamp = Expression<Double>("timestamp")

    private let messageChatId = Expression<String>("chat_id")

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = getDatabasePath()
            db = try Connection(path)
            try createTables()
        } catch {
            print("Database setup error: \(error)")
        }
    }

    private func getDatabasePath() -> String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("LLMBox", isDirectory: true)

        if !FileManager.default.fileExists(atPath: appFolder.path) {
            try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }

        return appFolder.appendingPathComponent("localai.sqlite3").path
    }

    private func createTables() throws {
        try db?.run(chatsTable.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(title)
            t.column(createdAt)
            t.column(updatedAt)
        })

        try db?.run(messagesTable.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(messageChatId)
            t.column(role)
            t.column(content)
            t.column(timestamp)
            t.foreignKey(messageChatId, references: chatsTable, id, delete: .cascade)
        })
    }

    func saveChat(_ chat: Chat) throws {
        let insert = chatsTable.insert(or: .replace,
            id <- chat.id.uuidString,
            title <- chat.title,
            createdAt <- chat.createdAt.timeIntervalSince1970,
            updatedAt <- chat.updatedAt.timeIntervalSince1970
        )
        try db?.run(insert)
    }

    func loadChats() -> [Chat] {
        guard let db = db else { return [] }
        var chats: [Chat] = []

        do {
            for row in try db.prepare(chatsTable.order(updatedAt.desc)) {
                let chat = Chat(
                    id: UUID(uuidString: row[id]) ?? UUID(),
                    title: row[title],
                    messages: loadMessages(forChatId: row[id]),
                    createdAt: Date(timeIntervalSince1970: row[createdAt]),
                    updatedAt: Date(timeIntervalSince1970: row[updatedAt])
                )
                chats.append(chat)
            }
        } catch {
            print("Load chats error: \(error)")
        }

        return chats
    }

    func deleteChat(_ chatId: UUID) throws {
        let chat = chatsTable.filter(id == chatId.uuidString)
        try db?.run(chat.delete())
    }

    func updateChatTitle(_ chatId: UUID, newTitle: String) throws {
        let chat = chatsTable.filter(id == chatId.uuidString)
        try db?.run(chat.update(
            title <- newTitle,
            updatedAt <- Date().timeIntervalSince1970
        ))
    }

    func saveMessage(_ message: Message, chatId: UUID) throws {
        let insert = messagesTable.insert(or: .replace,
            id <- message.id.uuidString,
            messageChatId <- chatId.uuidString,
            role <- message.role,
            content <- message.content,
            timestamp <- message.timestamp.timeIntervalSince1970
        )
        try db?.run(insert)

        let chat = chatsTable.filter(id == chatId.uuidString)
        try db?.run(chat.update(updatedAt <- Date().timeIntervalSince1970))
    }

    func loadMessages(forChatId chatIdString: String) -> [Message] {
        guard let db = db else { return [] }
        var messages: [Message] = []

        do {
            let query = messagesTable
                .filter(messageChatId == chatIdString)
                .order(timestamp.asc)

            for row in try db.prepare(query) {
                let message = Message(
                    id: UUID(uuidString: row[id]) ?? UUID(),
                    role: row[role],
                    content: row[content],
                    timestamp: Date(timeIntervalSince1970: row[timestamp])
                )
                messages.append(message)
            }
        } catch {
            print("Load messages error: \(error)")
        }

        return messages
    }

    func deleteMessage(_ messageId: UUID) throws {
        let message = messagesTable.filter(id == messageId.uuidString)
        try db?.run(message.delete())
    }
}