//
//  ExportButton.swift
//  To-Do-List
//
//  Created by dark type on 21.09.2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportButton: View {
    @Binding var exporting: Bool
    var items: [TaskData]
    @State private var document: ExportDocument?

    var body: some View {
        Button(action: {
            Task {
                document = await DataManager.shared.exportJsonFile(tasks: items)
                exporting = true
            }
        }) {
            Image(systemName: "square.and.arrow.up.on.square")
        }
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "tasks.json") { result in
            switch result {
            case .success(let url):
                print("exported successfully to \(url)")
            case .failure(let error):
                print("did not export due to: \(error.localizedDescription)")
            }
        }
    }
}
