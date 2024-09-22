//
//  Localize.swift
//  To-Do-List
//
//  Created by dark type on 22.09.2024.
//

import Foundation

extension String {
    func localized() -> String {
        NSLocalizedString(self, tableName: "Localizable", bundle: .main, value: self, comment: self)
    }
}
