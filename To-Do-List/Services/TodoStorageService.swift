//
//  TodoFileStorageService.swift
//  To-Do-List
//
//  Created by dark type on 11.05.2025.
//

import Foundation

final class TodoStorageService: TodoStorageServiceProtocol {
    private let fileURL: URL
    
    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documentsDirectory.appendingPathComponent("todos.json")
    }
    
    func saveTodos(_ todos: [Todo]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(todos)
        try data.write(to: fileURL)
    }
    
    func loadTodos() throws -> [Todo] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Todo].self, from: data)
    }
    
    func deleteSavedTodos() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    func exportTodos(_ todos: [Todo], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(todos)
        try data.write(to: url)
    }
}
