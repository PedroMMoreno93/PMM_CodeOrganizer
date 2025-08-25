//
//  OrganizerPipelineTests.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import XCTest
@testable import PMM_CodeOrganizerCore

final class OrganizerPipelineTests: XCTestCase {

    // Helpers
    private func toLines(_ text: String) -> [String] {
        var arr: [String] = []
        text.enumerateLines { line, _ in arr.append(line + "\n") }
        if text.hasSuffix("\n") == false { arr.append("\n") }
        return arr
    }
    private func fromLines(_ lines: [String]) -> String { lines.joined() }

    // Test 1: snapshot de tu A.swift
    func test_AFile_isOrganizedExactlyAsExpected() {
        let input = """
//
//  A.swift
//  PMM_CodeOrganizer
//
//  Created by Pedro M Moreno on 23/8/25.
//


import SwiftUI

@testable import XCTest
import Foundation

extension A {
    func super() {

    }
    
    var dedeA: String {
        ""
    }
}
import Combine

struct A {
    let x = 0
    
    init() {

    }
    
    private func dede() {

    }
    
    public func aa() {

    }
    
    var algo: String = ""
    
    var otro: Int {
        return 0
    }
}

"""

let expected = """
//
//  A.swift
//  PMM_CodeOrganizer
//
//  Created by Pedro M Moreno on 23/8/25.
//
// MARK: Imports
@testable import XCTest
import Combine
import Foundation
import SwiftUI

struct A {
    // MARK: Constants
    let x = 0

    // MARK: Variables
    var algo: String = ""

    // MARK: Init
    init() {

    }

    // MARK: Computed Properties
    var otro: Int {
        return 0
    }

    // MARK: Public Funcs
    public func aa() {

    }

    // MARK: Private Funcs
    private func dede() {

    }
}

// MARK: Extension A
extension A {
    // MARK: Computed Properties
    var dedeA: String {
        ""
    }

    // MARK: Funcs
    func super() {

    }
}
"""

        var prefs = OrganizerPrefs()
        prefs.insertMarks = true
        prefs.reorderMembers = true
        prefs.reorderTopLevel = true
        prefs.markStyle = .noDash
        prefs.titles = MarkTitles(
            imports: "Imports",
            constants: "Constants",
            variables: "Variables",
            computed: "Computed Properties",
            initTitle: "Init",
            body: "Body",
            publicMethods: "Public Funcs",
            privateMethods: "Private Funcs",
            nestedPrefix: "",
            funcs: "Funcs"
        )

        let outLines = Pipeline.run(lines: toLines(input), prefs: prefs)
        XCTAssertEqual(fromLines(outLines), expected  + "\n", "El output no coincide con el snapshot esperado.")
    }

    // Test 2: #if + atributos y sin línea en blanco tras MARK
    func test_PreprocessorBlocksAndAttributesStayIntact_NoBlankAfterMark() {
        let input = """
        import Foundation

        struct B {
            @available(iOS 17, *)
            public func newAPI() {}

            #if DEBUG
            var dbg: Int {
                1
            }
            #endif
        }
        """

        var prefs = OrganizerPrefs()
        prefs.insertMarks = true
        prefs.reorderMembers = true
        prefs.reorderTopLevel = false
        prefs.markStyle = .noDash

        let lines = Pipeline.run(lines: toLines(input), prefs: prefs)
        let text = lines.joined()

        // 1) No hay línea en blanco justo después de un MARK
        for i in 0..<(lines.count-1) {
            if lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("// MARK:") {
                XCTAssertFalse(lines[i+1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                               "Hay una línea en blanco justo después de un MARK")
            }
        }

        // 2) El bloque #if permanece intacto
        XCTAssertTrue(text.contains("#if DEBUG"), "Falta #if DEBUG")
        XCTAssertTrue(text.contains("#endif"), "Falta #endif")
        XCTAssertTrue(text.range(of: #"#if DEBUG[\s\S]*#endif"#, options: .regularExpression) != nil,
                      "El bloque #if ... #endif no está contiguo")

        // 3) @available mantiene pegado a la función
        XCTAssertTrue(text.contains("@available(iOS 17, *)\n    public func newAPI()"),
                      "El atributo debe quedar inmediatamente encima de la función")
    }
}
