//
//  TodoListViewModel.swift
//  To-Do-List
//
//  Created by dark type on 11.05.2025.
//

import Combine
import SwiftUI

@MainActor
class TodoListViewModel: ObservableObject {
    @Published var todos: [Todo] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var sortOption: SortOption = .deadline
    private var currentTasks: [Int: Task<Void, Never>] = [:]
    
    enum SortOption: String, CaseIterable {
        case deadline = "Deadline"
        case priority = "Priority"
        case title = "Title"
        case creationDate = "Creation Date"
           
        var apiValue: String {
            switch self {
            case .deadline: return "deadline"
            case .priority: return "priority"
            case .title: return "title"
            case .creationDate: return "created"
            }
        }
           
        var icon: String {
            switch self {
            case .deadline: return "calendar"
            case .priority: return "exclamationmark.triangle"
            case .title: return "textformat"
            case .creationDate: return "clock"
            }
        }
    }
    
    private nonisolated let apiService: TodoAPIServiceProtocol
    private nonisolated let storageService: TodoStorageServiceProtocol
    
    // MARK: - Initialization
    
    init(apiService: TodoAPIServiceProtocol, storageService: TodoStorageServiceProtocol) {
        self.apiService = apiService
        self.storageService = storageService
    }
    
    // MARK: - Data Operations
    
    func loadTodos() async {
        isLoading = true
        defer { isLoading = false }
            
        do {
            todos = try await apiService.fetchTodos()
            updateTodoStatuses()
            sortTodos()
                    
            try storageService.saveTodos(todos)
            error = nil
                    
        } catch {
            self.error = error
                
            do {
                todos = try storageService.loadTodos()
                updateTodoStatuses()
                sortTodos()
            } catch {
                print("Failed to load from local storage: \(error)")
            }
        }
    }
    
    func addTodo(_ todo: Todo) async {
        do {
            let newTodo = try await apiService.createTodo(todo)
            todos.append(newTodo)
            updateTodoStatuses()
            sortTodos()
            try storageService.saveTodos(todos)
        } catch {
            self.error = error
            print("Failed to add todo: \(error)")
        }
    }
    
    func updateTodo(_ todo: Todo) async {
        guard let id = todo.id, let index = todos.firstIndex(where: { $0.id == id }) else {
            print("Cannot update todo: Missing ID or todo not found")
            return
        }
            
        do {
            try await apiService.updateTodo(todo)
            todos[index] = todo
            updateTodoStatuses()
            sortTodos()
            try storageService.saveTodos(todos)
        } catch {
            self.error = error
            print("Failed to update todo: \(error)")
        }
    }
    
    func deleteTodo(_ todo: Todo) async {
        guard let id = todo.id, let index = todos.firstIndex(where: { $0.id == id }) else {
            print("Cannot delete todo: Missing ID or todo not found")
            return
        }
           
        do {
            try await apiService.deleteTodo(id: id)
            todos.remove(at: index)
            try storageService.saveTodos(todos)
        } catch {
            self.error = error
            print("Failed to delete todo: \(error)")
        }
    }

    func deleteTodo(id: Int) async {
        guard let index = todos.firstIndex(where: { $0.id == id }) else {
            print("Cannot delete todo: Todo not found with ID \(id)")
            return
        }
           
        do {
            try await apiService.deleteTodo(id: id)
            todos.remove(at: index)
            try storageService.saveTodos(todos)
        } catch {
            self.error = error
            print("Failed to delete todo: \(error)")
        }
    }
    
    func changeSortOption(_ option: SortOption) async {
        sortOption = option
        
        isLoading = true
        defer { isLoading = false }
        
        do {
   
            todos = try await apiService.fetchSortedTodos(by: option)
            updateTodoStatuses()
            error = nil
            
 
            try storageService.saveTodos(todos)
        } catch {
            self.error = error
            print("Failed to fetch sorted todos: \(error)")
            
            sortTodos()
        }
    }
    
