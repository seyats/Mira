import Foundation

struct OpenAIProvider: ChatProvider {
    let kind: ProviderKind = .openAI

    func reply(messages: [ChatMessage], model: String) async throws -> String {
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        guard !apiKey.isEmpty else { throw URLError(.userAuthenticationRequired) }
        return try await ResponsesProvider(apiKey: apiKey, baseURL: URL(string: "https://api.openai.com/v1")!, model: model).reply(messages: messages)
    }
}

struct OpenRouterProvider: ChatProvider {
    let kind: ProviderKind = .openRouter

    func reply(messages: [ChatMessage], model: String) async throws -> String {
        let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? ""
        guard !apiKey.isEmpty else { throw URLError(.userAuthenticationRequired) }
        let openRouterModel = ProcessInfo.processInfo.environment["OPENROUTER_MODEL"] ?? "openai/gpt-oss-20b"
        return try await ResponsesProvider(apiKey: apiKey, baseURL: URL(string: "https://openrouter.ai/api/v1")!, model: openRouterModel).reply(messages: messages)
    }
}

struct OllamaProvider: ChatProvider {
    let kind: ProviderKind = .ollama

    func reply(messages: [ChatMessage], model: String) async throws -> String {
        let host = ProcessInfo.processInfo.environment["OLLAMA_BASE_URL"] ?? "http://127.0.0.1:11434"
        let url = URL(string: "\(host)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": ProcessInfo.processInfo.environment["OLLAMA_MODEL"] ?? "llama3.1",
            "stream": false,
            "messages": messages.map {
                [
                    "role": $0.role == .user ? "user" : "assistant",
                    "content": $0.text
                ]
            }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let message = json?["message"] as? [String: Any], let content = message["content"] as? String {
            return content
        }
        if let responseText = json?["response"] as? String {
            return responseText
        }
        return "Ollama returned no text."
    }
}

struct ResponsesProvider {
    let apiKey: String
    let baseURL: URL
    let model: String

    func reply(messages: [ChatMessage]) async throws -> String {
        let url = baseURL.appendingPathComponent("responses")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AuroraChat/1.0", forHTTPHeaderField: "User-Agent")

        let input = messages.map { message in
            [
                "role": message.role == .user ? "user" : "assistant",
                "content": message.text
            ]
        }

        let body: [String: Any] = [
            "model": model,
            "input": input
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let text = extractOutputText(from: object) {
            return text
        }
        if let raw = String(data: data, encoding: .utf8), let text = extractFromRaw(raw) {
            return text
        }
        return "Sorry, I couldn't parse the response."
    }

    private func extractFromRaw(_ raw: String) -> String? {
        guard let data = raw.data(using: .utf8) else { return nil }
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return extractOutputText(from: object)
    }

    private func extractOutputText(from object: [String: Any]?) -> String? {
        if let direct = object?["output_text"] as? String, !direct.isEmpty {
            return direct
        }
        if let output = object?["output"] as? [[String: Any]] {
            for item in output {
                if let content = item["content"] as? [[String: Any]] {
                    for part in content {
                        if let text = part["text"] as? String, !text.isEmpty {
                            return text
                        }
                    }
                }
            }
        }
        return nil
    }
}
