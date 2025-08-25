//
//  JSONFormatter.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum JSONFormatter {

    public struct ParseIssue {
        public let line: Int
        public let column: Int
        public let message: String
    }

    /// Punto de entrada: formatea si es JSON válido; si no, deja intacto y anota un warning en la línea del error.
    /// - Returns: líneas de salida (listas para `buffer.lines.setArray`)
    public static func formatOrAnnotate(lines: [String]) -> [String] {
        let originalText = lines.joined()
        switch prettyPrinted(text: originalText) {
        case .success(let pretty):
            return toLines(pretty)
        case .failure(let parseError):
            // Intentamos localizar el problema para anotar
            let issue = locateIssueHeuristically(in: originalText) ?? parseError
            return insertWarning(issue: issue, on: lines)
        }
    }

    // MARK: - Pretty print

    private enum PrettyResult { case success(String), failure(ParseIssue) }

    private static func prettyPrinted(text: String) -> PrettyResult {
        guard let data = text.data(using: .utf8) else {
            return .failure(ParseIssue(line: 0, column: 0, message: "Codificación no UTF-8"))
        }
        do {
            // Permite fragmentos (true/false/null/“string”), y pretty-print
            let obj = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let pretty = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted])
            var out = String(data: pretty, encoding: .utf8) ?? ""
            if !out.hasSuffix("\n") { out.append("\n") }
            return .success(out)
        } catch let err as NSError {
            let msg = err.userInfo[NSDebugDescriptionErrorKey] as? String
                ?? err.localizedDescription
            // JSONSerialization no da línea/columna; devolvemos issue sin posición exacta.
            return .failure(ParseIssue(line: 0, column: 0, message: "JSON inválido: \(msg)"))
        }
    }

    // MARK: - Heurístico de localización (llaves/corchetes y strings)

    /// Intenta señalar el primer problema obvio: cierre sin apertura, string sin cerrar, falta de cierre.
    private static func locateIssueHeuristically(in text: String) -> ParseIssue? {
        var line = 0, col = 0
        var stack: [(expected: Character, line: Int, column: Int)] = []
        var inString = false
        var stringStart: (line: Int, column: Int)? = nil
        var escaped = false

        func advance(_ ch: Character) { if ch == "\n" { line += 1; col = 0 } else { col += 1 } }

        for ch in text {
            if inString {
                if escaped { escaped = false }
                else if ch == "\\" { escaped = true }
                else if ch == "\"" { inString = false; stringStart = nil }
                advance(ch); continue
            }
            switch ch {
            case "\"": inString = true; stringStart = (line, col)
            case "{": stack.append(("}", line, col))
            case "[": stack.append(("]", line, col))
            case "}", "]":
                if stack.isEmpty || stack.last!.expected != ch {
                    return ParseIssue(line: line, column: col, message: "Cierre '\(ch)' sin apertura correspondiente")
                } else { _ = stack.popLast() }
            default: break
            }
            advance(ch)
        }

        // EOF alcanzado
        if inString, let s = stringStart {
            return ParseIssue(line: s.line, column: s.column, message: "Cadena sin cerrar")
        }
        if let unclosed = stack.last {
            // ✅ En vez de devolver la posición de APERTURA, señalamos el EOF como sitio donde falta cerrar
            let eof = eofPosition(for: text) // (línea, col) del último carácter
            let missing = unclosed.expected
            let cdesc = missing == "}" ? "}" : "]"
            return ParseIssue(line: eof.line, column: eof.col, message: "Falta cerrar '\(cdesc)'")
        }
        return nil
    }

    private static func eofPosition(for text: String) -> (line: Int, col: Int) {
        var line = 0, col = 0
        for ch in text {
            if ch == "\n" { line += 1; col = 0 } else { col += 1 }
        }
        return (line, col)
    }


    // MARK: - Inserción de warning

    private static func insertWarning(issue: ParseIssue, on lines: [String]) -> [String] {
        var out = lines
        let idx = max(0, min(issue.line, out.count)) // si se sale, lo ajustamos
        let warning = "// PMM_JSON_WARNING: \(issue.message) (línea \(issue.line + 1), col \(issue.column + 1))\n"

        // Idempotencia suave: evita duplicar si ya hay un warning igual pegado
        if idx < out.count, out[idx].contains("PMM_JSON_WARNING") { return out }
        if idx > 0, out[idx - 1].contains("PMM_JSON_WARNING") { return out }

        // Insertamos una línea de comentario inmediatamente antes de la línea detectada (o al final si EOF)
        let insertAt = min(idx, out.count)
        var insertion: [String] = []
        // Si justo arriba no hay línea en blanco, mete una para separar visualmente
        if insertAt > 0, out[insertAt - 1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            insertion.append("\n")
        }
        insertion.append(warning)
        out.insert(contentsOf: insertion, at: insertAt)
        return out
    }

    // MARK: - Utils

    private static func toLines(_ text: String) -> [String] {
        var arr: [String] = []
        text.enumerateLines { line, _ in arr.append(line + "\n") }
        if !text.hasSuffix("\n") { arr.append("\n") }
        return arr
    }
}
