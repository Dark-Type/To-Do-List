//
//  TodoEditView.swift
//  To-Do-List
//
//  Created by dark type on 11.05.2025.
//

import SwiftUI

struct TodoEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var todo: Todo
    let isNewTodo: Bool
    let onSave: (Todo) -> Void
    @State private var title: String
    @State private var description: String
    @State private var priority: TodoPriority
    @State private var hasDeadline: Bool
    @State private var deadline: Date
       
    @State private var priorityChangedByUser = false
    @State private var deadlineChangedByUser = false
    
    @State private var showValidationError = false
    @State private var validationError = ""
    
    init(todo: Binding<Todo>, isNewTodo: Bool, onSave: @escaping (Todo) -> Void) {
        self._todo = todo
        self.isNewTodo = isNewTodo
        self.onSave = onSave
        _title = State(initialValue: todo.wrappedValue.title)
        _description = State(initialValue: todo.wrappedValue.description ?? "")
        if isNewTodo {
            _priority = State(initialValue: .default)
        } else {
            _priority = State(initialValue: todo.wrappedValue.priority)
        }
        _hasDeadline = State(initialValue: todo.wrappedValue.deadline != nil)
        _deadline = State(initialValue: todo.wrappedValue.deadline ?? Date().addingTimeInterval(86400))
        _priorityChangedByUser = State(initialValue: false)
        _deadlineChangedByUser = State(initialValue: !isNewTodo && todo.wrappedValue.deadline != nil)
    }
    
    var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    var body: some View {
        NavigationView {
            Group {
                if isUITesting {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Task Details")
                                .font(.headline)
                            TextField("Title", text: $title)
                                .textFieldStyle(.roundedBorder)
                            
                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("Description (Optional)")
                                        .foregroundColor(Color(.placeholderText))
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                                TextEditor(text: $description)
                                    .frame(minHeight: 100)
                                    .accessibilityIdentifier("DescriptionTextEditor")
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                            }
                            
                            Divider()
                            
                            Text("Priority")
                                .font(.headline)
                            Picker(selection: $priority, label:
                                Label("Priority", systemImage: "flag")
                                    .accessibilityIdentifier("PriorityPickerButton"))
                            {
                                ForEach(TodoPriority.allCases, id: \.self) { priority in
                                    Label {
                                        Text(priority.rawValue)
                                    } icon: {
                                        Image(systemName: priority.icon)
                                            .foregroundColor(TodoColors.color(priority.color))
                                    }
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: priority) { _ in
                                priorityChangedByUser = true
                                if priority == .default {
                                    priorityChangedByUser = false
                                }
                            }
                            if priority == .default {
                                Text("Priority will be determined by title macros or set to Medium")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            Text("Deadline")
                                .font(.headline)
                            Toggle("Set Deadline", isOn: $hasDeadline)
                                .accessibilityIdentifier("Set Deadline")
                                .onChange(of: hasDeadline) { newValue in
                                    deadlineChangedByUser = true
                                    if !newValue {
                                        deadlineChangedByUser = false
                                    }
                                }
                            if hasDeadline {
                                DatePicker("Deadline", selection: $deadline, displayedComponents: [.date])
                                    .accessibilityIdentifier("Deadline")
                                    .onChange(of: deadline) { _ in
                                        deadlineChangedByUser = true
                                    }
                            }
                            
                            Divider()
                            
                            Text("Pro Tips")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Automatic Priority:")
                                    .font(.headline)
                                Text("Add !1, !2, !3, or !4 to the title to set priority.")
                                Text("Example: \"Submit report !1\" → Critical priority")
                                    .font(.caption)
                                    .italic()
                                Divider()
                                Text("Automatic Deadline:")
                                    .font(.headline)
                                Text("Add !before DD.MM.YYYY to the title to set a deadline.")
                                Text("Example: \"Call client !before 15.05.2025\"")
                                    .font(.caption)
                                    .italic()
                            }
                            .padding(.vertical, 8)
                            Spacer(minLength: 32)
                        }
                        .padding()
                    }
                } else {
                    Form {
                        Section(header: Text("Task Details")) {
                            TextField("Title", text: $title)
                            
                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("Description (Optional)")
                                        .foregroundColor(Color(.placeholderText))
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                                TextEditor(text: $description)
                                    .frame(minHeight: 100)
                                    .accessibilityIdentifier("DescriptionTextEditor")
                            }
                        }
                        
                        Section(header: Text("Priority")) {
                            Picker(selection: $priority, label:
                                Label("Priority", systemImage: "flag")
                                    .accessibilityIdentifier("PriorityPickerButton"))
                            {
                                ForEach(TodoPriority.allCases, id: \.self) { priority in
                                    Label {
                                        Text(priority.rawValue)
                                    } icon: {
                                        Image(systemName: priority.icon)
                                            .foregroundColor(TodoColors.color(priority.color))
                                    }
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: priority) { _ in
                                priorityChangedByUser = true
                                if priority == .default {
                                    priorityChangedByUser = false
                                }
                            }
                            if priority == .default {
                                Text("Priority will be determined by title macros or set to Medium")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Section(header: Text("Deadline")) {
                            Toggle("Set Deadline", isOn: $hasDeadline)
                                .accessibilityIdentifier("Set Deadline")
                                .onChange(of: hasDeadline) { newValue in
                                    deadlineChangedByUser = true
                                    if !newValue {
                                        deadlineChangedByUser = false
                                    }
                                }
                            if hasDeadline {
                                DatePicker("Deadline", selection: $deadline, displayedComponents: [.date])
                                    .accessibilityIdentifier("Deadline")
                                    .onChange(of: deadline) { _ in
                                        deadlineChangedByUser = true
                                    }
                            }
                        }
                        
                        Section(header: Text("Pro Tips")) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Automatic Priority:")
                                    .font(.headline)
                                Text("Add !1, !2, !3, or !4 to the title to set priority.")
                                Text("Example: \"Submit report !1\" → Critical priority")
                                    .font(.caption)
                                    .italic()
                                Divider()
                                Text("Automatic Deadline:")
                                    .font(.headline)
                                Text("Add !before DD.MM.YYYY to the title to set a deadline.")
                                Text("Example: \"Call client !before 15.05.2025\"")
                                    .font(.caption)
                                    .italic()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle(isNewTodo ? "New Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            .alert(isPresented: $showValidationError) {
                Alert(
                    title: Text("Validation Error"),
                    message: Text(validationError),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func saveChanges() {
        if title.count < 4 {
            showValidationError = true
            validationError = "Title must be at least 4 characters long."
            return
        }
             
        processMacros()
             
        todo.title = title
        todo.description = description.isEmpty ? nil : description
             
        todo.priority = priority == .default ? .medium : priority
             
        todo.deadline = hasDeadline ? deadline.asUTCMidnight() : nil
        todo.modifiedAt = Date()
             
        onSave(todo)
        presentationMode.wrappedValue.dismiss()
    }
      
    func processMacros() {
        var newTitle = title
        var newPriority = priority
        var newDeadline = hasDeadline ? deadline : nil

        let priorityPattern = /!([1-4])\s?/
        if let match = newTitle.firstMatch(of: priorityPattern) {
            if !priorityChangedByUser {
                let priorityNumber = String(match.output.1)
                        
                switch priorityNumber {
                case "1": newPriority = .critical
                case "2": newPriority = .high
                case "3": newPriority = .medium
                case "4": newPriority = .low
                default: break
                }
            }
                    
            newTitle = newTitle.replacing(match.output.0, with: "")
        }
                
        let deadlinePattern = /!before\s+(\d{1,2})[.-](\d{1,2})[.-](\d{4})\s?/
        if let match = newTitle.firstMatch(of: deadlinePattern) {
            if !deadlineChangedByUser {
                if let day = Int(String(match.output.1)),
                   let month = Int(String(match.output.2)),
                   let year = Int(String(match.output.3)),
                   let date = createDate(day: day, month: month, year: year)
                {
                    newDeadline = date.asUTCMidnight()
                    hasDeadline = true
                }
            }
                    
            newTitle = newTitle.replacing(match.output.0, with: "")
        }
                
        title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        priority = newPriority
        
        if newDeadline != nil {
            deadline = newDeadline!
        }
        
        // Debug output to diagnose issues
        print("Title after processing: \(title)")
        print("HasDeadline after processing: \(hasDeadline)")
        if hasDeadline {
            print("Deadline after processing: \(deadline)")
        }
    }
    
    private func createDate(day: Int, month: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(secondsFromGMT: 0)

        return Calendar(identifier: .gregorian).date(from: components)
    }

    func normalizedToUTCMidnight(_ date: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.nanosecond = 0
        components.timeZone = TimeZone(secondsFromGMT: 0)
        return calendar.date(from: components)!
    }
}

extension Date {
    /// Returns a Date at midnight UTC for the same calendar day in the user's local time zone
    func asUTCMidnight() -> Date {
        let calendar = Calendar(identifier: .gregorian)
        var localComponents = calendar.dateComponents(in: TimeZone.current, from: self)
        localComponents.hour = 0
        localComponents.minute = 0
        localComponents.second = 0
        localComponents.nanosecond = 0
        localComponents.timeZone = TimeZone(secondsFromGMT: 0)
        return Calendar(identifier: .gregorian).date(from: localComponents)!
    }
}
