//
//  TodoListViewModelTests.swift
//  To-Do-List
//
//  Created by dark type on 12.05.2025.
//

import Combine
import Foundation
import Testing
@testable import To_Do_List

@MainActor
struct TodoListViewModelTests {
    // MARK: - Sorting Tests
    
    @Test("Todo sorting - equivalent partitions for each sort option")
    func testTodoSorting() async throws {
        let mockAPI = MockTodoAPIService()
        let mockStorage = MockTodoStorageService()
        let sut = TodoListViewModel(apiService: mockAPI, storageService: mockStorage)
        
        let now = Date()
        let todos = [
            Todo(id: 1, title: "C Task", deadline: now.addingTimeInterval(86400 * 5), status: .active, priority: .low, createdAt: now.addingTimeInterval(-86400 * 3)),
                 
            Todo(id: 2, title: "A Task", deadline: now.addingTimeInterval(86400), status: .active, priority: .critical, createdAt: now.addingTimeInterval(-86400)),
                 
            Todo(id: 3, title: "B Task", deadline: now.addingTimeInterval(86400 * 3), status: .active, priority: .high, createdAt: now.addingTimeInterval(-86400 * 2)),
                 
            Todo(id: 4, title: "D Task", deadline: now.addingTimeInterval(86400 * 2), status: .completed, priority: .medium, createdAt: now)
        ]
        
        mockAPI.mockedTodos = todos
        
        sut.sortOption = .deadline
        await sut.loadTodos()
        sut.sortTodos()
        
        #expect(sut.todos.count == 4)
        
        #expect(sut.todos[0].id == 2)
        #expect(sut.todos[1].id == 3)
        #expect(sut.todos[2].id == 1)
        #expect(sut.todos[3].id == 4)
        
        sut.sortOption = .priority
        sut.sortTodos()
        
        #expect(sut.todos[0].id == 2)
        #expect(sut.todos[1].id == 3)
        #expect(sut.todos[2].id == 1)
        #expect(sut.todos[3].id == 4)
        
        sut.sortOption = .title
        sut.sortTodos()
        
        #expect(sut.todos[0].id == 2)
        #expect(sut.todos[1].id == 3)
        #expect(sut.todos[2].id == 1)
        #expect(sut.todos[3].id == 4)
        
        sut.sortOption = .creationDate
        sut.sortTodos()
        
        #expect(sut.todos[0].id == 1)
        #expect(sut.todos[1].id == 3)
        #expect(sut.todos[2].id == 2)
        #expect(sut.todos[3].id == 4)
    }
    
    // MARK: - Status Update Tests
    
    @Test("Todo status update - boundary value analysis for deadline")
    func testStatusUpdate() async throws {
        let mockAPI = MockTodoAPIService()
        let mockStorage = MockTodoStorageService()
        let sut = TodoListViewModel(apiService: mockAPI, storageService: mockStorage)
        
        let now = Date()
        
        let todos = [
            Todo(id: 1, title: "Past deadline", deadline: now.addingTimeInterval(-86400), status: .active),
            Todo(id: 2, title: "Current deadline", deadline: now, status: .active),
            Todo(id: 3, title: "Future deadline", deadline: now.addingTimeInterval(86400), status: .active),
            Todo(id: 4, title: "No deadline", status: .active),
            Todo(id: 5, title: "Completed with past deadline", deadline: now.addingTimeInterval(-86400), status: .completed, isCompleted: true)
        ]
        
        mockAPI.mockedTodos = todos
        
        await sut.loadTodos()
        sut.updateTodoStatuses()
        
        #expect(sut.todos[0].status == .overdue)
        #expect(sut.todos[1].status == .overdue)
        #expect(sut.todos[2].status == .active)
        #expect(sut.todos[3].status == .active)
        #expect(sut.todos[4].status == .completed)
    }
    
    // MARK: - CRUD Tests
    
    @Test("Todo CRUD operations")
    func testCRUDOperations() async throws {
        let mockAPI = MockTodoAPIService()
        let mockStorage = MockTodoStorageService()
        let sut = TodoListViewModel(apiService: mockAPI, storageService: mockStorage)
        
        mockAPI.mockedTodos = []
        await sut.loadTodos()
        #expect(sut.todos.isEmpty)
        
        let newTodo = Todo(id: nil, title: "New Todo")
        mockAPI.nextMockedTodo = Todo(id: 1, title: "New Todo", createdAt: Date())
        await sut.addTodo(newTodo)
        
        #expect(sut.todos.count == 1)
        #expect(sut.todos[0].id == 1)
        #expect(sut.todos[0].title == "New Todo")
        
        var updatedTodo = sut.todos[0]
        updatedTodo.title = "Updated Todo"
        await sut.updateTodo(updatedTodo)
        
        #expect(sut.todos[0].title == "Updated Todo")
        
        await sut.deleteTodo(updatedTodo)
        #expect(sut.todos.isEmpty)
        
        mockAPI.mockedTodos = [Todo(id: 1, title: "Todo", status: .active, isCompleted: false)]
        await sut.loadTodos()
        
        let todoToToggle = sut.todos[0]
        #expect(!sut.isCompleted(todoToToggle))
        
        await sut.toggleCompletion(for: todoToToggle)
        
        try await Task.sleep(nanoseconds: 100000000)
        
        #expect(mockAPI.markCompletedCalled, "toggleCompletion should have called markAsCompleted")
    }

