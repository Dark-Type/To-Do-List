//
//  TodoMacroProcessingTests.swift
//  To-Do-List
//
//  Created by dark type on 12.05.2025.
//

import Foundation
import Testing
@testable import To_Do_List

struct TodoMacroProcessingTests {
    // MARK: - Priority Macro Pattern Tests
    
    @Test("Priority macro pattern matching with boundary values")
    func testPriorityMacroPattern() {
        let pattern = /!([1-4])\s?/
        
        let testCases = [
            ("!1", true, "1"),
            ("!2", true, "2"),
            ("!3", true, "3"),
            ("!4", true, "4"),
            ("!1 ", true, "1"),
            ("Text !2 middle", true, "2"),
            ("!3Text", true, "3"),
            
            ("!0", false, ""),
            ("!5", false, ""),
            ("! 1", false, ""),
            ("!a", false, ""),
            ("!", false, "")
        ]
        
        for (input, shouldMatch, expectedGroup) in testCases {
            if let match = input.firstMatch(of: pattern) {
                #expect(shouldMatch, "String '\(input)' should match")
                let group = String(match.output.1)
                #expect(group == expectedGroup, "Expected group \(expectedGroup) but got \(group)")
            } else {
                #expect(!shouldMatch, "String '\(input)' should not match")
            }
        }
    }
    
    // MARK: - Deadline Macro Pattern Tests
    
    @Test("Deadline macro pattern matching with boundary values")
    func testDeadlineMacroPattern() {
        let pattern = /!before\s+(\d{1,2})[.-](\d{1,2})[.-](\d{4})\s?/
        
        let testCases = [
            ("!before 15.05.2025", true, ["15", "05", "2025"]),
            ("!before 15-05-2025", true, ["15", "05", "2025"]),
            ("!before 1.5.2025", true, ["1", "5", "2025"]),
            ("!before 01.05.2025 ", true, ["01", "05", "2025"]),
            ("Text !before 15.05.2025 middle", true, ["15", "05", "2025"]),
            
            ("!before15.05.2025", false, []),
            ("!before 15/05/2025", false, []),
            ("!before 15.05.25", false, []),
            ("!before .05.2025", false, [])
        ]
        
        for (input, shouldMatch, expectedGroups) in testCases {
            if let match = input.firstMatch(of: pattern) {
                #expect(shouldMatch, "String '\(input)' should match")
                
                if expectedGroups.count >= 3 {
                    let day = String(match.output.1)
                    let month = String(match.output.2)
                    let year = String(match.output.3)
                    
                    #expect(day == expectedGroups[0], "Expected day \(expectedGroups[0]) but got \(day)")
                    #expect(month == expectedGroups[1], "Expected month \(expectedGroups[1]) but got \(month)")
                    #expect(year == expectedGroups[2], "Expected year \(expectedGroups[2]) but got \(year)")
                }
            } else {
                #expect(!shouldMatch, "String '\(input)' should not match")
            }
        }
    }
    
    // MARK: - Date Creation Tests
    
    @Test("Date creation with boundary values")
    func testDateCreation() {
        func createDate(day: Int, month: Int, year: Int) -> Date? {
            var components = DateComponents()
            components.day = day
            components.month = month
            components.year = year
            
            return Calendar.current.date(from: components)
        }
        
        let testCases = [
            (1, 1, 2025, true),
            (31, 1, 2025, true),
            (28, 2, 2025, true),
            (29, 2, 2024, true),
            (30, 4, 2025, true),
            (31, 12, 2025, true),
            
            (0, 1, 2025, false),
            (32, 1, 2025, false),
            (29, 2, 2025, false),
            (31, 4, 2025, false),
            (1, 0, 2025, false),
            (1, 13, 2025, false)
        ]
        
        for (day, month, year, shouldBeValid) in testCases {
            let date = createDate(day: day, month: month, year: year)
            
            if shouldBeValid {
                #expect(date != nil, "Date \(day)/\(month)/\(year) should be valid")
                
                if let date = date {
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.day, .month, .year], from: date)
                    
                    #expect(components.day == day, "Day should be \(day) but got \(components.day ?? -1)")
                    #expect(components.month == month, "Month should be \(month) but got \(components.month ?? -1)")
                    #expect(components.year == year, "Year should be \(year) but got \(components.year ?? -1)")
                }
            } else {
                if let date = date {
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.day, .month, .year], from: date)
                    
                    let hasExpectedComponents = components.day == day &&
                        components.month == month &&
                        components.year == year
                    
                    #expect(!hasExpectedComponents, "Invalid date \(day)/\(month)/\(year) should not return the requested components")
                } else {
                    #expect(true, "Invalid date \(day)/\(month)/\(year) returned nil")
                }
            }
        }
    }
}
