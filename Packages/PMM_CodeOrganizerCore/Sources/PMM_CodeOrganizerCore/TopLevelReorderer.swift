//
//  TopLevelReorderer.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum TopLevelReorderer {
    private static let extStartRx = try! NSRegularExpression(
        pattern: #"^\s*extension\s+\w+\b"#, options: [.anchorsMatchLines]
    )

    public static func moveExtensionsToBottom(in lines: [String]) -> [String] {
        var rest: [String] = []
        var exts: [[String]] = []

        var i = 0
        var depth = 0
        while i < lines.count {
            let line = lines[i]
            let isExt = depth == 0 && matches(extStartRx, line)
            if isExt {
                // captura el bloque completo de la extension
                guard let end = findBlockClose(in: lines, startingAt: i) else {
                    // si no hay cierre, no tocar
                    rest.append(line); i += 1; continue
                }
                // recorta blancos finales en 'rest' (deja máx 1)
                while rest.count >= 2,
                      rest[rest.count-1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      rest[rest.count-2].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    rest.removeLast()
                }
                exts.append(Array(lines[i...end]))
                i = end + 1
                continue
            } else {
                rest.append(line)
                depth += line.filter { $0 == "{" }.count
                depth -= line.filter { $0 == "}" }.count
                i += 1
            }
        }

        // reconstruye: resto (colapsado) + 1 salto + extensiones (1 salto entre ellas)
        var out = WhitespaceNormalizer.collapseBlankLines(rest)
        if !exts.isEmpty {
            if !out.isEmpty && !out.last!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                out.append("\n")
            }
            for (idx, block) in exts.enumerated() {
                if idx > 0 { out.append("\n") }
                out.append(contentsOf: block)
                if !out.last!.hasSuffix("\n") { out[out.count-1] += "\n" }
            }
        }
        return out
    }

    private static func matches(_ rx: NSRegularExpression, _ line: String) -> Bool {
        rx.firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length)) != nil
    }
    private static func findBlockClose(in lines: [String], startingAt start: Int) -> Int? {
        var d = 0
        var i = start
        while i < lines.count {
            d += lines[i].filter { $0 == "{" }.count
            d -= lines[i].filter { $0 == "}" }.count
            if d == 0 { return i }
            i += 1
        }
        return nil
    }
}
