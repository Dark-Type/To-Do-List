//
//  TodoDetailView.swift
//  To-Do-List
//
//  Created by dark type on 11.05.2025.
//

import SwiftUI

struct TodoDetailView: View {
    @Environment(\.presentationMode) var presentationMode
 
    let todoId: Int?
    @ObservedObject var viewModel: TodoListViewModel
    @State private var isEditing = false
    @State private var editableTodo: Todo
    @State private var shouldDismissAfterUpdate = false
    
    private var todo: Todo {
        if let id = todoId {
            return viewModel.todos.first { $0.id == id } ?? editableTodo
        } else {
            return editableTodo
        }
    }
    
    init(todo: Todo, viewModel: TodoListViewModel) {
        self.todoId = todo.id
        self.viewModel = viewModel
        self._editableTodo = State(initialValue: todo)
    }
    
    var body: some View {
        mainContent
            .navigationTitle("Task Details")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        isEditing = true
                    }
                    .accessibilityIdentifier("EditButton")
                }
            })
            .sheet(isPresented: $isEditing, onDismiss: {
                if shouldDismissAfterUpdate {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    shouldDismissAfterUpdate = false
                }
            }) {
                editSheet
            }
            .onChange(of: viewModel.todos) { _ in
                updateEditableTodoIfNeeded()
            }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                todoHeaderSection
                
                Divider()
                
                todoPrioritySection
                
                descriptionSectionIfNeeded
                
                todoDeadlineSection
                
                todoMetadataSection
                
                Spacer()
                
                todoActionButtons
            }
            .padding()
        }
    }
    
    private var descriptionSectionIfNeeded: some View {
        Group {
            if let description = todo.description, !description.isEmpty {
                todoDescriptionSection(description)
            }
        }
    }
    
    private var editSheet: some View {
        TodoEditView(
            todo: $editableTodo,
            isNewTodo: todoId == nil,
            onSave: { updatedTodo in
                Task {
                    if let id = updatedTodo.id {
                        await viewModel.updateTodo(updatedTodo)
                           
                        if let refreshed = viewModel.todos.first(where: { $0.id == id }) {
                            editableTodo = refreshed
                        }
                           
                        shouldDismissAfterUpdate = true
                        isEditing = false
                    } else {
                        await viewModel.addTodo(updatedTodo)
                        isEditing = false
                    }
                }
            }
        )
        .presentationDetents([.large])
    }
    
    private func updateEditableTodoIfNeeded() {
        if !isEditing, let id = todoId, let updatedTodo = viewModel.todos.first(where: { $0.id == id }) {
            editableTodo = updatedTodo
        }
    }
    
    private var todoHeaderSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(todo.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .strikethrough(viewModel.isCompleted(todo))
                
                HStack {
                    Text(todo.status.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    
                    if let deadline = todo.deadline {
                        Text(viewModel.formattedDeadline(for: todo) ?? "")
                            .font(.caption)
                            .foregroundColor(deadlineColor)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.toggleCompletion(for: todo)
                }
            }) {
                Circle()
                    .fill(viewModel.isCompleted(todo) ? Color.green : Color.clear)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(viewModel.isCompleted(todo) ? Color.green : Color.gray, lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .opacity(viewModel.isCompleted(todo) ? 1.0 : 0.0)
                    )
            }
        }
    }
    
    private var todoPrioritySection: some View {
        HStack {
            Label {
                Text("Priority: \(todo.priority.rawValue)")
            } icon: {
                Image(systemName: todo.priority.icon)
                    .foregroundColor(TodoColors.color(todo.priority.color))
            }
        }
    }
    
    private func todoDescriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
            
            Text(description)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var todoDeadlineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Deadline")
                .font(.headline)
            
            if let deadline = todo.deadline {
                HStack {
                    Image(systemName: "calendar")
                    Text(formattedDate(deadline))
                }
                .foregroundColor(deadlineColor)
            } else {
                Text("No deadline set")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var todoMetadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Created on: \(formattedDate(todo.createdAt))")
                .font(.caption)
                .foregroundColor(.gray)
            
            if let updatedAt = $editableTodo.wrappedValue.modifiedAt {
                Text("Last updated: \(formattedDate(updatedAt))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var todoActionButtons: some View {
        HStack {
            Button(action: {
                Task {
                    if let id = todo.id {
                        await viewModel.deleteTodo(todo)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }) {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            
            if !isEditing {
                Button(action: {
                    isEditing = true
                }) {
                    Label("Edit", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var statusColor: Color {
        switch todo.status {
        case .active: return TodoColors.color(.mediumPriority)
        case .completed: return TodoColors.color(.completed)
        case .overdue: return TodoColors.color(.overdue)
        case .late: return TodoColors.color(.deadline)
        }
    }
    
    private var deadlineColor: Color {
        guard let deadline = todo.deadline, !viewModel.isCompleted(todo) else {
            return TodoColors.secondaryLabel
        }
        
        let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        
        if daysUntilDeadline < 0 {
            return TodoColors.color(.overdue)
        } else if daysUntilDeadline < 3 {
            return TodoColors.color(.deadline)
        } else {
            return TodoColors.secondaryLabel
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
