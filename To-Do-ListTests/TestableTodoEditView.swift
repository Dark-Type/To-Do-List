//
//  TestableTodoEditView.swift
//  To-Do-List
//
//  Created by dark type on 12.05.2025.
//

//
//  TodoMacroTests.swift
//  To-Do-ListTests
//
//  Created by Dark-Type on 12.05.2025.
//

import SwiftUI
import Testing
@testable import To_Do_List

@MainActor
struct TodoEditViewTests {
    // MARK: - Title Validation Tests
    
    @Test("Title validation - Boundary Value Analysis")
    func testTitleValidation() async throws {
        let testCases = [
            ("", false, "Title must be at least 4 characters long."),
            ("ABC", false, "Title must be at least 4 characters long."),
            ("ABCD", true, ""),
            ("Regular Title", true, ""),
            (String(repeating: "A", count: 100), true, "")
        ]
        
        for (title, shouldPass, expectedError) in testCases {
            var todo = Todo(id: 1, title: "Test")
            var saveWasCalled = false
            var savedTodo: Todo?
            let sut = TodoEditViewHelper(
                todo: todo,
                isNewTodo: true,
                title: title,
                onSave: { newTodo in
                    saveWasCalled = true
                    savedTodo = newTodo
                }
            )
            
            sut.saveChanges()
            
            #expect(sut.showValidationError != shouldPass)
            if !shouldPass {
                #expect(sut.validationError == expectedError)
                #expect(!saveWasCalled)
            } else {
                #expect(saveWasCalled)
                #expect(savedTodo != nil)
                #expect(savedTodo?.title == title)
            }
        }
    }
    
    // MARK: - Priority Tests
    
    @Test("Priority handling with user changes")
    func testPriorityHandling() async throws {
        var todo = Todo(id: 1, title: "Test Todo")
        let sut1 = TodoEditViewHelper(todo: todo, isNewTodo: true)
        
        #expect(sut1.priority == .default)
        #expect(!sut1.priorityChangedByUser)
        
        let sut2 = TodoEditViewHelper(todo: todo, isNewTodo: true)
        sut2.priority = .high
        sut2.priorityChanged()
        
        #expect(sut2.priority == .high)
        #expect(sut2.priorityChangedByUser)
        
        sut2.priority = .default
        sut2.priorityChanged()
        
        #expect(sut2.priority == .default)
        #expect(!sut2.priorityChangedByUser)
    }
    
    // MARK: - Deadline Tests
    
    @Test("Deadline handling")
    func testDeadlineHandling() async throws {
        var todo = Todo(id: 1, title: "Test", deadline: nil)
        let sut = TodoEditViewHelper(todo: todo, isNewTodo: true)
        
        #expect(!sut.hasDeadline)
        #expect(!sut.deadlineChangedByUser)

        sut.hasDeadline = true
        sut.deadlineToggled()
        
        #expect(sut.hasDeadline)
        #expect(sut.deadlineChangedByUser)

        sut.hasDeadline = false
        sut.deadlineToggled()
        
        #expect(!sut.hasDeadline)
        #expect(!sut.deadlineChangedByUser)
    }
    
    // MARK: - Macro Processing Tests
    
    @Test("Priority macro processing")
    func testPriorityMacroProcessing() async throws {
        let testCases = [
            ("Task !1", false, "Task", TodoPriority.critical),
            ("Task !2", false, "Task", TodoPriority.high),
            ("Task !3", false, "Task", TodoPriority.medium),
            ("Task !4", false, "Task", TodoPriority.low),
            ("Task !1 with space", false, "Task with space", TodoPriority.critical),
            ("!1 At Beginning", false, "At Beginning", TodoPriority.critical),
            ("At End !2", false, "At End", TodoPriority.high),
            
            ("Task !1", true, "Task", TodoPriority.medium)
        ]
        
        for (inputTitle, userChangedPriority, expectedTitle, expectedPriority) in testCases {
            let todo = Todo(id: 1, title: "Original", priority: .medium)
            let sut = TodoEditViewHelper(
                todo: todo,
                isNewTodo: false,
                title: inputTitle,
                priority: .medium
            )
            
            sut.priorityChangedByUser = userChangedPriority
            sut.processMacros()
            
            #expect(sut.title == expectedTitle, "Title should be processed correctly")
            if !userChangedPriority {
                #expect(sut.priority == expectedPriority, "Priority should be set correctly when not user-changed")
            } else {
                #expect(sut.priority == .medium, "Priority should remain unchanged when user-changed")
            }
        }
    }
    
