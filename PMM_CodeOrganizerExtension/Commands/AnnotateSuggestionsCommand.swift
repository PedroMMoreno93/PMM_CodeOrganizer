//
//  AnnotateSuggestionsCommand.swift
//  PMM_CodeOrganizerExtension
//
//  Created by Pedro M Moreno.
//

import Foundation
import XcodeKit
import PMM_CodeOrganizerCore

final class AnnotateSuggestionsCommand: NSObject, XCSourceEditorCommand {
    func perform(
        with invocation: XCSourceEditorCommandInvocation,
        completionHandler: @escaping (Error?) -> Void
    ) {
        defer {
            completionHandler(nil)
        }
        guard let lines = invocation.buffer.lines as? [String]
        else {
            return
        }
        var out = lines
        // MVP: añade un sumario al final (luego lo haremos “de verdad”)
        out.append("\n// SUGERENCIAS: (MVP)\n")
        out.append("// - Considera extraer tipos si hay demasiados top-level.\n")
        out.append("// - Considera dividir funciones largas en helpers privados.\n")
        invocation.buffer.lines.setArray(out)
    }
}
