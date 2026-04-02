import XCTest
@testable import Voice2TextApp

final class LLMPromptTests: XCTestCase {
    func testSystemPromptIsConservative() {
        let prompt = Constants.llmSystemPrompt

        XCTAssertTrue(prompt.contains("conservative"))
        XCTAssertTrue(prompt.contains("ONLY fix"))
        XCTAssertTrue(prompt.contains("NEVER rewrite"))
        XCTAssertTrue(prompt.contains("NEVER add or remove"))
        XCTAssertTrue(prompt.contains("return it EXACTLY as-is"))
    }

    func testSystemPromptMentionsTechnicalTerms() {
        let prompt = Constants.llmSystemPrompt

        XCTAssertTrue(prompt.contains("Python"))
        XCTAssertTrue(prompt.contains("JSON"))
        XCTAssertTrue(prompt.contains("API"))
    }

    func testLLMRequestStructure() throws {
        let request = LLMRequest(
            model: "gpt-4",
            messages: [
                .init(role: "system", content: "test system"),
                .init(role: "user", content: "test user")
            ],
            temperature: 0.3
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["model"] as? String, "gpt-4")
        XCTAssertEqual(json["temperature"] as? Double, 0.3)

        let messages = json["messages"] as! [[String: String]]
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0]["role"], "system")
        XCTAssertEqual(messages[1]["role"], "user")
    }
}
