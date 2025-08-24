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
//
//    struct Prefs: Decodable {
//        var sortImports: Bool
//        var insertMarks: Bool
//    }
//
//    
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

        // 1) Imports
        if prefs.sortImports {
            working = ImportSorter.hoistAndSortImports(in: working) // no añade MARK
        }
        if prefs.insertMarks {
            working = MarkInserter.ensureSingleImportsMark(in: working,
                                                           title: prefs.titles.imports,
                                                           style: prefs.markStyle)
        }

        // 2) Expandir tipos de una línea
        working = TypeBodyExpander.expandOneLineTypeBodies(in: working)

        // 3) Reordenar + marcar miembros dentro de tipos/extensiones
        if prefs.reorderMembers {
            working = TypeMemberOrganizer.reorderAndMark(in: working,
                                                         style: prefs.markStyle,
                                                         titles: prefs.titles)
        } else if prefs.insertMarks {
            working = TypeMemberMarker.insertMemberMarks(in: working,
                                                         style: prefs.markStyle,
                                                         titles: prefs.titles)
        }

        // 4) Reordenado top-level: extensiones al final
        if prefs.reorderTopLevel {
            working = TopLevelReorderer.moveExtensionsToBottom(in: working)
        }

        // 5) MARK de cada extension
        if prefs.insertMarks {
            working = TopLevelMarker.insertExtensionMarks(in: working, style: prefs.markStyle)
        }

        // 6) Normalizar espacios (clave para tu caso)
        working = WhitespaceNormalizer.removeBlankLineAfterMark(working)
        working = WhitespaceNormalizer.collapseBlankLines(working)

        invocation.buffer.lines.setArray(working)
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
