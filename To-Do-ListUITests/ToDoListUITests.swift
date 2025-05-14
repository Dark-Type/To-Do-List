//
//  ToDoListUITests.swift
//  To-Do-List
//
//  Created by dark type on 13.05.2025.
//

import XCTest

final class ToDoListUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    // MARK: - Main E2E

    func testEndToEndScenario() throws {
        try testCreationAndUpdatesOfRegularText()
        try testTaskCreationWithPriorityMacro()
        try testTaskCreationWithDeadlineMacro()
        try testTaskCreationWithBothMacros()
        try testTaskWithBothMacrosButExplicitPriorityAndDeadline()
        try testSortTasksByTitle()
        testDeleteAllTestTasks()
    }

    // MARK: - Partial tests
    
    func testCreationAndUpdatesOfRegularText() throws {
        openAddTaskScreen()
        enterTaskTitle("abc")
        saveTask()
        XCTAssertTrue(app.alerts["Validation Error"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.alerts.staticTexts["Title must be at least 4 characters long."].exists)
        app.alerts.buttons["OK"].tap()

        enterTaskTitle("abcd")
        saveTask()
        XCTAssertTrue(app.staticTexts["abcd"].waitForExistence(timeout: 2))
        backToListIfNeeded()
        XCTAssertTrue(app.staticTexts["abcd"].exists)

        app.staticTexts["abcd"].tap()
        XCTAssertTrue(app.navigationBars["Task Details"].exists)
        let editButton = app.buttons["EditButton"]
        XCTAssertTrue(editButton.exists, "Edit button does not exist")
        editButton.tap()
        let newTitle = "AllChanged"
        let newDesc = "Edited description"
        let newPriority = "High"
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        enterTaskTitle(newTitle)
        enterTaskDescription(newDesc)
        pickPriority(newPriority)
        setDeadline(true)
        pickDeadlineDate(tomorrow)
        saveTask()
        XCTAssertTrue(app.staticTexts["Tomorrow"].waitForExistence(timeout: 2))

        app.staticTexts["AllChanged"].tap()
        let editButton2 = app.buttons["EditButton"]
        XCTAssertTrue(editButton2.exists, "Edit button does not exist")
        editButton2.tap()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        setDeadline(true)
        pickDeadlineDate(yesterday)
        saveTask()
        XCTAssertTrue(app.staticTexts["Overdue"].waitForExistence(timeout: 2))

        markTaskAsCompleted(title: "AllChanged")
        XCTAssertTrue(app.staticTexts["Late"].waitForExistence(timeout: 2))

        markTaskAsCompleted(title: "AllChanged")
        XCTAssertTrue(app.staticTexts["Overdue"].waitForExistence(timeout: 2))

        markTaskAsCompleted(title: "AllChanged")
        app.staticTexts["AllChanged"].tap()
        let editButton3 = app.buttons["EditButton"]
        XCTAssertTrue(editButton3.exists, "Edit button does not exist")
        editButton3.tap()
        setDeadline(true)
        let endOfTheMonth = Calendar.current.date(byAdding: .day, value: 12, to: Date())!
        pickDeadlineDate(endOfTheMonth)
        saveTask()
        XCTAssertTrue(app.staticTexts["Completed"].waitForExistence(timeout: 2))
    }

    func testTaskCreationWithPriorityMacro() throws {
        createTaskWithTitle("Priority macro !1")
        openTaskWithTitle("Priority macro")
        XCTAssertTrue(app.staticTexts["Priority: Critical"].exists)
        backToListIfNeeded()
    }

    func testTaskCreationWithDeadlineMacro() throws {
        createTaskWithTitle("Deadline macro !before 25.12.2025")
        openTaskWithTitle("Deadline macro")
        XCTAssertTrue(app.staticTexts["25 Dec 2025"].exists)
        backToListIfNeeded()
    }

    func testTaskCreationWithBothMacros() throws {
        createTaskWithTitle("Both macros !1 !before 01.01.2026")
        openTaskWithTitle("Both macros")
        XCTAssertTrue(app.staticTexts["Priority: Critical"].exists)
        XCTAssertTrue(app.staticTexts["1 Jan 2026"].exists)
        backToListIfNeeded()
    }

    func testTaskWithBothMacrosButExplicitPriorityAndDeadline() throws {
        openAddTaskScreen()
        enterTaskTitle("Explicit both !1 !before 02.02.2026")
        pickPriority("Low")
        setDeadline(true)
        let endOfTheMonth = Calendar.current.date(byAdding: .day, value: 12, to: Date())!
        pickDeadlineDate(endOfTheMonth)
        saveTask()
        openTaskWithTitle("Explicit both")
        XCTAssertTrue(app.staticTexts["Priority: Low"].exists)
        XCTAssertTrue(app.staticTexts["26 May 2025"].exists)
        backToListIfNeeded()
    }

    func testSortTasksByTitle() throws {
        openSortMenu()
        selectSortOption("Title")
        XCTAssertTrue(tasksAreSortedByTitle())
    }

    func testDeleteAllTestTasks() {
        deleteTaskWithTitle("AllChanged")
        XCTAssertFalse(app.staticTexts["AllChanged"].exists)
        deleteTaskWithTitle("Explicit both")
        deleteTaskWithTitle("Both macros")
        deleteTaskWithTitle("Deadline macro")
        deleteTaskWithTitle("Priority macro")
    }

    // MARK: - Helpers

    func dateFromDMY(_ dmy: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.date(from: dmy)!
    }

    func openAddTaskScreen() {
        if app.buttons["Add Task"].exists {
            app.buttons["Add Task"].tap()
        } else if app.navigationBars.buttons["plus"].exists {
            app.navigationBars.buttons["plus"].tap()
        }
    }

    func enterTaskTitle(_ title: String) {
        let field = app.textFields["Title"]
        field.tap()
        field.clearAndEnterText(text: title)
    }

    func enterTaskDescription(_ desc: String) {
        let field = app.textViews["DescriptionTextEditor"]
        field.tap()
        field.clearAndEnterText(text: desc)
    }

    func pickPriority(_ priority: String) {
        let possibleLabels = ["Priority", "Medium", "High", "Low", "Critical"]
        var found = false
        for label in possibleLabels {
            let button = app.buttons[label]
            if button.exists && button.isHittable {
                button.tap()
                found = true
                break
            }
        }
        XCTAssertTrue(found, "Priority picker button not found or not hittable")

        let optionButton = app.buttons["Low"]
        XCTAssertTrue(optionButton.waitForExistence(timeout: 2), "Priority option not found")
        optionButton.tap()
    }

    func setDeadline(_ on: Bool) {
        let toggle = app.switches["Set Deadline"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))

        let datePicker = app.datePickers["Deadline"]
        let isDatePickerVisible = datePicker.exists && datePicker.isHittable

        if on && !isDatePickerVisible {
            toggle.tap()
            XCTAssertTrue(datePicker.waitForExistence(timeout: 2))
        } else if !on && isDatePickerVisible {
            toggle.tap()
            let start = Date()
            while datePicker.exists && Date().timeIntervalSince(start) < 2 {
                usleep(100_000)
            }
            XCTAssertFalse(datePicker.exists)
        }
    }

    func pickDeadlineDate(_ date: Date) {
        let picker = app.datePickers["Deadline"]
        XCTAssertTrue(picker.waitForExistence(timeout: 2), "Deadline date picker not found")
        picker.tap()
        print(app.buttons.allElementsBoundByIndex.map { $0.label })

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "en_US")
        monthFormatter.dateFormat = "LLLL yyyy"
        let monthLabel = monthFormatter.string(from: date)

        let monthButton = app.buttons[monthLabel]
        if monthButton.exists {
            monthButton.tap()
        }

        let enFormatter = DateFormatter()
        enFormatter.locale = Locale(identifier: "en_US")
        enFormatter.dateFormat = "EEEE, d MMMM"
        let enLabel = enFormatter.string(from: date)

        let ruFormatter = DateFormatter()
        ruFormatter.locale = Locale(identifier: "ru_RU")
        ruFormatter.dateFormat = "EEEE, d MMMM"
        let ruLabel = ruFormatter.string(from: date)

        let possibleLabels = [enLabel, ruLabel]

        let dayButton = app.buttons.allElementsBoundByIndex.first { button in
            possibleLabels.contains(button.label)
        }
        XCTAssertNotNil(dayButton, "No button with expected calendar day label found. Checked: \(possibleLabels)")

        if dayButton!.isSelected {
            let dismissButton = app.buttons["dismiss popup"]
            XCTAssertTrue(dismissButton.waitForExistence(timeout: 2), "Dismiss popup button not found")
            dismissButton.tap()
            return
        }
        dayButton!.tap()
        let dismissButton = app.buttons["dismiss popup"]
        XCTAssertTrue(dismissButton.waitForExistence(timeout: 2), "Dismiss popup button not found")
        dismissButton.tap()
    }

    func selectMonth(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        let targetMonth = formatter.string(from: date)

        while !app.staticTexts[targetMonth].exists {
            let nextButton = app.buttons["Next Month"]
            XCTAssertTrue(nextButton.waitForExistence(timeout: 2), "Next Month button not found")
            nextButton.tap()
        }
    }

    func saveTask() {
        app.buttons["Save"].tap()
    }

    func backToListIfNeeded() {
        if app.navigationBars.buttons["Todo List"].exists {
            app.navigationBars.buttons["Todo List"].tap()
        } else if app.buttons["Back"].exists {
            app.buttons["Back"].tap()
        }
    }

    func markTaskAsCompleted(title: String) {
        guard let todoId = getTaskId(forTitle: title) else {
            XCTFail("Could not find id for task with title \(title)")
            return
        }
        let toggle = app.buttons["CompletionToggle_\(todoId)"]
        XCTAssertTrue(toggle.exists, "Toggle for todo \(todoId) does not exist")
        toggle.tap()
    }

    func createTaskWithTitle(_ title: String) {
        openAddTaskScreen()
        enterTaskTitle(title)
        saveTask()
    }

    func openTaskWithTitle(_ title: String) {
        let taskText = app.staticTexts[title]
        XCTAssertTrue(taskText.waitForExistence(timeout: 2), "Task with title '\(title)' not found")
        taskText.tap()
    }

    func openSortMenu() {
        app.navigationBars.buttons["Sort"].tap()
    }

    func selectSortOption(_ option: String) {
        let optionButton = app.buttons[option]
        XCTAssertTrue(optionButton.waitForExistence(timeout: 2), "Sort option '\(option)' not found")
        optionButton.tap()
    }

    func tasksAreSortedByTitle() -> Bool {
        let titles = app.tables.cells.staticTexts.allElementsBoundByIndex.map { $0.label }
        return titles == titles.sorted()
    }

    func deleteTaskWithTitle(_ title: String) {
        let cell = app.staticTexts[title]
        if cell.exists {
            cell.swipeLeft()
            app.buttons["Delete"].tap()
        }
    }

    func formattedDateForPicker(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }

    func pickerDayString(from date: Date) -> String {
        let calendar = Calendar.current
        return String(calendar.component(.day, from: date))
    }

    func uiDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }

    func getTaskId(forTitle title: String) -> Int? {
        let idElement = app.staticTexts["TaskId_\(title)"]
        guard idElement.exists else { return nil }
        return Int(idElement.label)
    }
}

// MARK: - XCUIElement extension for text field clearing

extension XCUIElement {
    func clearAndEnterText(text: String) {
        tap()
        guard let stringValue = value as? String else {
            typeText(text)
            return
        }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
        typeText(text)
    }
}

extension XCUIElement {
    func scrollToElement() {
        while !isHittable {
            XCUIApplication().swipeUp()
        }
    }
}
