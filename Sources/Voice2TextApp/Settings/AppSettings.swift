import Foundation

@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // Keys
    private enum Keys {
        static let selectedLanguage = "selectedLanguage"
        static let llmEnabled = "llmEnabled"
        static let llmApiBaseURL = "llmApiBaseURL"
        static let llmApiKey = "llmApiKey"
        static let llmModel = "llmModel"
    }

    // Language
    @Published var selectedLanguage: String {
        didSet {
            defaults.set(selectedLanguage, forKey: Keys.selectedLanguage)
        }
    }

    // LLM settings
    @Published var llmEnabled: Bool {
        didSet {
            defaults.set(llmEnabled, forKey: Keys.llmEnabled)
        }
    }

    @Published var llmApiBaseURL: String {
        didSet {
            defaults.set(llmApiBaseURL, forKey: Keys.llmApiBaseURL)
        }
    }

    @Published var llmApiKey: String {
        didSet {
            defaults.set(llmApiKey, forKey: Keys.llmApiKey)
        }
    }

    @Published var llmModel: String {
        didSet {
            defaults.set(llmModel, forKey: Keys.llmModel)
        }
    }

    private init() {
        // Load language (default to zh-CN)
        self.selectedLanguage = defaults.string(forKey: Keys.selectedLanguage) ?? Constants.defaultLanguage

        // Load LLM settings
        self.llmEnabled = defaults.bool(forKey: Keys.llmEnabled)
        self.llmApiBaseURL = defaults.string(forKey: Keys.llmApiBaseURL) ?? "https://api.openai.com/v1"
        self.llmApiKey = defaults.string(forKey: Keys.llmApiKey) ?? ""
        self.llmModel = defaults.string(forKey: Keys.llmModel) ?? "gpt-4"
    }

    var isLLMConfigured: Bool {
        !llmApiBaseURL.isEmpty && !llmApiKey.isEmpty && !llmModel.isEmpty
    }
}
