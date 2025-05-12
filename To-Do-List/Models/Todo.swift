//
//  Todo.swift
//  To-Do-List
//
//  Created by dark type on 11.05.2025.
//

import Foundation

enum TodoStatus: String, Codable, CaseIterable {
    case active = "Active"
    case completed = "Completed"
    case overdue = "Overdue"
    case late = "Late"
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .active: try container.encode(0)
        case .completed: try container.encode(1)
        case .overdue: try container.encode(2)
        case .late: try container.encode(3)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            switch intValue {
            case 0: self = .active
            case 1: self = .completed
            case 2: self = .overdue
            case 3: self = .late
            default: self = .active
            }
        } else if let stringValue = try? container.decode(String.self) {
            switch stringValue.lowercased() {
            case "active": self = .active
            case "completed": self = .completed
            case "overdue": self = .overdue
            case "late": self = .late
            default: self = .active
            }
        } else {
            self = .active
        }
    }
}

enum TodoPriority: String, Codable, CaseIterable {
    case `default` = "Default"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var icon: String {
        switch self {
        case .default: return "arrow.triangle.2.circlepath"
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .critical: return "exclamationmark.circle"
        }
    }
    
    var color: TodoColors.ColorType {
        switch self {
        case .default: return .secondary
        case .low: return .lowPriority
        case .medium: return .mediumPriority
        case .high: return .highPriority
        case .critical: return .criticalPriority
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .default: try container.encode(1)
        case .low: try container.encode(0)
        case .medium: try container.encode(1)
        case .high: try container.encode(2)
        case .critical: try container.encode(3)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            switch intValue {
            case 0: self = .low
            case 1: self = .medium
            case 2: self = .high
            case 3: self = .critical
            default: self = .medium
            }
        } else if let stringValue = try? container.decode(String.self) {
            switch stringValue.lowercased() {
            case "default": self = .default
            case "low": self = .low
            case "medium": self = .medium
            case "high": self = .high
            case "critical": self = .critical
            default: self = .medium
            }
        } else {
            self = .medium
        }
    }
    
    var isDefault: Bool {
        return self == .default
    }
}

struct Todo: Identifiable, Codable, Equatable {
    var id: Int?
    var title: String
    var description: String?
    var deadline: Date?
    var status: TodoStatus = .active
    var priority: TodoPriority = .medium
    let createdAt: Date
    var modifiedAt: Date?
    var isCompleted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case deadline
        case status
        case priority
        case createdAt
        case modifiedAt
        case isCompleted
    }
    
    init(
        id: Int? = 0,
        title: String,
        description: String? = nil,
        deadline: Date? = nil,
        status: TodoStatus = .active,
        priority: TodoPriority = .medium,
        createdAt: Date = Date(),
        modifiedAt: Date? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.deadline = deadline
        self.status = status
        self.priority = priority
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isCompleted = isCompleted
    }
}
