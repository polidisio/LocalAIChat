import Foundation

struct OllamaModel: Identifiable, Codable {
    var id: String { name }
    let name: String
    let modifiedAt: Date?
    let size: Int64?

    init(name: String, modifiedAt: Date? = nil, size: Int64? = nil) {
        self.name = name
        self.modifiedAt = modifiedAt
        self.size = size
    }
}

struct OllamaTagsResponse: Codable {
    let models: [OllamaModelInfo]

    struct OllamaModelInfo: Codable {
        let name: String
        let modifiedAt: String?
        let size: Int64?
    }
}

struct OllamaGenerateRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
    let keepAlive: Int? = nil

    enum CodingKeys: String, CodingKey {
        case model, prompt, stream
        case keepAlive = "keep_alive"
    }
}

struct OllamaGenerateResponse: Codable {
    let response: String
    let done: Bool?
}

enum OllamaError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(Int)
    case decodingError
    case noConnection

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .serverError(let code): return "Server error: \(code)"
        case .decodingError: return "Failed to decode response"
        case .noConnection: return "Cannot connect to server"
        }
    }
}