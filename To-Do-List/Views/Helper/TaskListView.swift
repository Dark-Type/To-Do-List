//
//  TaskListView.swift
//  To-Do-List
//
//  Created by dark type on 22.09.2024.
//

import SwiftUI

struct TaskListView: View {
    @Binding var items: [TaskData]
    var viewModel: ContentViewModel

    var body: some View {
        List($items) { $item in
            TaskItem(task: $item)
                .onChange(of: item) { oldItem, newItem in
                    viewModel.saveItems()
                }
                .swipeActions {
                    Button(action: {
                        if let index = items.firstIndex(of: item) {
                            viewModel.deleteItem(at: index)
                        }
                    }) {
                        Image(systemName: "trash.fill")
                    }.tint(.red)
                }
        }
        .listRowSeparator(.hidden)
    }
}
