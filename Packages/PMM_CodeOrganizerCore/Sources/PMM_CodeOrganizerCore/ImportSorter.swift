//
//  ImportSorter.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum ImportSorter {
    private static let importRegex = try! NSRegularExpression(
        pattern: #"^\s*(@testable\s+)?import\s+\w+"#, options: [.anchorsMatchLines]
    )

    public static func sortAndHoistAllImports(in lines: [String]) -> [String] {
        var headerEnd = 0
        // Mantén banner/comentarios iniciales
        while headerEnd < lines.count, lines[headerEnd].trimmingCharacters(in: .whitespaces).hasPrefix("//") || lines[headerEnd].trimmingCharacters(in: .whitespaces).isEmpty {
            headerEnd += 1
        }

        // Extrae todos los imports y elimina sus líneas originales
        var body = lines
        var imports: [String] = []
        for (idx, line) in lines.enumerated().reversed() {
            if matchesImport(line) {
                imports.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
                body.remove(at: idx)
            }
        }
        guard !imports.isEmpty else { return lines }

        // Normaliza, dedup y ordena
        let unique = Array(NSOrderedSet(array: imports)) as! [String]
        let sorted = unique.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        // Inserta bloque ordenado tras cabecera
        var out: [String] = []
        out.append(contentsOf: body[..<headerEnd])
        out.append("// MARK: - Imports\n")
        out.append(contentsOf: sorted.map { $0 + "\n" })
        if body[headerEnd].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false { out.append("\n") }
        out.append(contentsOf: body[headerEnd...])
        return out
    }

    private static func matchesImport(_ line: String) -> Bool {
        importRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) != nil
    }
}
