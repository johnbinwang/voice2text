import XCTest
@testable import Voice2TextApp

final class AppSettingsTests: XCTestCase {
    var settings: AppSettings!

    override func setUp() async throws {
        settings = AppSettings.shared
    }

    func testDefaultLanguageIsChineseSimplified() {
        // Reset to default
        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
        let freshSettings = AppSettings()
        XCTAssertEqual(freshSettings.selectedLanguage, "zh-CN")
    }

    func testLanguagePersistence() {
        settings.selectedLanguage = "en-US"
        XCTAssertEqual(UserDefaults.standard.string(forKey: "selectedLanguage"), "en-US")

        settings.selectedLanguage = "ja-JP"
        XCTAssertEqual(UserDefaults.standard.string(forKey: "selectedLanguage"), "ja-JP")
    }

    func testLLMConfigurationValidation() {
        settings.llmApiBaseURL = ""
        settings.llmApiKey = ""
        settings.llmModel = ""
        XCTAssertFalse(settings.isLLMConfigured)

        settings.llmApiBaseURL = "https://api.openai.com/v1"
        settings.llmApiKey = "sk-test"
        settings.llmModel = "gpt-4"
        XCTAssertTrue(settings.isLLMConfigured)
    }

    func testLLMEnabledPersistence() {
        settings.llmEnabled = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "llmEnabled"))

        settings.llmEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "llmEnabled"))
    }

    func testAPIKeyCanBeCleared() {
        settings.llmApiKey = "sk-test"
        XCTAssertEqual(settings.llmApiKey, "sk-test")

        settings.llmApiKey = ""
        XCTAssertEqual(settings.llmApiKey, "")
        XCTAssertFalse(settings.isLLMConfigured)
    }
}