    @Test("Deadline macro processing")
    func testDeadlineMacroProcessing() async throws {
        let testCases = [
            ("Task !before 15.05.2025", false, "Task", true),
            ("Task !before 15-05-2025", false, "Task", true),
            ("Task !before 1.5.2025 short format", false, "Task short format", true),
            ("!before 15.05.2025 At Beginning", false, "At Beginning", true),
            ("At End !before 15.05.2025", false, "At End", true),
            
            ("Task !before 15.05.2025", true, "Task", true)
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let (inputTitle, userChangedDeadline, expectedTitle, expectedHasDeadline) = testCase
            
            print("\n--- Testing case #\(index): \(inputTitle) ---")
            let todo = Todo(id: 1, title: "Original")
            let sut = TodoEditViewHelper(
                todo: todo,
                isNewTodo: false,
                title: inputTitle
            )
            
            sut.deadlineChangedByUser = userChangedDeadline
            let originalDeadline = sut.deadline
            print("Before processMacros - hasDeadline: \(sut.hasDeadline)")
            
            sut.processMacros()
            
            print("After processMacros - title: \(sut.title)")
            print("After processMacros - hasDeadline: \(sut.hasDeadline)")
            
            #expect(sut.title == expectedTitle, "Title should be processed correctly")
          
            if !userChangedDeadline, expectedHasDeadline {
                #expect(sut.deadline != originalDeadline,
                        "Deadline should be updated when not user-changed")
                print("Deadline updated from \(originalDeadline) to \(sut.deadline)")
            } else if userChangedDeadline {
                #expect(sut.deadline == originalDeadline,
                        "Deadline should remain unchanged when user-changed")
            }
        }
    }

    @Test("Combined macro processing")
    func testCombinedMacroProcessing() async throws {
        let title = "Important task !1 !before 20.05.2025"
        let todo = Todo(id: 1, title: "Original", priority: .medium)
        let sut = TodoEditViewHelper(todo: todo, isNewTodo: false, title: title)
        
        sut.processMacros()
        
        #expect(sut.title == "Important task")
        #expect(sut.priority == .critical)
        #expect(sut.hasDeadline)
    }
}

// MARK: - Test Helper

@MainActor
class TodoEditViewHelper {
    var todo: Todo
    let isNewTodo: Bool
    let onSave: (Todo) -> Void
    var title: String
    var description: String
    var priority: TodoPriority
    var hasDeadline: Bool
    var deadline: Date
    
    var priorityChangedByUser = false
    var deadlineChangedByUser = false
    
    var showValidationError = false
    var validationError = ""
    
    init(todo: Todo,
         isNewTodo: Bool,
         title: String? = nil,
         description: String? = nil,
         priority: TodoPriority? = nil,
         onSave: @escaping (Todo) -> Void = { _ in })
    {
        self.todo = todo
        self.isNewTodo = isNewTodo
        self.onSave = onSave
        self.title = title ?? todo.title
        self.description = description ?? todo.description ?? ""
        
        if isNewTodo {
            self.priority = priority ?? .default
        } else {
            self.priority = priority ?? todo.priority
        }
        
        self.hasDeadline = todo.deadline != nil
        self.deadline = todo.deadline ?? Date().addingTimeInterval(86400)
        self.deadlineChangedByUser = !isNewTodo && todo.deadline != nil
    }
    
    func saveChanges() {
        if title.count < 4 {
            showValidationError = true
            validationError = "Title must be at least 4 characters long."
            return
        }
        
        processMacros()
        
        todo.title = title
        todo.description = description.isEmpty ? nil : description
        
        todo.priority = priority == .default ? .medium : priority
        
        todo.deadline = hasDeadline ? deadline : nil
        todo.modifiedAt = Date()
        
        onSave(todo)
    }
    
    func priorityChanged() {
        priorityChangedByUser = true
        
        if priority == .default {
            priorityChangedByUser = false
        }
    }
    
    func deadlineToggled() {
        deadlineChangedByUser = true
        
        if !hasDeadline {
            deadlineChangedByUser = false
        }
    }
    
    func deadlineChanged() {
        deadlineChangedByUser = true
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
                    newDeadline = date
                    hasDeadline = true
                }
            }
            
            newTitle = newTitle.replacing(match.output.0, with: "")
        }
        
        title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        priority = newPriority
        deadline = newDeadline ?? deadline
    }
    
    private func createDate(day: Int, month: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        
        return Calendar.current.date(from: components)
    }
}
