//
//  ListItem.swift
//  To-Do-List
//
//  Created by dark type on 11.09.2024.
//

import SwiftUI

struct Task: View {
    @Binding var task: TaskData
    private var istTaskDone: Bool {
        task.isDone
    }

    var body: some View {
        HStack {
            TextField("Task", text: $task.taskName)
            Spacer()
            Toggle(isOn: $task.isDone) {
                Text(istTaskDone ? "Done" : "")
                    .foregroundStyle(istTaskDone ? .green : .blue)
            }.toggleStyle(TaskCheckbox())

        }.padding(.leading, 15)
            .padding(.trailing, 15)
    }
}
