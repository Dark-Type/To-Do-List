//
//  ImportButton.swift
//  To-Do-List
//
//  Created by dark type on 21.09.2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportButton: View {
    @Binding var importing: Bool
    @Binding var items: [TaskData]

    var body: some View {
        Button(action: { importing = true }) {
            Image(systemName: "square.and.arrow.down")
                .padding()
                .cornerRadius(10)
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) { result in
            Task {
                guard let url = try? result.get() else { return }
                if url.startAccessingSecurityScopedResource() {
                    if let importedItems = await DataManager.shared.importJsonFile(from: url) {
                        items = importedItems
                        print("Successfully imported items")
                    }
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
}
