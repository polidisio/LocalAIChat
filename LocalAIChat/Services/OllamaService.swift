import Foundation

actor OllamaService {
    private let session: URLSession
    private let decoder = JSONDecoder()
    private var currentTask: URLSessionDataTask?

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 600
        self.session = URLSession(configuration: config)
    }

    func fetchModels(from serverURL: String) async throws -> [OllamaModel] {
        guard let url = URL(string: "\(serverURL)/api/tags") else {
            throw OllamaError.invalidURL
        }

        print("Fetching models from: \(url)")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            throw OllamaError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response: \(jsonString)")
        }

        let tagsResponse = try decoder.decode(OllamaTagsResponse.self, from: data)
        return tagsResponse.models.map { OllamaModel(name: $0.name, modifiedAt: parseDate($0.modifiedAt), size: $0.size) }
    }

    func generateResponse(model: String, prompt: String, serverURL: String) async throws -> String {
        guard let url = URL(string: "\(serverURL)/api/generate") else {
            throw OllamaError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        let body = OllamaGenerateRequest(model: model, prompt: prompt, stream: false)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OllamaError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let generateResponse = try decoder.decode(OllamaGenerateResponse.self, from: data)
        return generateResponse.response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func streamResponse(model: String, prompt: String, serverURL: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                await self.streamResponseImpl(model: model, prompt: prompt, serverURL: serverURL, continuation: continuation)
            }
        }
    }

    private func streamResponseImpl(model: String, prompt: String, serverURL: String, continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        guard let url = URL(string: "\(serverURL)/api/generate") else {
            continuation.finish(throwing: OllamaError.invalidURL)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 300

        let body = OllamaGenerateRequest(model: model, prompt: prompt, stream: true)
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                continuation.finish(throwing: OllamaError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0))
                return
            }

            guard let responseText = String(data: data, encoding: .utf8) else {
                continuation.finish()
                return
            }

            let lines = responseText.components(separatedBy: "\n").filter { !$0.isEmpty }
            for line in lines {
                var jsonString = line
                if line.hasPrefix("data: ") {
                    jsonString = String(line.dropFirst(6))
                }
                
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let responseChunk = json["response"] as? String {
                    continuation.yield(responseChunk)
                }
            }
            
            continuation.finish()
        } catch {
            continuation.finish(throwing: OllamaError.networkError(error))
        }
    }

    func cancelCurrentRequest() {
        currentTask?.cancel()
        currentTask = nil
    }

    func testConnection(to serverURL: String) async throws -> Bool {
        guard let url = URL(string: "\(serverURL)/api/tags") else {
            throw OllamaError.invalidURL
        }

        let (_, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.noConnection
        }

        return httpResponse.statusCode == 200
    }

    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
}