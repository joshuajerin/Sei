import Foundation
import SwiftUI

class TodoViewModel: ObservableObject {
    @Published var items: [TodoItem] = []
    
    func addItem(title: String) {
        let newItem = TodoItem(title: title)
        items.append(newItem)
    }
    
    func toggleItem(_ item: TodoItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted.toggle()
        }
    }
    
    func deleteItem(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
    }
} 