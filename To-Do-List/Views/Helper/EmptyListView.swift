//
//  EmptyListView.swift
//  To-Do-List
//
//  Created by dark type on 22.09.2024.
//

import SwiftUI

struct EmptyListView: View {
    var body: some View {
        VStack {
            Spacer()
            Label("Your list is empty", systemImage: "tray")
                .imageScale(.large)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding()
            Text("Go add some tasks!").font(.callout)
            Spacer()
        }
    }
}
#Preview {
    EmptyListView()
}
