import Foundation

struct LLMRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double

    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct LLMResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message

        struct Message: Codable {
            let content: String
        }
    }
}

@MainActor
class LLMRefinementService {
    func refine(text: String) async throws -> String {
        let settings = AppSettings.shared

        guard settings.isLLMConfigured else {
            throw LLMError.notConfigured
        }

        guard !settings.llmApiBaseURL.isEmpty,
              !settings.llmApiKey.isEmpty,
              !settings.llmModel.isEmpty else {
            throw LLMError.notConfigured
        }

        let url = URL(string: settings.llmApiBaseURL.trimmingCharacters(in: .whitespaces))!
            .appendingPathComponent("chat/completions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.llmApiKey)", forHTTPHeaderField: "Authorization")

        let llmRequest = LLMRequest(
            model: settings.llmModel,
            messages: [
                .init(role: "system", content: Constants.llmSystemPrompt),
                .init(role: "user", content: text)
            ],
            temperature: 0.3
        )

        request.httpBody = try JSONEncoder().encode(llmRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw LLMError.requestFailed
        }

        let llmResponse = try JSONDecoder().decode(LLMResponse.self, from: data)

        guard let refinedText = llmResponse.choices.first?.message.content else {
            throw LLMError.emptyResponse
        }

        return refinedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum LLMError: LocalizedError {
    case notConfigured
    case requestFailed
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "LLM is not configured"
        case .requestFailed:
            return "LLM request failed"
        case .emptyResponse:
            return "LLM returned empty response"
        }
    }
}
