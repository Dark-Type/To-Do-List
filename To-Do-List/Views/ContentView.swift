//
//  ContentView.swift
//  To-Do-List
//
//  Created by dark type on 11.09.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.items.isEmpty {
                    EmptyListView()
                } else {
                    TaskListView(items: $viewModel.items, viewModel: viewModel)
                        .navigationTitle("name")
                        .navigationBarItems(trailing: ExportButton(exporting: $viewModel.exporting, items: viewModel.items))
                }
                BottomBar(importing: $viewModel.importing, items: $viewModel.items, viewModel: viewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
