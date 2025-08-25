//
//  SuggestionsEngineTests.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno on 25/8/25.
//

import XCTest
@testable import PMM_CodeOrganizerCore

final class SuggestionsEngineTests: XCTestCase {

    // MARK: - Helpers
    private func toLines(_ text: String) -> [String] {
        var arr: [String] = []
        text.enumerateLines { line, _ in arr.append(line + "\n") }
        if !text.hasSuffix("\n") { arr.append("\n") }
        return arr
    }
    private func fromLines(_ lines: [String]) -> String { lines.joined() }
    private func countSuggestionComments(in text: String) -> Int {
        text.components(separatedBy: .newlines).filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("// SUGERENCIA") }.count
    }

    // MARK: - Tests

    /// Debe sugerir agrupar/ordenar imports cuando están dispersos o no contiguos.
    func test_ImportsDispersed_YieldsSuggestion() {
        let input = """
        import Foundation

        struct Foo {}
        import SwiftUI
        """

        var prefs = OrganizerPrefs()
        // umbrales por defecto valen; aquí solo queremos la sugerencia de imports
        let sugs = SuggestionsEngine.analyze(lines: toLines(input), prefs: prefs)

        XCTAssertTrue(sugs.contains(where: { $0.category == .imports }),
                      "Debería sugerir organizar imports cuando están dispersos")
    }

    /// Función larga + muchos parámetros + alta complejidad + tipo largo
    func test_LongFunc_Params_Complexity_LongType() {
        let input = """
        struct S {
            func big(a: Int, b: Int, c: Int) {
                if true { }
                for _ in 0..<10 { }
                if true { }
                if true { }
                // relleno
                print("x")
                print("y")
                print("z")
            }
        }
        """

        var prefs = OrganizerPrefs()
        prefs.maxFunctionLines = 5           // bajamos para forzar longFunc
        prefs.maxComplexityTokens = 2        // if/for/while/guard/switch/catch > 2
        prefs.maxParamsPerFunc = 2           // 3 params → manyParams
        prefs.maxTypeLines = 8               // tipo pasa el límite

        let sugs = SuggestionsEngine.analyze(lines: toLines(input), prefs: prefs)

        XCTAssertTrue(sugs.contains(where: { $0.category == .longFunc }), "Debe detectar función larga")
        XCTAssertTrue(sugs.contains(where: { $0.category == .manyParams }), "Debe detectar demasiados parámetros")
        XCTAssertTrue(sugs.contains(where: { $0.category == .highComplexity }), "Debe detectar alta complejidad")
        XCTAssertTrue(sugs.contains(where: { $0.category == .longType }), "Debe detectar tipo largo")
    }

    /// En extension no están permitidas stored properties no estáticas
    func test_ExtensionStoredProperty_Warns() {
        let input = """
        struct S {}

        extension S {
            var x = 0
        }
        """

        let sugs = SuggestionsEngine.analyze(lines: toLines(input), prefs: OrganizerPrefs())
        XCTAssertTrue(sugs.contains(where: { $0.category == .extensionStoredProp }),
                      "Debe avisar de propiedad almacenada en extensión")
    }

    /// apply() NO debe duplicar comentarios si se aplica dos veces
    func test_Apply_IsIdempotent() {
        let input = """
        import Foundation

        struct Foo {}
        import SwiftUI
        """

        let prefs = OrganizerPrefs()
        let lines = toLines(input)
        let sugs = SuggestionsEngine.analyze(lines: lines, prefs: prefs)

        let once = SuggestionsEngine.apply(suggestions: sugs, on: lines)
        let twice = SuggestionsEngine.apply(suggestions: sugs, on: once)

        let c1 = countSuggestionComments(in: fromLines(once))
        let c2 = countSuggestionComments(in: fromLines(twice))

        XCTAssertEqual(c1, c2, "No debe duplicar comentarios de sugerencia al aplicar dos veces")
        XCTAssertEqual(c1, sugs.count, "Debe haber un comentario por sugerencia")
    }
}
