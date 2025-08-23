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
    private static let importsMarkRegex = try! NSRegularExpression(
        pattern: #"^\s*//\s*MARK:\s*-?\s*Imports\b"#, options: [.caseInsensitive, .anchorsMatchLines]
    )
    
    public static func hoistAndSortImports(in lines: [String]) -> [String] {
        // 1) Detecta cabecera (comentarios/banco)
        var headerEnd = 0
        while headerEnd < lines.count {
            let t = lines[headerEnd].trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("//") || t.isEmpty { headerEnd += 1 } else { break }
        }
        
        // 2) Extrae todos los imports (en cualquier parte)
        var body = lines
        var imports: [String] = []
        
        for (idx, line) in lines.enumerated().reversed() {
            if matchesImport(line) {
                imports.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
                body.remove(at: idx)
            } else if matchesImportsMark(line) {
                // elimina cualquier MARK de Imports antiguo para no duplicar
                body.remove(at: idx)
            }
        }
        guard !imports.isEmpty else { return lines }
        
        // 3) Normaliza, dedup y ordena
        let unique = Array(NSOrderedSet(array: imports)) as! [String]
        let sorted = unique.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        
        // 4) Inserta imports ordenados tras la cabecera (sin MARK aquí)
        var out: [String] = []
        out.append(contentsOf: body[..<headerEnd])
        out.append(contentsOf: sorted.map { $0 + "\n" })
        // separador con el resto si hace falta
        if headerEnd < body.count, body[headerEnd].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            out.append("\n")
        }
        out.append(contentsOf: body[headerEnd...])
        return out
    }
    
    private static func matchesImport(_ line: String) -> Bool {
        importRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) != nil
    }
    
    private static func matchesImportsMark(_ line: String) -> Bool {
        importsMarkRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) != nil
    }
}
