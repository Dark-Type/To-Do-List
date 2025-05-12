//
//  To_Do_ListApp.swift
//  To-Do-List
//
//  Created by dark type on 11.09.2024.
//

import SwiftUI

@main
struct TodoApp: App {
    let apiService: TodoAPIServiceProtocol
    let storageService: TodoStorageServiceProtocol
    
    let todoListViewModel: TodoListViewModel
    
    init() {
        self.apiService = TodoAPIService()
        self.storageService = TodoStorageService()
        
        self.todoListViewModel = TodoListViewModel(
            apiService: apiService,
            storageService: storageService
        )
    }
    
    var body: some Scene {
        WindowGroup {
            TodoListView(viewModel: todoListViewModel)
        }
    }
}