    // MARK: - Error Handling Tests
    
    @Test("Error handling with API failures")
    func testErrorHandling() async throws {
        let mockAPI = MockTodoAPIService()
        let mockStorage = MockTodoStorageService()
        mockAPI.shouldFailWithError = true
        
        let fallbackTodos = [Todo(id: 99, title: "Fallback Todo")]
        mockStorage.savedTodos = fallbackTodos
        
        let sut = TodoListViewModel(apiService: mockAPI, storageService: mockStorage)

        await sut.loadTodos()
        
        #expect(sut.error != nil)
        #expect(sut.todos.count == 1)
        #expect(sut.todos[0].id == 99)
    }
    
    @Test("Formatted deadline tests")
    func testFormattedDeadline() async throws {
        let mockAPI = MockTodoAPIService()
        let mockStorage = MockTodoStorageService()
        let sut = TodoListViewModel(apiService: mockAPI, storageService: mockStorage)
        
        let now = Date()
        let calendar = Calendar.current
        
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        var tomorrowComponents = todayComponents
        tomorrowComponents.day! += 1
        var futureComponents = todayComponents
        futureComponents.day! += 5
        
        let today = calendar.date(from: todayComponents)!
        let tomorrow = calendar.date(from: tomorrowComponents)!
        let future = calendar.date(from: futureComponents)!
        
        let todos = [
            Todo(id: 1, title: "Today", deadline: today),
            Todo(id: 2, title: "Tomorrow", deadline: tomorrow),
            Todo(id: 3, title: "Future", deadline: future),
            Todo(id: 4, title: "No deadline")
        ]
   
        #expect(sut.formattedDeadline(for: todos[0]) == "Today")
        #expect(sut.formattedDeadline(for: todos[1]) == "Tomorrow")
        #expect(sut.formattedDeadline(for: todos[2])?.isEmpty == false)
        #expect(sut.formattedDeadline(for: todos[2]) != "Today")
        #expect(sut.formattedDeadline(for: todos[2]) != "Tomorrow")
        #expect(sut.formattedDeadline(for: todos[3]) == nil)
    }
}

// MARK: - Mock Classes

final class MockTodoAPIService: TodoAPIServiceProtocol {
    var mockedTodos: [Todo] = []
    var nextMockedTodo: Todo?
    var shouldFailWithError = false
    
    var markCompletedCalled = false
    var markIncompleteCalled = false
    
    func fetchTodos() async throws -> [Todo] {
        if shouldFailWithError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock API Error"])
        }
        return mockedTodos
    }
    
    func fetchSortedTodos(by option: TodoListViewModel.SortOption) async throws -> [Todo] {
        if shouldFailWithError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock API Error"])
        }
        return mockedTodos
    }
    
    func fetchTodo(id: Int) async throws -> Todo {
        if shouldFailWithError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock API Error"])
        }
        return mockedTodos.first { $0.id == id } ?? Todo(id: id, title: "Not Found")
    }
    
    func createTodo(_ todo: Todo) async throws -> Todo {
        if shouldFailWithError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock API Error"])
        }
        return nextMockedTodo ?? todo
    }
    
    func updateTodo(_ todo: Todo) async throws {
        if shouldFailWithError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock API Error"])
        }
        
        if let index = mockedTodos.firstIndex(where: { $0.id == todo.id }) {
            mockedTodos[index] = todo
        }
    }
    
    func deleteTodo(id: Int) async throws {
        if shouldFailWithError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock API Error"])
        }
        
        mockedTodos.removeAll { $0.id == id }
    }
    
    func markAsCompleted(id: Int) async throws {
        if shouldFailWithError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock API Error"])
        }
        
        markCompletedCalled = true
        if let index = mockedTodos.firstIndex(where: { $0.id == id }) {
            mockedTodos[index].status = .completed
            mockedTodos[index].isCompleted = true
        }
    }
    
    func markAsIncomplete(id: Int) async throws {
        if shouldFailWithError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock API Error"])
        }
        
        markIncompleteCalled = true
        if let index = mockedTodos.firstIndex(where: { $0.id == id }) {
            mockedTodos[index].status = .active
            mockedTodos[index].isCompleted = false
        }
    }
    
    func uploadTodoList(_ todos: [Todo]) async throws {
        if shouldFailWithError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock API Error"])
        }
        
        mockedTodos = todos
    }
}

final class MockTodoStorageService: TodoStorageServiceProtocol {
    func deleteSavedTodos() throws {}
    
    func exportTodos(_ todos: [To_Do_List.Todo], to url: URL) throws {}
    
    var savedTodos: [Todo] = []
    var shouldFailWithError = false
    
    func saveTodos(_ todos: [Todo]) throws {
        if shouldFailWithError {
            throw NSError(domain: "MockError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock Storage Error"])
        }
        
        savedTodos = todos
    }
    
    func loadTodos() throws -> [Todo] {
        if shouldFailWithError {
            throw NSError(domain: "MockError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock Storage Error"])
        }
        
        return savedTodos
    }
}
