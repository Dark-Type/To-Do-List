//
//  TodoListView.swift
//  To-Do-List
//
//  Created by dark type on 11.05.2025.
//

import SwiftUI

struct TodoListView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @State private var showingAddTodo = false
    @State private var newTodo = Todo(id: 0, title: "")
    @State private var showingSortOptions = false

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.todos.isEmpty {
                    EmptyStateView(action: { showingAddTodo = true })
                } else {
                    TodosListContent(viewModel: viewModel)
                }
            }
            .navigationTitle("Todo List")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(TodoListViewModel.SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                Task {
                                    await viewModel.changeSortOption(option)
                                }
                            }) {
                                Label(option.rawValue, systemImage: option.icon)
                                if viewModel.sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        newTodo = viewModel.createNewTodo()
                        showingAddTodo = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadTodos()
            }
            .refreshable {
                await viewModel.loadTodos()
            }
            .sheet(isPresented: $showingAddTodo) {
                TodoEditView(
                    todo: $newTodo,
                    isNewTodo: true,
                    onSave: { todoToAdd in
                        guard !todoToAdd.title.isEmpty, todoToAdd.title.count >= 4 else { return }
                        Task {
                            await viewModel.addTodo(todoToAdd)
                            showingAddTodo = false
                        }
                    }
                )
                .presentationDetents([.large])
            }
            .alert(item: Binding<TodoError?>(
                get: { viewModel.error != nil ? TodoError(message: viewModel.error?.localizedDescription ?? "Unknown error") : nil },
                set: { _ in viewModel.error = nil }
            )) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct TodoError: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - Supporting Views

struct TodosListContent: View {
    @ObservedObject var viewModel: TodoListViewModel

    var body: some View {
        List {
            ForEach(viewModel.todos) { todo in
                TodoRowView(todo: todo, viewModel: viewModel)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let todo = viewModel.todos[index]
                    Task {
                        await viewModel.deleteTodo(todo)
                    }
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 85))
                .foregroundColor(TodoColors.color(.secondary))

            Text("No Tasks Yet")
                .font(.title)
                .fontWeight(.semibold)

            Text("Start by adding your first task")
                .foregroundColor(TodoColors.secondaryLabel)

            Button(action: action) {
                Label("Add Task", systemImage: "plus")
                    .padding()
                    .background(TodoColors.color(.primary))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading...")
                .foregroundColor(TodoColors.secondaryLabel)
                .padding(.top)
        }
    }
}

#Preview {
    TodoListView(viewModel: TodoListViewModel(
        apiService: TodoAPIService(),
        storageService: TodoStorageService()
    ))
}
