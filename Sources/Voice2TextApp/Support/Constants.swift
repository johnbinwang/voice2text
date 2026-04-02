import Foundation

enum Constants {
    // Default language
    static let defaultLanguage = "zh-CN"

    // Supported languages
    static let supportedLanguages: [(code: String, name: String)] = [
        ("en-US", "English"),
        ("zh-CN", "简体中文"),
        ("zh-TW", "繁體中文"),
        ("ja-JP", "日本語"),
        ("ko-KR", "한국어")
    ]

    // HUD dimensions
    static let hudHeight: CGFloat = 56
    static let hudCornerRadius: CGFloat = 28
    static let hudMinWidth: CGFloat = 160
    static let hudMaxWidth: CGFloat = 560
    static let hudWidthAnimationDuration: TimeInterval = 0.25
    static let hudEntranceAnimationDuration: TimeInterval = 0.35
    static let hudExitAnimationDuration: TimeInterval = 0.22

    // Waveform
    static let waveformWidth: CGFloat = 44
    static let waveformHeight: CGFloat = 32
    static let waveformBarCount = 5
    static let waveformBarWeights: [CGFloat] = [0.5, 0.8, 1.0, 0.75, 0.55]
    static let waveformJitterAmount: CGFloat = 0.04
    static let waveformAttackRate: CGFloat = 0.4
    static let waveformReleaseRate: CGFloat = 0.15

    // LLM
    static let llmSystemPrompt = """
You are a conservative speech recognition error corrector. Your ONLY job is to fix obvious speech recognition errors.

Rules:
1. ONLY fix clear recognition mistakes (e.g., Chinese homophones like "配森" → "Python", "杰森" → "JSON")
2. NEVER rewrite, rephrase, polish, or improve the text
3. NEVER add or remove content
4. If the input looks correct, return it EXACTLY as-is
5. Preserve all punctuation, spacing, and formatting
6. Focus on technical terms that are commonly misrecognized (Python, JSON, API, macOS, Swift, Xcode, etc.)

Return ONLY the corrected text, nothing else.
"""

    // History
    static let appSupportDirectoryName = "Voice2Text"
    static let transcriptionHistoryFileName = "transcriptions.jsonl"
}
