//
//  MarkInserter.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum MarkInserter {
    private static let importRegex = try! NSRegularExpression(
        pattern: #"^\s*(@testable\s+)?import\s+\w+"#, options: [.anchorsMatchLines]
    )
    
    private static let importsMarkRegex = try! NSRegularExpression(
        pattern: #"^\s*//\s*MARK:\s*-?\s*Imports\b"#, options: [.caseInsensitive, .anchorsMatchLines]
    )
    
    public static func ensureSingleImportsMark(
        in lines: [String],
        title: String,
        style: MarkStyle
    ) -> [String] {
        var out = lines
        guard let firstImport = out.firstIndex(where: {
            matchesImport($0)
        }) else {
            return out
        }
        
        // busca hacia arriba saltando en blanco
        var look = firstImport - 1
        while look >= 0, out[look].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            look -= 1
        }
        
        let hasMark = look >= 0 ? matchesImportsMark(out[look]) : false
        
        if !hasMark {
            out.insert(style.prefix + "\(title)\n", at: firstImport)
        }
        // colapsa duplicados
        var i = 1
        while i < out.count {
            if matchesImportsMark(out[i]) && matchesImportsMark(out[i-1]) {
                out.remove(at: i)
                continue
            }
            i += 1
        }
        return out
    }
    
    private static func matchesImport(
        _ line: String
    ) -> Bool {
        importRegex.firstMatch(
            in: line,
            range: NSRange(location: 0, length: line.utf16.count)
        ) != nil
    }
    
    private static func matchesImportsMark(_ line: String) -> Bool {
        importsMarkRegex.firstMatch(
            in: line,
            range: NSRange(location: 0, length: line.utf16.count)
        ) != nil
    }
}
