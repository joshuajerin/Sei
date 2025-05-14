import Foundation
import SwiftUI
import Supabase

struct NewTask: Encodable {
    let user_id: UUID
    let title: String
    let is_completed: Bool
}

struct NewSubtask: Encodable {
    let task_id: UUID
    let title: String
    let is_completed: Bool
}

struct Subtask: Identifiable, Codable {
    let id: String
    let task_id: String
    let title: String
    let is_completed: Bool
    let created_at: Date
}

class TodoViewModel: ObservableObject {
    @Published var items: [TodoItem] = []
    @Published var subtasks: [Subtask] = []
    
    // Fetch tasks for the current user
    func fetchTasks() async {
        do {
            let tasks: [TodoItem] = try await SupabaseManager.shared.client.database
                .from("tasks")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            print("Fetched tasks: \(tasks)")
            if let firstTask = tasks.first {
                let taskId = firstTask.id
                print("Main task ID: \(taskId)")
                DispatchQueue.main.async {
                    self.items = tasks
                }
            }
        } catch {
            print("Error fetching tasks: \(error)")
        }
    }

    func fetchAllSubtasks() async {
        do {
            let fetched: [Subtask] = try await SupabaseManager.shared.client.database
                .from("subtasks")
                .select()
                .order("created_at", ascending: true)
                .execute()
                .value
            DispatchQueue.main.async {
                self.subtasks = fetched
            }
        } catch {
            print("Error fetching subtasks: \(error)")
        }
    }

    // Add a new task
    func addItem(title: String) {
        Task {
            guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }
            let newTask = NewTask(user_id: userId, title: title, is_completed: false)
            do {
                print("Inserting main task with user_id: \(userId) (\(type(of: userId))) and title: \(title)")
                _ = try await SupabaseManager.shared.client.database
                    .from("tasks")
                    .insert(newTask)
                    .execute()
                await fetchTasks()
                await fetchAllSubtasks()
            } catch {
                print("Error adding task: \(error)")
            }
        }
    }
    
    // Toggle completion
    func toggleItem(_ item: TodoItem) {
        Task {
            do {
                _ = try await SupabaseManager.shared.client.database
                    .from("tasks")
                    .update(["is_completed": !item.is_completed])
                    .eq("id", value: item.id)
                    .execute()
                await fetchTasks()
                await fetchAllSubtasks()
            } catch {
                print("Error toggling task: \(error)")
            }
        }
    }
    
    // Delete a task
    func deleteItem(_ item: TodoItem) {
        Task {
            do {
                _ = try await SupabaseManager.shared.client.database
                    .from("tasks")
                    .delete()
                    .eq("id", value: item.id)
                    .execute()
                await fetchTasks()
                await fetchAllSubtasks()
            } catch {
                print("Error deleting task: \(error)")
            }
        }
    }
    
    @MainActor
    func addItemAndSubtasks(title: String, subtasks: [String]) async {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
            print("No userId")
            return
        }
        let newTask = NewTask(user_id: userId, title: title, is_completed: false)
        do {
            print("Inserting main task with user_id: \(userId) (\(type(of: userId))) and title: \(title)")
            _ = try await SupabaseManager.shared.client.database
                .from("tasks")
                .insert(newTask)
                .execute()
            await fetchTasks()

            if let firstTask = self.items.first {
                let taskIdString = firstTask.id
                print("Main task ID (from items): \(taskIdString)")
                guard let taskIdUUID = UUID(uuidString: taskIdString) else {
                    print("Failed to convert taskIdString to UUID: \(taskIdString)")
                    return
                }
                // Insert each subtask
                for subtaskTitle in subtasks {
                    let newSubtask = NewSubtask(task_id: taskIdUUID, title: subtaskTitle, is_completed: false)
                    do {
                        print("Inserting subtask with task_id: \(taskIdUUID) (\(type(of: taskIdUUID))) and title: \(subtaskTitle)")
                        // Error here: Subtasks not being inserted into the database
                        let subtaskResponse = try await SupabaseManager.shared.client.database
                            .from("subtasks")
                            .insert(newSubtask)
                            .select()
                            .execute()
                        print("Inserted subtask: \(subtaskTitle), response: \(subtaskResponse.value)")
                    } catch {
                        print("Error inserting subtask: \(subtaskTitle), error: \(error), localized: \(error.localizedDescription)")
                    }
                }
            } else {
                print("No tasks found in items after insert!")
            }
            await fetchAllSubtasks()
        } catch {
            print("Error adding task and subtasks: \(error), localized: \(error.localizedDescription)")
        }
    }
} 
