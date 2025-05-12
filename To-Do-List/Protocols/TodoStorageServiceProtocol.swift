//
//  TodoStorageServiceProtocol.swift
//  To-Do-List
//
//  Created by dark type on 11.05.2025.
//

import Foundation

protocol TodoStorageServiceProtocol : Sendable {
    func saveTodos(_ todos: [Todo]) throws
    func loadTodos() throws -> [Todo]
    func deleteSavedTodos() throws
    func exportTodos(_ todos: [Todo], to url: URL) throws
}
