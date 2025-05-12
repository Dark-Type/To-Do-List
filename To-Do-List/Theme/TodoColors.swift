//
//  TodoColors.swift
//  To-Do-List
//
//  Created by dark type on 11.05.2025.
//

import SwiftUI

struct TodoColors {
    enum ColorType {
        case primary
        case secondary
        case background
        case lowPriority
        case mediumPriority
        case highPriority
        case criticalPriority
        case deadline
        case overdue
        case completed
        case label
        case secondaryLabel
    }
    
    static func color(_ type: ColorType) -> Color {
        switch type {
        case .primary:
            return Color.blue
        case .secondary:
            return Color.gray
        case .background:
            return Color(.systemBackground)
        case .lowPriority:
            return Color.green
        case .mediumPriority:
            return Color.blue
        case .highPriority:
            return Color.orange
        case .criticalPriority:
            return Color.red
        case .deadline:
            return Color.orange
        case .overdue:
            return Color.red
        case .completed:
            return Color.green
        case .label:
            return Color(.label)
        case .secondaryLabel:
            return Color(.secondaryLabel)
        }
    }
    
    static var label: Color { color(.label) }
    static var secondaryLabel: Color { color(.secondaryLabel) }
}
