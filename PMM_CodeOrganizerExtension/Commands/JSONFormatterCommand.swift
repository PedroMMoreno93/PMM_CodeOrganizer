//
//  JSONFormatterCommand.swift
//  PMM_CodeOrganizerExtension
//
//  Created by Pedro M Moreno on 25/8/25.
//

import XcodeKit
import PMM_CodeOrganizerCore

final class JSONFormatterCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation,
                 completionHandler: @escaping (Error?) -> Void) {
        defer { completionHandler(nil) }

        guard let lines = invocation.buffer.lines as? [String] else { return }

        // Ejecuta formato/annotación
        let result = JSONFormatter.formatOrAnnotate(lines: lines)

        // Si el resultado es idéntico, no hacemos nada; si no, lo aplicamos
        if result != lines {
            invocation.buffer.lines.setArray(result)
        }
    }
}
