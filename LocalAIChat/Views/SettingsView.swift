import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @State private var tempURL: String = ""
    @State private var showExportSuccess: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Ollama Server URL")
                    .font(.headline)
                TextField("http://localhost:11434", text: $tempURL)
                    .textFieldStyle(.roundedBorder)
                Text("Enter the URL of your Ollama server")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Model")
                        .font(.headline)
                    Spacer()
                    if !viewModel.availableModels.isEmpty {
                        Text("\(viewModel.availableModels.count) models")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if viewModel.availableModels.isEmpty {
                    HStack {
                        Text("No models found")
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            Task { await viewModel.testConnection() }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                } else {
                    Picker("Model", selection: $viewModel.selectedModel) {
                        ForEach(viewModel.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            HStack(spacing: 16) {
                Button(action: {
                    viewModel.serverURL = tempURL
                    Task {
                        await viewModel.testConnection()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reconnect")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button(action: { exportAllChats() }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Chats")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
                }
            }

            if showExportSuccess {
                Text("Chats exported successfully!")
                    .foregroundColor(.green)
                    .font(.caption)
            }

            Spacer()

            Button("Done") { dismiss() }
                .padding(.bottom)
        }
        .padding()
        .frame(width: 450, height: 420)
        .onAppear { tempURL = viewModel.serverURL }
    }

    private func exportAllChats() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json, .plainText]
        panel.nameFieldStringValue = "localai_export"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(viewModel.chats)
                try data.write(to: url)
                showExportSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showExportSuccess = false
                }
            } catch {
                print("Export error: \(error)")
            }
        }
    }
}