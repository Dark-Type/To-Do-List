//
//  TodoAPIServiceProtocol.swift
//  To-Do-List
//
//  Created by dark type on 11.05.2025.
//

protocol TodoAPIServiceProtocol: Sendable {
    func fetchTodos() async throws -> [Todo]
    func createTodo(_ todo: Todo) async throws -> Todo
    func updateTodo(_ todo: Todo) async throws
    func deleteTodo(id: Int) async throws
    func fetchSortedTodos(by option: TodoListViewModel.SortOption) async throws -> [Todo]
    func markAsCompleted(id: Int) async throws
    func markAsIncomplete(id: Int) async throws
    func uploadTodoList(_ todos: [Todo]) async throws
}
