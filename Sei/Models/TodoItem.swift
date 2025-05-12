import Foundation

struct TodoItem: Identifiable, Codable {
    let id: String
    let user_id: String
    var title: String
    var is_completed: Bool
    let created_at: Date
} 