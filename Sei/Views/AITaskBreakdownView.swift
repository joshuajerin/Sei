import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: MessageContent
    let isUser: Bool
}

enum MessageContent {
    case text(String)
    case task(AITaskResult)
}

struct AITaskResult: Decodable {
    let task: String
    let subtasks: [Subtask]
    struct Subtask: Decodable, Identifiable {
        let id = UUID()
        let title: String

        enum CodingKeys: String, CodingKey {
            case title
        }
    }
}

// Add this extension for robust JSON extraction
extension String {
    func firstMatch(of pattern: String, options: NSRegularExpression.Options = []) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let range = NSRange(self.startIndex..., in: self)
        if let match = regex.firstMatch(in: self, options: [], range: range) {
            if let range = Range(match.range, in: self) {
                return String(self[range])
            }
        }
        return nil
    }
}

struct AITaskBreakdownView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading = false
    @EnvironmentObject var todoViewModel: TodoViewModel
    @State private var likedTaskIDs: Set<UUID> = []

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser { Spacer() }
                                switch message.content {
                                case .text(let text):
                                    Text(text)
                                        .padding()
                                        .background(message.isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                case .task(let taskResult):
                                    VStack(alignment: .leading) {
                                        Text(taskResult.task)
                                            .font(.headline)
                                        ForEach(taskResult.subtasks) { subtask in
                                            Text("- \(subtask.title)")
                                        }
                                        HStack {
                                            Button(action: {
                                                likedTaskIDs.insert(message.id)
                                            }) {
                                                Image(systemName: likedTaskIDs.contains(message.id) ? "hand.thumbsup.fill" : "hand.thumbsup")
                                                    .foregroundColor(likedTaskIDs.contains(message.id) ? .green : .gray)
                                                Text(likedTaskIDs.contains(message.id) ? "Liked" : "Like")
                                            }
                                            .buttonStyle(.bordered)
                                            if likedTaskIDs.contains(message.id) {
                                                Button(action: {
                                                    Task {
                                                        await todoViewModel.addItemAndSubtasks(title: taskResult.task, subtasks: taskResult.subtasks.map { $0.title })
                                                        // Disable the button after adding
                                                        likedTaskIDs.remove(message.id)
                                                    }
                                                }) {
                                                    Text("Add to My List")
                                                        .font(.subheadline)
                                                        .padding(6)
                                                        .background(Color.blue.opacity(0.2))
                                                        .cornerRadius(8)
                                                }
                                                .padding(.leading, 8)
                                                .disabled(!likedTaskIDs.contains(message.id))
                                            }
                                        }
                                        .padding(.top, 8)
                                    }
                                    .padding()
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(12)
                                }
                                if !message.isUser { Spacer() }
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            HStack {
                TextField("Describe your task...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    sendMessage()
                }
                .disabled(inputText.isEmpty || isLoading)
            }
            .padding()
        }
        .navigationTitle("AI Task Breakdown")
    }

    func sendMessage() {
        let userMessage = ChatMessage(content: .text(inputText), isUser: true)
        messages.append(userMessage)
        let prompt = inputText
        inputText = ""
        isLoading = true

        Task {
            if let aiReplyString = await fetchAIResponse(prompt: prompt) {
                if let jsonString = aiReplyString.firstMatch(of: "\\{[\\s\\S]*\\}") {
                    print("Extracted JSON: \(jsonString)")
                    if let data = jsonString.data(using: .utf8) {
                        do {
                            let result = try JSONDecoder().decode(AITaskResult.self, from: data)
                            let aiTaskMessage = ChatMessage(content: .task(result), isUser: false)
                            messages.append(aiTaskMessage)
                        } catch {
                            print("Decoding error: \(error)")
                            let aiTextMessage = ChatMessage(content: .text(aiReplyString), isUser: false)
                            messages.append(aiTextMessage)
                        }
                    } else {
                        print("Could not convert JSON string to data")
                        let aiTextMessage = ChatMessage(content: .text(aiReplyString), isUser: false)
                        messages.append(aiTextMessage)
                    }
                } else {
                    print("No JSON found in reply")
                    let aiTextMessage = ChatMessage(content: .text(aiReplyString), isUser: false)
                    messages.append(aiTextMessage)
                }
            } else {
                let errorMsg = ChatMessage(content: .text("Sorry, I couldn't get a response."), isUser: false)
                messages.append(errorMsg)
            }
            isLoading = false
        }
    }

    func fetchAIResponse(prompt: String) async -> String? {
        guard let url = URL(string: "http://192.168.6.103:11434/api/chat") else { return nil }
        let systemPrompt = """
            You are an expert productivity assistant. When a user describes a goal, break it down into a main task and a list of subtasks. 
            Reply in the following JSON format:

            {
            "task": "Main task title",
            "subtasks": [
                {"title": "Subtask 1"},
                {"title": "Subtask 2"},
                ...
            ]
            }

            If you need more information, ask the user a clarifying question.
            """
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": prompt]
        ]
        let body: [String: Any] = [
            "model": "llama3.2",
            "messages": messages
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let raw = String(data: data, encoding: .utf8) else { return nil }
            var fullReply = ""
            let lines = raw.split(separator: "\n")

            if lines.count > 1 {
                for line in lines {
                    guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                    if let jsonDataChunk = line.data(using: .utf8) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: jsonDataChunk) as? [String: Any],
                               let messagePart = (json["message"] as? [String: Any])?["content"] as? String {
                                fullReply += messagePart
                            } else if line.trimmingCharacters(in: .whitespacesAndNewlines) == "{" || line.trimmingCharacters(in: .whitespacesAndNewlines) == "}" || line.contains("\"task\":") {
                                fullReply += String(line)
                            }
                        } catch {
                            print("Error decoding JSON line: \(error) - line: \(line)")
                            fullReply += String(line)
                        }
                    }
                }
            } else if let singleJsonData = raw.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: singleJsonData) as? [String: Any],
                       let messageContent = (json["message"] as? [String: Any])?["content"] as? String {
                        fullReply = messageContent
                    } else {
                        fullReply = raw
                    }
                } catch {
                    fullReply = raw
                }
            }

            return fullReply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Sorry, I couldn't process your request." : fullReply.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("AI error: \(error)")
        }
        return "Sorry, I couldn't process your request."
    }
}

#Preview {
    NavigationView {
        AITaskBreakdownView()
            .environmentObject(TodoViewModel())
    }
} 