    // MARK: - Helper Methods
    
    func updateTodoStatuses() {
        let now = Date()
        
        for i in 0 ..< todos.count {
            var todo = todos[i]
            
            if todo.status == .active, let deadline = todo.deadline {
                if deadline < now {
                    todo.status = .overdue
                    todo.modifiedAt = now
                    todos[i] = todo
                }
            }
        }
    }
    
    func sortTodos() {
        switch sortOption {
        case .deadline:
            todos.sort { a, b -> Bool in
             
                if isCompleted(a) && !isCompleted(b) { return false }
                if !isCompleted(a) && isCompleted(b) { return true }
                
                if let aDeadline = a.deadline, let bDeadline = b.deadline {
                    return aDeadline < bDeadline
                }
      
                if a.deadline != nil && b.deadline == nil { return true }
                if a.deadline == nil && b.deadline != nil { return false }
                
                return a.createdAt < b.createdAt
            }
            
        case .priority:
            todos.sort { a, b -> Bool in
             
                if isCompleted(a) && !isCompleted(b) { return false }
                if !isCompleted(a) && isCompleted(b) { return true }
                
                let priorityOrder: [TodoPriority] = [.critical, .high, .medium, .low]
                if let aIndex = priorityOrder.firstIndex(of: a.priority),
                   let bIndex = priorityOrder.firstIndex(of: b.priority)
                {
                    return aIndex < bIndex
                }
                
                return a.createdAt < b.createdAt
            }
            
        case .title:
            todos.sort { a, b -> Bool in
       
                if isCompleted(a) && !isCompleted(b) { return false }
                if !isCompleted(a) && isCompleted(b) { return true }
                
                return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            }
            
        case .creationDate:
            todos.sort { a, b -> Bool in
   
                if isCompleted(a) && !isCompleted(b) { return false }
                if !isCompleted(a) && isCompleted(b) { return true }
                
                return a.createdAt < b.createdAt
            }
        }
    }
    
    func formattedDeadline(for todo: Todo) -> String? {
        guard let deadline = todo.deadline else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        if Calendar.current.isDateInToday(deadline) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(deadline) {
            return "Tomorrow"
        }
        
        return formatter.string(from: deadline)
    }
    
    func isCompleted(_ todo: Todo) -> Bool {
        return todo.status == .completed || todo.status == .late
    }
    
    func shouldShowStatus(_ todo: Todo) -> Bool {
        return todo.status != .active
    }
    
    func createNewTodo() -> Todo {
        Todo(id: nil, title: "", createdAt: Date())
    }
    
    private func getNextTodoId() -> Int {
        let highestId = todos.compactMap { $0.id }.max() ?? 0
        return highestId + 1
    }

    func toggleCompletion(for todo: Todo) async {
        guard let id = todo.id else {
            print("Cannot toggle completion: Todo has no ID")
            return
        }
           
        currentTasks[id]?.cancel()
           
        guard todos.firstIndex(where: { $0.id == id }) != nil else { return }
           
        var updatedTodo = todo
        let willMarkCompleted = !isCompleted(todo)
        updatedTodo.status = willMarkCompleted ? .completed : .active
        updatedTodo.isCompleted = willMarkCompleted
        updatedTodo.modifiedAt = Date()
           
        currentTasks[id] = Task {
            do {
                if willMarkCompleted {
                    try await apiService.markAsCompleted(id: id)
                } else {
                    try await apiService.markAsIncomplete(id: id)
                }
                   
                let updatedTodos = try await apiService.fetchTodos()
                await MainActor.run {
                    self.todos = updatedTodos
                    self.updateTodoStatuses()
                    self.sortTodos()
                    self.objectWillChange.send()
                    try? self.storageService.saveTodos(self.todos)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.objectWillChange.send()
                }
            }
               
            await MainActor.run {
                self.currentTasks.removeValue(forKey: id)
            }
        }
    }
}
