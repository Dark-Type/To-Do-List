//
//  BottomBarView.swift
//  To-Do-List
//
//  Created by dark type on 22.09.2024.
//

import SwiftUI

struct BottomBar: View {
    @Binding var importing: Bool
    @Binding var items: [TaskData]
    var viewModel: ContentViewModel

    var body: some View {
        HStack {
            ImportButton(importing: $importing, items: $items)
            Spacer()
            Button(action: {
                viewModel.addNewItem()
            }) {
                Label("", systemImage: "plus.rectangle.on.rectangle")
                    .padding()
                    .cornerRadius(10)
            }
        }
        .padding(.leading, 15)
        .padding(.trailing, 15)
    }
}
