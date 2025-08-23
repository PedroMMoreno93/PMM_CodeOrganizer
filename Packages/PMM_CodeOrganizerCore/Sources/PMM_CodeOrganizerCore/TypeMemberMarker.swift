//
//  TypeMemberMarker.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum TypeMemberMarker {
    private static let typeStartRx = try! NSRegularExpression(
        pattern: #"^\s*(public|internal|private|fileprivate)?\s*(final\s+)?(struct|class|actor|enum)\s+\w+"#,
        options: [.anchorsMatchLines]
    )
    private static let markConstantsRx = try! NSRegularExpression(
        pattern: #"^\s*//\s*MARK:\s*-?\s*Constants\b"#,
        options: [.caseInsensitive, .anchorsMatchLines]
    )
    private static let storedLetRx = try! NSRegularExpression(
        pattern: #"^\s*(public|internal|private|fileprivate)?\s*(static\s+)?let\s+\w+"#,
        options: [.anchorsMatchLines]
    )

    public static func insertConstantsMark(in lines: [String]) -> [String] {
        var out = lines
        var i = 0
        while i < out.count {
            if matches(typeStartRx, out[i]) {
                // 1) encuentra la primera llave de apertura del tipo (puede estar en la línea siguiente)
                guard let openIdx = findOpenBrace(in: out, startingAt: i) else { i += 1; continue }

                // 2) recorre el cuerpo del tipo con depth estándar: empieza en 1 y termina cuando vuelve a 0
                var depth = 1
                var j = openIdx + 1
                var firstLetAtDepth1: Int? = nil

                while j < out.count {
                    // si estamos en “nivel 1” dentro del tipo, detecta el primer let almacenado
                    if depth == 1, matches(storedLetRx, out[j]) {
                        firstLetAtDepth1 = firstLetAtDepth1 ?? j
                    }
                    // ajusta profundidad por llaves de la línea
                    let opens = out[j].filter { $0 == "{" }.count
                    let closes = out[j].filter { $0 == "}" }.count
                    depth += opens
                    depth -= closes
                    if depth == 0 { break } // cerró el tipo
                    j += 1
                }

                if let insertAt = firstLetAtDepth1 {
                    // 3) evita duplicar: ¿ya hay un MARK: Constants entre “{” y el let?
                    let hasExisting = (openIdx+1..<insertAt).contains { idx in matches(markConstantsRx, out[idx]) }
                    if !hasExisting {
                        let indent = indentation(of: out[insertAt])
                        out.insert(indent + "// MARK: Constants\n", at: insertAt)
                        i = insertAt + 1
                        continue
                    }
                }
                i = j + 1
            } else {
                i += 1
            }
        }
        return out
    }

    // helpers
    private static func matches(_ rx: NSRegularExpression, _ line: String) -> Bool {
        rx.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) != nil
    }
    private static func indentation(of line: String) -> String {
        String(line.prefix { $0 == " " || $0 == "\t" })
    }
    private static func findOpenBrace(in lines: [String], startingAt idx: Int) -> Int? {
        var k = idx
        while k < lines.count {
            if lines[k].contains("{") { return k }
            k += 1
        }
        return nil
    }
}
