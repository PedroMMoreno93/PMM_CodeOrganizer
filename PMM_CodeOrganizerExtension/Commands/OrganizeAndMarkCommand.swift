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

    struct Prefs: Decodable {
        var sortImports: Bool
        var insertMarks: Bool
    }

    
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
        if prefs.sortImports {
            working = ImportSorter.sortAndHoistAllImports(in: working)
        }
        if prefs.insertMarks {
            working = MarkInserter.insertImportsMark(in: working)
        }
        
        invocation.buffer.lines.removeAllObjects()
        working.forEach { invocation.buffer.lines.add($0) }
    }
    
    private func loadPrefs() -> Prefs {
        let ud = UserDefaults(suiteName: suite)
        if let data = ud?.data(forKey: key),
           let decoded = try? JSONDecoder().decode(OrganizerPrefs.self, from: data) {
            return Prefs(sortImports: decoded.sortImports, insertMarks: decoded.insertMarks)
        }
        return Prefs(sortImports: true, insertMarks: true)
    }
    
}
