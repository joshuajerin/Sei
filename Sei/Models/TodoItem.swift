import Foundation

struct TodoItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date? // Optional due date
    
    init(title: String, isCompleted: Bool = false, dueDate: Date? = nil) {
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.dueDate = dueDate
    }
} 