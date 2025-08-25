//
//  JSONFormatterTests.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import XCTest
@testable import PMM_CodeOrganizerCore

final class JSONFormatterTests: XCTestCase {

    // Helpers
    private func toLines(_ text: String) -> [String] {
        var arr: [String] = []
        text.enumerateLines { line, _ in arr.append(line + "\n") }
        if !text.hasSuffix("\n") { arr.append("\n") }
        return arr
    }
    private func fromLines(_ lines: [String]) -> String { lines.joined() }

    private func warningLines(in lines: [String]) -> [Int] {
        lines.enumerated().compactMap { idx, s in
            s.contains("PMM_JSON_WARNING") ? idx : nil
        }
    }

    // 1) JSON válido → pretty print estable
    func test_PrettyPrint_ValidJSON() {
        let input = #"{"a":1,"b":[true,"x"],"c":{"k":"v"}}"#
        let outLines = JSONFormatter.formatOrAnnotate(lines: toLines(input))
        let out = fromLines(outLines)

        // Debe empezar por '{' y tener saltos/indentación
        XCTAssertTrue(out.hasPrefix("{\n"), "Debe pretty-printear con salto tras '{'")
        XCTAssertTrue(out.contains(#""a" : 1"#) || out.contains(#""a": 1"#), "Debe contener clave 'a' con valor 1")
        XCTAssertTrue(out.hasSuffix("\n"), "Debe terminar en nueva línea")
        // No debe haber warnings
        XCTAssertTrue(warningLines(in: outLines).isEmpty, "No deben insertarse warnings en JSON válido")
    }

    // 2) String sin cerrar → warning y contenido intacto
    func test_UnclosedString_WarnsAndKeepsContent() {
        let input = #"{"a":"hola}"#
        let lines = toLines(input)
        let outLines = JSONFormatter.formatOrAnnotate(lines: lines)
        let out = fromLines(outLines)

        // Debe insertar exactamente un warning
        let warns = warningLines(in: outLines)
        XCTAssertEqual(warns.count, 1, "Debe insertarse un único warning")
        // El resto del contenido debe permanecer (subcadena presente)
        XCTAssertTrue(out.contains(input), "El contenido original debe permanecer intacto")
    }

    // 3) Falta cierre de '}' → warning al principio y contenido intacto
    func test_MissingClosingBrace_WarnsAndKeepsContent() {
        let input = #"{"a":1"#
        let outLines = JSONFormatter.formatOrAnnotate(lines: toLines(input))
        let out = fromLines(outLines)

        let warns = warningLines(in: outLines)
        XCTAssertEqual(warns.count, 1)
        XCTAssertTrue(out.contains(input))
        XCTAssertTrue(out.contains("Falta cerrar '}'") || out.contains("JSON inválido"),
                      "El mensaje debe indicar el problema de cierre")
    }

    // 4) Cierre inesperado '}' → warning
    func test_UnexpectedClosingBrace_Warns() {
        let input = #"}"#
        let outLines = JSONFormatter.formatOrAnnotate(lines: toLines(input))
        let out = fromLines(outLines)

        let warns = warningLines(in: outLines)
        XCTAssertEqual(warns.count, 1)
        XCTAssertTrue(out.contains("Cierre '}' sin apertura"), "Debe indicar cierre sin apertura")
        XCTAssertTrue(out.contains(input), "Contenido original debe quedar")
    }

    // 5) No es JSON en absoluto → warning genérico y contenido intacto
    func test_NonJSON_WarnsGenericAndKeepsContent() {
        let input = "hello world"
        let outLines = JSONFormatter.formatOrAnnotate(lines: toLines(input))
        let out = fromLines(outLines)

        let warns = warningLines(in: outLines)
        XCTAssertEqual(warns.count, 1)
        XCTAssertTrue(out.contains("JSON inválido") || out.contains("Codificación"), "Debe avisar que no es JSON")
        XCTAssertTrue(out.contains(input))
    }

    // 6) Idempotencia en inválido: aplicar dos veces no duplica warnings
    func test_Invalid_IdempotentWarning() {
        let input = #"}"#
        let once = JSONFormatter.formatOrAnnotate(lines: toLines(input))
        let twice = JSONFormatter.formatOrAnnotate(lines: once)

        XCTAssertEqual(warningLines(in: once).count, 1)
        XCTAssertEqual(warningLines(in: twice).count, 1, "No debe duplicar el warning al aplicar de nuevo")
    }
}
