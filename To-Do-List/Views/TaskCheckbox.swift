//
//  ItemCheckbox.swift
//  To-Do-List
//
//  Created by dark type on 11.09.2024.
//

import SwiftUI

struct TaskCheckbox: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()

        }, label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                    .foregroundStyle(configuration.isOn ? .green : .blue)
                configuration.label
            }
        })
    }
}
