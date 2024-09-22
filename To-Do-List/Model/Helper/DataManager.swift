//
//  Model.swift
//  To-Do-List
//
//  Created by dark type on 11.09.2024.
//
import Foundation
import UniformTypeIdentifiers

actor DataManager {
    static let shared = DataManager()

    private init() {}

    func saveToJsonFile(tasks: [TaskData]) async {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileUrl = documentDirectoryUrl.appendingPathComponent("tasks.json")

        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(tasks)
            try data.write(to: fileUrl, options: .atomic)
            print("Tasks successfully saved to \(fileUrl)")
        } catch {
            print("Files were not encoded properly due to \(error)")
        }
    }

    func loadJsonFile() async -> [TaskData] {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to get documents directory URL")
            return []
        }
        let fileUrl = documentDirectoryUrl.appendingPathComponent("tasks.json")

        do {
            let data = try Data(contentsOf: fileUrl)
            let decoder = JSONDecoder()
            let tasks = try decoder.decode([TaskData].self, from: data)
            print("Successfully loaded tasks from \(fileUrl)")
            return tasks
        } catch {
            print("Failed to load JSON file due to error: \(error.localizedDescription)")
            return []
        }
    }

    func exportJsonFile(tasks: [TaskData]) async -> ExportDocument {
        let encoder = JSONEncoder()
        print("export tasks")
        print(tasks)
        do {
            let data = try encoder.encode(tasks)
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            return ExportDocument(text: jsonString)
        } catch {
            print("Error encoding tasks: \(error)")
            return ExportDocument(text: "")
        }
    }

    func importJsonFile(from url: URL) async -> [TaskData]? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode([TaskData].self, from: data)
        } catch {
            print("Error decoding imported JSON: \(error)")
            return nil
        }
    }
}
