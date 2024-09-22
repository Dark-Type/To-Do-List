//
//  TaskData.swift
//  To-Do-List
//
//  Created by dark type on 13.09.2024.
//

import Foundation

struct TaskData: Identifiable, Codable, Equatable {
    let id = UUID()
    var taskName: String
    var isDone: Bool
    enum CodingKeys: String, CodingKey {
        case taskName = "string"
        case isDone = "boolean"
    }

    init(taskName: String, isDone: Bool) {
        self.taskName = taskName
        self.isDone = isDone
    }
}
