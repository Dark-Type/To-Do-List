//
//  TodoRowView.swift
//  To-Do-List
//
//  Created by dark type on 11.05.2025.
//

import SwiftUI

struct TodoRowView: View {
    @ObservedObject var viewModel: TodoListViewModel
    let todoId: Int
    private var todo: Todo {
        viewModel.todos.first { $0.id == todoId } ?? Todo(id: todoId, title: "")
    }
       
    init(todo: Todo, viewModel: TodoListViewModel) {
        self.todoId = todo.id ?? 0
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationLink(destination: TodoDetailView(todo: todo, viewModel: viewModel)) {
            HStack {
                priorityIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(todo.title)
                        .font(.headline)
                        .strikethrough(viewModel.isCompleted(todo))
                        .foregroundColor(rowColor)
                    Text("\(todo.id ?? 0)")
                        .accessibilityIdentifier("TaskId_\(todo.title)")
                        .font(.caption2)
                        .foregroundColor(.clear)
                        .padding(.zero)
                    
                    if todo.deadline != nil {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(viewModel.formattedDeadline(for: todo) ?? "No deadline")
                                .font(.caption)
                        }
                        .foregroundColor(deadlineColor)
                    }
                    
                    if viewModel.shouldShowStatus(todo) {
                        Text(todo.status.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                completionToggle
            }
            .contentShape(Rectangle())
        }
    }
    
    private var priorityIcon: some View {
        Image(systemName: todo.priority.icon)
            .foregroundColor(TodoColors.color(todo.priority.color))
            .font(.title3)
            .frame(width: 30)
    }
    
    private var completionToggle: some View {
        Button(action: {
            Task {
                await viewModel.toggleCompletion(for: todo)
            }
        }) {
            Image(systemName: viewModel.isCompleted(todo) ? "checkmark.circle.fill" : "circle")
                .foregroundColor(viewModel.isCompleted(todo) ? .green : .gray)
                .font(.title3)
        }
        .buttonStyle(BorderlessButtonStyle())
        .accessibilityIdentifier("CompletionToggle_\(todo.id ?? 0)")
    }
    
    private var rowColor: Color {
        if viewModel.isCompleted(todo) {
            return TodoColors.secondaryLabel
        }
        return TodoColors.label
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
    
    private var statusColor: Color {
        switch todo.status {
        case .active: return TodoColors.color(.mediumPriority)
        case .completed: return TodoColors.color(.completed)
        case .overdue: return TodoColors.color(.overdue)
        case .late: return TodoColors.color(.deadline)
        }
    }
}
