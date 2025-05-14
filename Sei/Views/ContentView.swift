import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TodoViewModel
    @State private var newItemTitle = ""
    @State private var isSidebarVisible = false
    @EnvironmentObject var session: SessionManager
    @State private var userEmail: String? = nil
    @State private var expandedTaskIDs: Set<String> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main Content
                VStack(spacing: 0) {
                    // Custom navigation bar
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSidebarVisible.toggle()
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .padding(.leading)
                        
                        Spacer()
                        
                        Text("Sei")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Optional right button if needed
                        Button(action: {}) {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing)
                        .opacity(0) // Hide it for now, can be used later
                    }
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    
                    // List content
                    List {
                        Section(header: Text("Tasks")) {
                            ForEach(viewModel.items, id: \.id) { mainTask in
                                TaskUmbrellaView(
                                    mainTask: mainTask,
                                    subtasks: viewModel.subtasks.filter { $0.task_id == mainTask.id },
                                    isExpanded: expandedTaskIDs.contains(mainTask.id),
                                    onToggle: {
                                        if expandedTaskIDs.contains(mainTask.id) {
                                            expandedTaskIDs.remove(mainTask.id)
                                        } else {
                                            expandedTaskIDs.insert(mainTask.id)
                                        }
                                    },
                                    viewModel: viewModel
                                )
                            }
                            // Input field always at the bottom
                            HStack(spacing: 10) {
                                Button(action: {}) {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                                TextField("Add a task...", text: $newItemTitle, onCommit: addTask)
                                    .font(.body)
                                Spacer()
                                Button(action: addTask) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(newItemTitle.isEmpty ? .gray : .blue)
                                }
                                .disabled(newItemTitle.isEmpty)
                                .buttonStyle(.plain)
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.fetchTasks()
                        await viewModel.fetchAllSubtasks()
                    }
                }
                .onAppear {
                    Task {
                        await getUserEmail()
                    }
                }
                .task {
                    await viewModel.fetchTasks()
                    await viewModel.fetchAllSubtasks()
                }
                
                // Sidebar
                if isSidebarVisible {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSidebarVisible = false
                            }
                        }
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            // User info at the top
                            if let email = userEmail {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal)
                                .padding(.top, 24)
                            }
                            HStack {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        isSidebarVisible = false
                                    }
                                }) {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.title2)
                                }
                                Spacer()
                                Button(action: {
                                    // Focus the text field at the bottom
                                }) {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 24)
                            .padding(.bottom, 16)
                            Divider()
                            Text("Categories")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 16)
                            VStack(alignment: .leading, spacing: 20) {
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.blue)
                                        Text("Important")
                                            .foregroundColor(.blue)
                                    }
                                }
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.blue)
                                        Text("Today")
                                            .foregroundColor(.blue)
                                    }
                                }
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.blue)
                                        Text("Upcoming")
                                            .foregroundColor(.blue)
                                    }
                                }
                                // Add navigation to AI Task Breakdown
                                NavigationLink(destination: AITaskBreakdownView()) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.purple)
                                        Text("AI Task Breakdown")
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            Spacer()
                            // Log Out button at the bottom
                            Button(action: {
                                Task {
                                    await session.signOut()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.backward.circle.fill")
                                        .foregroundColor(.red)
                                    Text("Log Out")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        }
                        .frame(width: 300)
                        .background(Color.white)
                        // No corner radius, no shadow, no vertical padding
                        .edgesIgnoringSafeArea(.all)
                        Spacer()
                    }
                    .transition(.move(edge: .leading))
                }
            }
        }
    }
    
    private func getUserEmail() async {
        do {
            // Access the session directly without if let
            let authSession = try await SupabaseManager.shared.client.auth.session
            DispatchQueue.main.async {
                self.userEmail = authSession.user.email
            }
        } catch {
            print("Error getting user email: \(error)")
        }
    }
    
    private func addTask() {
        let trimmed = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            newItemTitle = ""
            return
        }
        // Prevent duplicate consecutive tasks
        if let last = viewModel.items.last, last.title == trimmed {
            newItemTitle = ""
            return
        }
        viewModel.addItem(title: trimmed)
        DispatchQueue.main.async {
            newItemTitle = ""
        }
    }
}

struct TaskUmbrellaView: View {
    let mainTask: TodoItem
    let subtasks: [Subtask]
    let isExpanded: Bool
    let onToggle: () -> Void
    let viewModel: TodoViewModel
    
    var body: some View {
        DisclosureGroup(isExpanded: .constant(isExpanded)) {
            ForEach(subtasks) { subtask in
                HStack {
                    Button(action: { viewModel.toggleItem(mainTask) }) {
                        Image(systemName: mainTask.is_completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(mainTask.is_completed ? .green : .gray)
                    }
                    Text(subtask.title)
                        .strikethrough(subtask.is_completed)
                        .foregroundColor(subtask.is_completed ? .gray : .primary)
                    Spacer()
                }
                .swipeActions {
                    Button(role: .destructive) {
                        viewModel.deleteItem(mainTask)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        } label: {
            HStack {
                Button(action: { viewModel.toggleItem(mainTask) }) {
                    Image(systemName: mainTask.is_completed ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(mainTask.is_completed ? .green : .gray)
                }
                Text(mainTask.title)
                    .strikethrough(mainTask.is_completed)
                    .foregroundColor(mainTask.is_completed ? .gray : .primary)
                Spacer()
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                }
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                viewModel.deleteItem(mainTask)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    NavigationView {
        ContentView()
            .environmentObject(TodoViewModel())
            .environmentObject(SessionManager())
    }
} 
