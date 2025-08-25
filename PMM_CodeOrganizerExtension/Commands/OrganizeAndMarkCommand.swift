//
//  OrganizeAndMarkCommand.swift
//  PMM_CodeOrganizerExtension
//
//  Created by Pedro M Moreno.
//

// MARK: - Imports
import Foundation
import PMM_CodeOrganizerCore
import XcodeKit

final class OrganizeAndMarkCommand: NSObject, XCSourceEditorCommand {
    private let suite = "com.pedrommoreno.CodeOrganizer"
    private let key = "prefs"

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
        
        let prefs = loadPrefs()
        
        var working = lines

        let out = Pipeline.run(lines: lines, prefs: prefs)
        invocation.buffer.lines.setArray(out)
    }
    
    private func loadPrefs() -> OrganizerPrefs {
        let ud = UserDefaults(suiteName: suite)
        if let data = ud?.data(forKey: key),
           let decoded = try? JSONDecoder().decode(OrganizerPrefs.self, from: data) {
            return decoded
        }
        return OrganizerPrefs(sortImports: true, insertMarks: true)
    }
    
}
