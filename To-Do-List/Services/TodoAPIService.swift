//
//  TodoAPIPlaceholder.swift
//  To-Do-List
//
//  Created by dark type on 11.05.2025.
//
import Foundation

enum TodoAPIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
}

final class TodoAPIService: TodoAPIServiceProtocol {
    private let baseURLString: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(baseURLString: String = "http://localhost:5223/api/Todo",
         session: URLSession = .shared)
    {
        self.baseURLString = baseURLString
        self.session = session
           
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
           
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
               
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd"
            ].map { format -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.calendar = Calendar(identifier: .iso8601)
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }
               
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
               
            print("⚠️ Failed to parse date: \(dateString)")
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
           
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
           
        encoder.keyEncodingStrategy = .useDefaultKeys
    }
       
    func fetchTodos() async throws -> [Todo] {
        let url = URL(string: baseURLString)!
        
        do {
            let (data, _) = try await session.data(from: url)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            return try decoder.decode([Todo].self, from: data)
        } catch {
            print("Error: \(error)")
            throw error
        }
    }
    
    func fetchSortedTodos(by option: TodoListViewModel.SortOption) async throws -> [Todo] {
        let url = URL(string: "\(baseURLString)/sort/\(option.apiValue)")!
        return try await performRequest(url: url)
    }
    
    func fetchTodo(id: Int) async throws -> Todo {
        let url = URL(string: "\(baseURLString)/\(id)")!
        return try await performRequest(url: url)
    }
    
    func createTodo(_ todo: Todo) async throws -> Todo {
        let url = URL(string: baseURLString)!
           
        
        var newTodo = todo
           
 
        if newTodo.title.count < 4 {
            throw TodoAPIError.invalidData("Title must be at least 4 characters")
        }
        
    
        var todoDict: [String: Any] = [
            "title": newTodo.title,
            "description": newTodo.description ?? "",
            "status": 0,
            "priority": getIntValue(for: newTodo.priority),
            "isCompleted": false,
            "createdAt": formatDateForAPI(Date())
        ]
        
        
        if let deadline = newTodo.deadline {
            todoDict["deadline"] = formatDateForAPI(deadline)
        }
        
        
        todoDict["modifiedAt"] = newTodo.modifiedAt != nil ? formatDateForAPI(newTodo.modifiedAt!) : NSNull()
           
        do {
            
            let jsonData = try JSONSerialization.data(withJSONObject: todoDict)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Create Todo - JSON being sent: \(jsonString)")
            }
               
            let responseData = try await performPostRequest(url: url, jsonData: jsonData)
            return try decoder.decode(Todo.self, from: responseData)
        } catch {
            print("Failed to add todo: \(error)")
            throw error
        }
    }
    private func getIntValue(for priority: TodoPriority) -> Int {
        switch priority {
        case .low: return 0
        case .medium, .`default`: return 1
        case .high: return 2
        case .critical: return 3
        }
    }


    func updateTodo(_ todo: Todo) async throws {
        guard let id = todo.id else {
            throw TodoAPIError.invalidData("Cannot update todo without ID")
        }
           
        let url = URL(string: "\(baseURLString)/\(id)")!
           
        
        if todo.title.count < 4 {
            throw TodoAPIError.invalidData("Title must be at least 4 characters")
        }
           
        
        do {
            let jsonData = try encoder.encode(todo)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Update Todo - JSON being sent: \(jsonString)")
            }
               
            try await performPutRequest(url: url, body: todo)
        } catch {
            print("Failed to update todo: \(error)")
            throw error
        }
    }

    private func performRawPostRequest(url: URL, jsonData: Data) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TodoAPIError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("Server error response: \(errorResponse)")
                }
                throw TodoAPIError.httpError(httpResponse.statusCode)
            }
            
            return data
        } catch let error as TodoAPIError {
            throw error
        } catch {
            throw TodoAPIError.networkError(error)
        }
    }

    private func performRawPutRequest(url: URL, jsonData: Data) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TodoAPIError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("Server error response: \(errorResponse)")
                }
                throw TodoAPIError.httpError(httpResponse.statusCode)
            }
        } catch let error as TodoAPIError {
            throw error
        } catch {
            throw TodoAPIError.networkError(error)
        }
    }
    
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    
    func deleteTodo(id: Int) async throws {
        let url = URL(string: "\(baseURLString)/\(id)")!
        try await performDeleteRequest(url: url)
    }
    
    func markAsCompleted(id: Int) async throws {
        let url = URL(string: "\(baseURLString)/complete/\(id)")!
        try await performPutRequestWithoutBody(url: url)
    }
    
    func markAsIncomplete(id: Int) async throws {
        let url = URL(string: "\(baseURLString)/incomplete/\(id)")!
        try await performPutRequestWithoutBody(url: url)
    }
    
    func uploadTodoList(_ todos: [Todo]) async throws {
        let url = URL(string: "\(baseURLString)/upload")!
        do {
            let jsonData = try encoder.encode(todos)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Uploading Todo List - JSON being sent: \(jsonString)")
            }
            try await performPostRequest(url: url, jsonData: jsonData)
        } catch {
            print("Error uploading todos: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TodoAPIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("Server error response: \(errorResponse)")
                }
                throw TodoAPIError.httpError(httpResponse.statusCode)
            }
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Failed to decode JSON: \(jsonString)")
                }
                throw TodoAPIError.decodingError(error)
            }
        } catch let error as TodoAPIError {
            throw error
        } catch {
            throw TodoAPIError.networkError(error)
        }
    }
    
    private func performPostRequest(url: URL, jsonData: Data) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TodoAPIError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("Server error response: \(errorResponse)")
                }
                throw TodoAPIError.httpError(httpResponse.statusCode)
            }
            
            return data
        } catch let error as TodoAPIError {
            throw error
        } catch {
            throw TodoAPIError.networkError(error)
        }
    }
    
    private func performPutRequest<T: Encodable>(url: URL, body: T) async throws {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           
        do {
            let jsonData = try encoder.encode(body)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Updating Todo - JSON being sent: \(jsonString)")
            }
            request.httpBody = jsonData
        } catch {
            print("Encoding error: \(error)")
            throw TodoAPIError.encodingError(error)
        }
           
        do {
            let (data, response) = try await session.data(for: request)
               
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TodoAPIError.invalidResponse
            }
               
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("Server error response: \(errorResponse)")
                }
                throw TodoAPIError.httpError(httpResponse.statusCode)
            }
        } catch let error as TodoAPIError {
            throw error
        } catch {
            throw TodoAPIError.networkError(error)
        }
    }
       
    private func performPutRequestWithoutBody(url: URL) async throws {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = "PUT"
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TodoAPIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("Server error response: \(errorResponse)")
                }
                throw TodoAPIError.httpError(httpResponse.statusCode)
            }
        } catch let error as TodoAPIError {
            throw error
        } catch {
            throw TodoAPIError.networkError(error)
        }
    }
    
    private func performDeleteRequest(url: URL) async throws {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = "DELETE"
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TodoAPIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("Server error response: \(errorResponse)")
                }
                throw TodoAPIError.httpError(httpResponse.statusCode)
            }
        } catch let error as TodoAPIError {
            throw error
        } catch {
            throw TodoAPIError.networkError(error)
        }
    }
}

private struct EmptyResponse: Decodable {}

extension TodoAPIError {
    static func invalidData(_ message: String) -> TodoAPIError {
        fatalError("Implement this error case in your TodoAPIError type")
    }
}
