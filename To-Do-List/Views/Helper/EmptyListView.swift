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

            Label("empty_list_message".localized(), systemImage: "tray")
                .imageScale(.large)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding()
            Text("add_tasks_message".localized()).font(.callout)
            Spacer()
        }
    }
}

#Preview {
    EmptyListView().environment(\.locale, .init(identifier: "en"))
}
