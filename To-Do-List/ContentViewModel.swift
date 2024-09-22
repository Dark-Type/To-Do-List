//
//  ContentViewModel.swift
//  To-Do-List
//
//  Created by dark type on 21.09.2024.
//

import SwiftUI

@MainActor
class ContentViewModel: ObservableObject {
    @Published var items: [TaskData] = []
    @Published var exporting = false
    @Published var importing = false

    private var dataManager = DataManager.shared

    init() {
        Task {
            let loadedTasks = await dataManager.loadJsonFile()
            items = loadedTasks
            await dataManager.saveToJsonFile(tasks: items)
        }
        // print(items)
    }

    func deleteItem(at index: Int) {
        Task {
            items.remove(at: index)
            await dataManager.saveToJsonFile(tasks: items)
        }
        // print("delete")
        // print(items)
    }

    func addNewItem() {
        Task {
            let newItem = TaskData(taskName: "", isDone: false)
            items.append(newItem)
            await dataManager.saveToJsonFile(tasks: items)
        }
        // print(items)
    }

    func saveItems() {
        Task {
            await dataManager.saveToJsonFile(tasks: items)
        }
        // print(items)
    }
}
