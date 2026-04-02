import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var testStatus: String = ""
    @State private var isTesting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("LLM Refinement Settings")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                Text("API Base URL")
                    .font(.subheadline)
                TextField("https://api.openai.com/v1", text: $settings.llmApiBaseURL)
                    .textFieldStyle(.roundedBorder)

                Text("API Key")
                    .font(.subheadline)
                SecureField("sk-...", text: $settings.llmApiKey)
                    .textFieldStyle(.roundedBorder)

                Text("Model")
                    .font(.subheadline)
                TextField("gpt-4", text: $settings.llmModel)
                    .textFieldStyle(.roundedBorder)
            }

            if !testStatus.isEmpty {
                Text(testStatus)
                    .font(.caption)
                    .foregroundColor(testStatus.contains("✓") ? .green : .red)
            }

            HStack {
                Button("Test") {
                    testConnection()
                }
                .disabled(isTesting || !settings.isLLMConfigured)

                Spacer()

                Button("Save") {
                    NSApplication.shared.keyWindow?.close()
                }
            }
        }
        .padding()
        .frame(width: 500, height: 300)
    }

    private func testConnection() {
        isTesting = true
        testStatus = "Testing..."

        Task {
            do {
                let service = LLMRefinementService()
                _ = try await service.refine(text: "test")
                await MainActor.run {
                    testStatus = "✓ Connection successful"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testStatus = "✗ Error: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
}
