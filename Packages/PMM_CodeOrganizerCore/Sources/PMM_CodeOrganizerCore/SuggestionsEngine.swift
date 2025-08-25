//
//  SuggestionsEngine.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum SuggestionsEngine {

    // Reuse de algunos regex
    private static let importRx   = try! NSRegularExpression(pattern: #"^\s*(@testable\s+)?import\s+\w+"#, options: [.anchorsMatchLines])
    private static let typeRx     = try! NSRegularExpression(pattern: #"^\s*(public|internal|private|fileprivate)?\s*(final\s+)?(struct|class|actor|enum)\s+\w+"#, options: [.anchorsMatchLines])
    private static let extRx      = try! NSRegularExpression(pattern: #"^\s*extension\s+\w+"#, options: [.anchorsMatchLines])
    private static let funcRx     = try! NSRegularExpression(pattern: #"^\s*(public|internal|private|fileprivate|open)?\s*(override\s+)?(static\s+)?func\s+\w+\s*\("#, options: [.anchorsMatchLines])
    private static let storedLet  = try! NSRegularExpression(pattern: #"^\s*(public|internal|private|fileprivate)?\s*(static\s+)?let\s+\w+"#, options: [.anchorsMatchLines])
    private static let storedVar  = try! NSRegularExpression(pattern: #"^\s*(public|internal|private|fileprivate)?\s*(static\s+)?var\s+\w+"#, options: [.anchorsMatchLines])
    private static let markRx     = try! NSRegularExpression(pattern: #"^\s*//\s*SUGERENCIA:"#)

    public static func analyze(lines: [String], prefs: OrganizerPrefs) -> [Suggestion] {
        var sugs: [Suggestion] = []

        // 0) Archivo muy largo
        let totalLines = lines.count
        if totalLines > prefs.maxFileLines {
            sugs.append(Suggestion(line: 0,
                                   message: "Archivo grande (\(totalLines) líneas). Considera dividir en varios ficheros lógicos.",
                                   severity: .info, category: .longFile))
        }

        // 1) Imports dispersos o no contiguos
        let importIdxs = lines.enumerated().compactMap { matches(importRx, $0.element) ? $0.offset : nil }
        if !importIdxs.isEmpty {
            // deben estar todos en la cabecera, contiguos
            let minI = importIdxs.min()!, maxI = importIdxs.max()!
            let contiguous = importIdxs.count == (maxI - minI + 1)
            if minI > 0 || !contiguous {
                let at = safeCommentPos(lines, itemIndex: minI, blockOpen: -1)
                sugs.append(Suggestion(line: at,
                    message: "Imports dispersos. Usa “Organize & Mark” para agrupar y ordenar al inicio.",
                    severity: .info, category: .imports))
            }
        }

        // 2) Particiona top-level en bloques para medir tipos/extensiones
        let top = sliceTopLevelBlocks(in: lines)
        var topLevelTypesCount = 0

        for blk in top {
            guard let start = blk.start, let end = blk.end else { continue }
            let firstLine = lines[start]
            let isType = matches(typeRx, firstLine)
            let isExt  = matches(extRx, firstLine)

            // Tipos largos
            if isType {
                topLevelTypesCount += 1
                let span = end - start + 1
                if span > prefs.maxTypeLines {
                    let pos = safeCommentPos(lines, itemIndex: start, blockOpen: start-1)
                    sugs.append(Suggestion(line: pos,
                        message: "Tipo largo (\(span) líneas). Considera extraer tipos/funciones privadas.",
                        severity: .warning, category: .longType))
                }
            }

            // Propiedades almacenadas no estáticas en extension (no permitidas)
            if isExt {
                var i = start+1
                var depth = 1
                while i <= end {
                    if depth == 1 {
                        if matches(storedLet, lines[i]) || (matches(storedVar, lines[i]) && !lines[i].contains(" static ")) {
                            let pos = safeCommentPos(lines, itemIndex: i, blockOpen: start)
                            sugs.append(Suggestion(line: pos,
                                message: "Propiedad almacenada en extension. Solo se permiten `static` o computadas.",
                                severity: .warning, category: .extensionStoredProp))
                        }
                    }
                    depth += lines[i].filter { $0 == "{" }.count
                    depth -= lines[i].filter { $0 == "}" }.count
                    i += 1
                }
            }

            // Funciones dentro del bloque: tamaño, params, “complejidad” aproximada
            var i = start
            while i <= end {
                if matches(funcRx, lines[i]) {
                    let fnStart = i
                    let fnEnd = findMemberEnd(in: lines, from: i, limit: end)
                    let span = fnEnd - fnStart + 1

                    if span > prefs.maxFunctionLines {
                        let pos = safeCommentPos(lines, itemIndex: fnStart, blockOpen: start)
                        sugs.append(Suggestion(line: pos,
                            message: "Función larga (\(span) líneas). Considera extraer helpers privados.",
                            severity: .warning, category: .longFunc))
                    }

                    // parámetros
                    let params = countParams(in: lines[fnStart])
                    if params > prefs.maxParamsPerFunc {
                        let pos = safeCommentPos(lines, itemIndex: fnStart, blockOpen: start)
                        sugs.append(Suggestion(line: pos,
                            message: "Demasiados parámetros (\(params)). Considera agrupar en un tipo/struct.",
                            severity: .info, category: .manyParams))
                    }

                    // complejidad (tokens simples)
                    let complexity = countComplexityTokens(in: Array(lines[fnStart...fnEnd]))
                    if complexity > prefs.maxComplexityTokens {
                        let pos = safeCommentPos(lines, itemIndex: fnStart, blockOpen: start)
                        sugs.append(Suggestion(line: pos,
                            message: "Alta complejidad (~\(complexity) ramas). Considera dividir en funciones más pequeñas.",
                            severity: .info, category: .highComplexity))
                    }

                    i = fnEnd + 1; continue
                }
                i += 1
            }
        }

        // demasiados tipos top-level
        if topLevelTypesCount > prefs.maxTopLevelTypes {
            sugs.append(Suggestion(line: 0,
                                   message: "Hay \(topLevelTypesCount) tipos top-level. Considera extraer a ficheros separados.",
                                   severity: .info, category: .tooManyTopLevel))
        }

        return sugs
    }

    // MARK: - Inserción de comentarios

    public static func apply(suggestions: [Suggestion], on lines: [String]) -> [String] {
        guard !suggestions.isEmpty else { return lines }
        var out = lines

        // Evitar duplicados: si ya hay una línea SUGERENCIA exactamente encima, no insertes otra
        let sorted = suggestions.sorted { $0.line > $1.line }
        for s in sorted {
            let comment = "// SUGERENCIA (\(s.severity.rawValue)): \(s.message)\n"
            if s.line > 0 && matches(markRx, out[s.line - 1]) { continue }
            out.insert(comment, at: s.line)
        }

        // Resumen al final
        let counts = Dictionary(grouping: suggestions, by: { $0.category }).mapValues(\.count)
        var summary: [String] = []
        summary.append("\n// SUGERENCIAS: \(suggestions.count) en total\n")
        for (cat, n) in counts.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            summary.append("// - \(cat.rawValue): \(n)\n")
        }
        out.append(contentsOf: summary)
        return out
    }

    // MARK: - Helpers de análisis

    private struct Block { let start: Int?; let end: Int? }
    private static func sliceTopLevelBlocks(in lines: [String]) -> [Block] {
        var res: [Block] = []
        var depth = 0
        var currentStart: Int? = nil

        for (i, l) in lines.enumerated() {
            if depth == 0, (matches(typeRx, l) || matches(extRx, l)) {
                if let s = currentStart {
                    res.append(Block(start: s, end: i-1))
                }
                currentStart = i
            }
            depth += l.filter { $0 == "{" }.count
            depth -= l.filter { $0 == "}" }.count
        }
        if let s = currentStart { res.append(Block(start: s, end: lines.count-1)) }
        return res
    }

    private static func findMemberEnd(in lines: [String], from idx: Int, limit: Int) -> Int {
        var i = idx
        var local = 0
        var sawBrace = false
        while i <= limit {
            let opens = lines[i].filter { $0 == "{" }.count
            let closes = lines[i].filter { $0 == "}" }.count
            local += opens; local -= closes
            if opens > 0 { sawBrace = true }
            if sawBrace && local == 0 { return i }
            if !sawBrace { return i } // declaración de 1 línea
            i += 1
        }
        return min(limit, i)
    }

    private static func safeCommentPos(_ lines: [String], itemIndex: Int, blockOpen: Int) -> Int {
        var pos = itemIndex
        // sube blancos
        while pos > blockOpen+1 && lines[pos - 1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { pos -= 1 }
        // sube atributos
        while pos > blockOpen+1 && lines[pos - 1].trimmingCharacters(in: .whitespaces).hasPrefix("@") { pos -= 1 }
        return pos
    }

    private static func countParams(in signature: String) -> Int {
        guard let open = signature.firstIndex(of: "("), let close = signature.lastIndex(of: ")"), close > open else { return 0 }
        let inner = signature[signature.index(after: open)..<close]
        let trimmed = inner.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return 0 }
        // cuenta comas al nivel 0 de paréntesis <> genéricos ignorados (simple)
        var count = 1
        var paren = 0
        for ch in trimmed {
            if ch == "(" { paren += 1 }
            else if ch == ")" { paren -= 1 }
            else if ch == "," && paren == 0 { count += 1 }
        }
        return count
    }

    private static func countComplexityTokens(in chunk: [String]) -> Int {
        var n = 0
        let tokens = [" if ", " guard ", " switch ", " for ", " while ", " catch "]
        for l in chunk {
            let t = " " + l + " "
            for tok in tokens where t.contains(tok) { n += 1 }
        }
        return n
    }

    private static func matches(_ rx: NSRegularExpression, _ line: String) -> Bool {
        rx.firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length)) != nil
    }
}
