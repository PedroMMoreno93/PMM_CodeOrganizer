//
//  ImportSorterTests.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import XCTest
@testable import PMM_CodeOrganizerCore

final class ImportSorterTests: XCTestCase {
    func test_sortsContiguousImportsAtTop() {
        let input = [
            "import SwiftUI\n",
            "import Foundation\n",
            "\n",
            "struct A {}\n"
        ]
        let out = ImportSorter.hoistAndSortImports(in: input)
        XCTAssertEqual(out[0], "import Foundation\n")
        XCTAssertEqual(out[1], "import SwiftUI\n")
    }
}
