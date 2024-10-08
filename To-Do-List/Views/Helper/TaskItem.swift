//
//  ListItem.swift
//  To-Do-List
//
//  Created by dark type on 11.09.2024.
//

import SwiftUI

struct TaskItem: View {
    @Binding var task: TaskData
    private var isTaskDone: Bool {
        task.isDone
    }

    var body: some View {
        HStack {
            TextField("task_placeholder".localized(), text: $task.taskName)
            Spacer()
            Toggle(isOn: $task.isDone) {
                Text(isTaskDone ? "done_state".localized() : "")
                    .foregroundStyle(isTaskDone ? .green : .blue)
            }.toggleStyle(TaskCheckbox())
        }
        .padding(.leading, 15)
        .padding(.trailing, 15)
    }
}
