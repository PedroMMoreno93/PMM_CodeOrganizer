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
        // 1) Imports: junta y ordena (sin MARK)
        if prefs.sortImports {
            working = ImportSorter.hoistAndSortImports(in: working)
        }
        // 2) Asegura un único MARK de Imports
        if prefs.insertMarks {
            working = MarkInserter.ensureSingleImportsMark(in: working)
        }
        // 3) Formato mínimo: expandir tipos de una línea
        working = TypeBodyExpander.expandOneLineTypeBodies(in: working)
        // 4) MARCAR constantes dentro de tipos
        if prefs.insertMarks {
            working = TypeMemberMarker.insertConstantsMark(in: working)
        }
        invocation.buffer.lines.removeAllObjects()
        invocation.buffer.lines.setArray(working)
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
