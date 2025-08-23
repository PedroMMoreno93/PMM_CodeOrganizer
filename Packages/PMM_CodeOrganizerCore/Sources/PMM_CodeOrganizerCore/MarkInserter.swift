//
//  MarkInserter.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum MarkInserter {
    /// Inserta // MARK: - Imports antes del primer import si no existe ya un MARK cerca.
    public static func insertImportsMark(in lines: [String]) -> [String] {
        var out = lines
        guard let firstImport = out.firstIndex(
            where: {
                $0.trimmingCharacters(in: .whitespaces).hasPrefix("import ")
            }) else {
            return out
        }
        let mark = "// MARK: - Imports\n"
        if firstImport == 0 || !out[max(0, firstImport-1)].contains("// MARK:") {
            out.insert(mark, at: firstImport)
        }
        return out
    }
}
