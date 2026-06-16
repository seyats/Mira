import Foundation

struct ModelOption: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String?
}

struct SuggestionCard: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
}

struct ProviderOption: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let kind: ProviderKind
}

enum ProviderKind: String, CaseIterable, Hashable {
    case openAI
    case openRouter
    case ollama
    case localMock

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .openRouter: return "OpenRouter"
        case .ollama: return "Ollama"
        case .localMock: return "Local demo"
        }
    }
}

struct ChatMessage: Identifiable, Hashable {
    enum Role: Hashable {
        case user
        case assistant
        case system
    }

    let id = UUID()
    let role: Role
    var text: String
    let date = Date()
    var isStreaming = false
}

struct Conversation: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var preview: String
    var messages: [ChatMessage]
}

protocol ChatProvider {
    var kind: ProviderKind { get }
    func reply(messages: [ChatMessage], model: String) async throws -> String
}

@MainActor
final class ChatStore: ObservableObject {
    @Published var currentModel = "Gemma 3 QAT (1B)"
    @Published var currentProvider: ProviderKind = .openAI
    @Published var conversations: [Conversation] = [
        Conversation(
            title: "New chat",
            preview: "Ask anything",
            messages: [
                ChatMessage(role: .assistant, text: "Привет. Я могу помочь как ChatGPT: отвечать, писать тексты, объяснять и вести диалог.")
            ]
        )
    ]
    @Published var currentConversationID: Conversation.ID?
    @Published var isThinking = false
    @Published var streamText = ""

    let availableModels: [ModelOption] = [
        .init(name: "Bonsai (8B)", subtitle: nil),
        .init(name: "Qwen 3.5 (2B)", subtitle: nil),
        .init(name: "SmolLM 3 (3B)", subtitle: nil),
        .init(name: "Gemma 3 QAT (1B)", subtitle: nil)
    ]

    let suggestionCards: [SuggestionCard] = [
        .init(title: "Discover", subtitle: "my next book"),
        .init(title: "Tell me", subtitle: "something fascinating"),
        .init(title: "Design", subtitle: "a workout routine"),
        .init(title: "Explain", subtitle: "a complex topic simply")
    ]

    let providers: [ProviderOption] = [
        .init(name: "OpenAI", subtitle: "Best quality", kind: .openAI),
        .init(name: "OpenRouter", subtitle: "Many free models", kind: .openRouter),
        .init(name: "Ollama", subtitle: "Local on your Mac/PC", kind: .ollama),
        .init(name: "Local demo", subtitle: "No key needed", kind: .localMock)
    ]

    private let providerClients: [ProviderKind: ChatProvider] = [
        .openAI: OpenAIProvider(),
        .openRouter: OpenRouterProvider(),
        .ollama: OllamaProvider(),
        .localMock: LocalMockProvider()
    ]

    init() {
        currentConversationID = conversations.first?.id
    }

    var currentConversation: Conversation {
        get {
            conversations.first(where: { $0.id == currentConversationID }) ?? conversations[0]
        }
        set {
            guard let index = conversations.firstIndex(where: { $0.id == currentConversationID }) else { return }
            conversations[index] = newValue
        }
    }

    func select(_ id: Conversation.ID) {
        currentConversationID = id
    }

    func newChat() {
        let conversation = Conversation(
            title: "New chat",
            preview: "Ask anything",
            messages: [
                ChatMessage(role: .assistant, text: "Привет. Я готов помочь.")
            ]
        )
        conversations.insert(conversation, at: 0)
        currentConversationID = conversation.id
    }

    func sendHello() {
        if currentConversation.messages.count == 1 {
            send("Hello")
        }
    }

    func setProvider(_ provider: ProviderKind) {
        currentProvider = provider
    }

    func providerName() -> String {
        currentProvider.displayName
    }

    func send(_ text: String) {
        guard let index = conversations.firstIndex(where: { $0.id == currentConversationID }) else { return }
        conversations[index].messages.append(ChatMessage(role: .user, text: text))
        conversations[index].title = title(from: text)
        conversations[index].preview = text
        isThinking = true
        streamText = ""

        let snapshot = conversations[index].messages
        let provider = providerClients[currentProvider] ?? LocalMockProvider()
        let model = currentModel

        Task {
            do {
                let reply = try await provider.reply(messages: snapshot, model: model)
                await MainActor.run {
                    self.typeReply(reply, in: index)
                }
            } catch {
                await MainActor.run {
                    self.typeReply(self.mockReply(for: text), in: index)
                }
            }
        }
    }

    func regenerateLastAnswer() {
        guard let index = conversations.firstIndex(where: { $0.id == currentConversationID }) else { return }
        guard conversations[index].messages.contains(where: { $0.role == .user }) else { return }
        conversations[index].messages.removeAll(where: { $0.role == .assistant })
        isThinking = true
        streamText = ""
        let provider = providerClients[currentProvider] ?? LocalMockProvider()
        let model = currentModel
        let snapshot = conversations[index].messages

        Task {
            do {
                let reply = try await provider.reply(messages: snapshot, model: model)
                await MainActor.run {
                    self.typeReply(reply, in: index)
                }
            } catch {
                await MainActor.run {
                    self.typeReply(self.mockReply(for: snapshot.last?.text ?? ""), in: index)
                }
            }
        }
    }

    private func typeReply(_ reply: String, in index: Int) {
        let assistant = ChatMessage(role: .assistant, text: "")
        conversations[index].messages.append(assistant)
        let messageIndex = conversations[index].messages.count - 1
        conversations[index].preview = reply

        Task {
            let chunks = split(reply, size: 3)
            for chunk in chunks {
                try? await Task.sleep(nanoseconds: 40_000_000)
                await MainActor.run {
                    self.conversations[index].messages[messageIndex].text += chunk
                    self.conversations[index].messages[messageIndex].isStreaming = true
                    self.streamText = self.conversations[index].messages[messageIndex].text
                }
            }
            await MainActor.run {
                self.conversations[index].messages[messageIndex].isStreaming = false
                self.isThinking = false
                self.streamText = ""
            }
        }
    }

    private func split(_ text: String, size: Int) -> [String] {
        guard !text.isEmpty else { return [] }
        var result: [String] = []
        var index = text.startIndex
        while index < text.endIndex {
            let end = text.index(index, offsetBy: size, limitedBy: text.endIndex) ?? text.endIndex
            result.append(String(text[index..<end]))
            index = end
        }
        return result
    }

    private func title(from text: String) -> String {
        let clipped = text.split(separator: " ").prefix(4).joined(separator: " ")
        return clipped.isEmpty ? "New chat" : String(clipped)
    }

    private func mockReply(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("code") || lower.contains("код") {
            return "Yes. I can write the SwiftUI code and wire the UI exactly to your reference."
        }
        if lower.contains("design") || lower.contains("дизайн") {
            return "I will keep the dark glass layout, large rounded cards, and the ChatGPT-like bottom dock."
        }
        if lower.contains("api") || lower.contains("openai") {
            return "I can connect OpenAI, OpenRouter, or Ollama, and show typing while the answer is streaming."
        }
        return "Understood. I can continue in this style and make the app feel much closer to ChatGPT."
    }
}

struct LocalMockProvider: ChatProvider {
    let kind: ProviderKind = .localMock
    func reply(messages: [ChatMessage], model: String) async throws -> String {
        let text = messages.last(where: { $0.role == .user })?.text ?? ""
        try await Task.sleep(nanoseconds: 650_000_000)
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "How can I help?"
        }
        return "I am using the local demo provider. Ask me anything and I will answer in a ChatGPT-like style."
    }
}
