import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TodoViewModel()
    @State private var newItemTitle = ""
    @State private var isSidebarVisible = false
    
    var body: some View {
        ZStack {
            // Main Content
            NavigationView {
                List {
                    Section(header: Text("Tasks")) {
                        // Existing tasks first
                        ForEach(viewModel.items) { item in
                            TodoItemRow(item: item, viewModel: viewModel)
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
                .navigationTitle("Sei")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSidebarVisible.toggle()
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                        }
                    }
                }
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
                        .padding(.top, 70) // status bar + nav bar height for iPhone
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
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        Spacer()
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

struct TodoItemRow: View {
    let item: TodoItem
    @ObservedObject var viewModel: TodoViewModel
    
    var body: some View {
        HStack {
            Button(action: { viewModel.toggleItem(item) }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
            }
            Text(item.title)
                .strikethrough(item.isCompleted)
                .foregroundColor(item.isCompleted ? .gray : .primary)
            Spacer()
        }
        .swipeActions {
            Button(role: .destructive) {
                viewModel.deleteItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    ContentView()
} 
