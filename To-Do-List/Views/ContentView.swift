//
//  ContentView.swift
//  To-Do-List
//
//  Created by dark type on 11.09.2024.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @State private var items: [TaskData] = []
    @State private var importing = false
    @State private var exporting = false
    
    var body: some View {
        NavigationView {
            VStack {
                if items.isEmpty {
                    Spacer()
                    Label("Your list is empty", systemImage: "tray").imageScale(.large).font(.largeTitle).multilineTextAlignment(.center).padding()
                    Text("Go add some tasks!").font(.callout)
                    Spacer()
                }
                else {
                    List($items) { $item in
                        HStack {
                            Task(task: $item).onChange(of: items) { saveItems() }.swipeActions{
                                Button(action: {
                                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                                        items.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "trash.fill")
                                }.tint(.red)
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .navigationTitle("ToDo List")
                    .navigationBarItems(trailing: Button(action: { exporting = true }, label: {
                        Image(systemName: "square.and.arrow.up.on.square")

                    }).fileExporter(isPresented: $exporting, document: DataManager.shared.exportJsonFile(tasks: items), contentType: .plainText, defaultFilename: "tasks.json") { result in
                        switch result {
                        case .success(let url):
                            print("exported successfully to \(url)")

                        case .failure(let error):
                            print("did not export due to: \(error.localizedDescription)")
                        }
                    }
                    )
                }

            

                HStack {
                    Button(action: {importing = true}) {
                        Image(systemName: "square.and.arrow.down")
                            .padding()
                            .cornerRadius(10)
                    }.fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) { result in
                        guard let url = try? result.get() else { return }
                        if url.startAccessingSecurityScopedResource(){
                            if let importedItems = DataManager.shared.importJsonFile(from: url) {
                                items = importedItems
                                print("Successfully imported items")
                            }
                            url.stopAccessingSecurityScopedResource()
                        }

                    }
                    Spacer()
                   
                    

                    Button(action: addNewItem) {
                        Label("", systemImage: "plus.rectangle.on.rectangle")
                            .padding()
                            .cornerRadius(10)
                    }
                }.padding(.leading, 15)
                    .padding(.trailing, 15)
            }
        }
    }

    private func addNewItem() {
        let newItem = TaskData(taskName: "", isDone: false)
        withAnimation {
            items.append(newItem)
        }
        saveItems()
    }

    private func deleteItems(offsets: IndexSet) {}

    func saveItems() {
        DataManager.shared.saveToJsonFile(tasks: items)
    }

    func loadItems() {
        if let loadedTasks = DataManager.shared.loadJsonFile() {
            items = loadedTasks
        }
    }
}

#Preview {
    ContentView()
}
