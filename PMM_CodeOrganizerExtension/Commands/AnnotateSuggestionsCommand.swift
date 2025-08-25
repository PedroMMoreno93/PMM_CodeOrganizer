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
    private let suite = "group.com.tu.dominio.pmm-codeorganizer"
    private let key = "prefs"

    func perform(with invocation: XCSourceEditorCommandInvocation,
                 completionHandler: @escaping (Error?) -> Void) {
        defer { completionHandler(nil) }
        guard let input = invocation.buffer.lines as? [String] else { return }

        let prefs = loadPrefs()

        // No alteramos estructura; solo analizamos y anotamos
        let sugs = SuggestionsEngine.analyze(lines: input, prefs: prefs)
        let out  = SuggestionsEngine.apply(suggestions: sugs, on: input)

        invocation.buffer.lines.setArray(out)
    }

    private func loadPrefs() -> OrganizerPrefs {
        let ud = UserDefaults(suiteName: suite)
        if let data = ud?.data(forKey: key),
           let decoded = try? JSONDecoder().decode(OrganizerPrefs.self, from: data) {
            return decoded
        }
        return OrganizerPrefs()
    }
}
