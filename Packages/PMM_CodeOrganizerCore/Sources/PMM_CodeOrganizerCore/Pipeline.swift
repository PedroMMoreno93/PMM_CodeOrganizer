//
//  Pipeline.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum Pipeline {
    public static func run(lines: [String], prefs: OrganizerPrefs) -> [String] {
        var work = lines

        // 1) Imports
        if prefs.sortImports {
            work = ImportSorter.hoistAndSortImports(in: work) // NO añade MARK
        }
        if prefs.insertMarks {
            work = MarkInserter.ensureSingleImportsMark(in: work,
                                                        title: prefs.titles.imports,
                                                        style: prefs.markStyle)
        }

        // 2) Expandir tipos de una línea
        work = TypeBodyExpander.expandOneLineTypeBodies(in: work)

        // 3) Reordenar + marcar miembros
        if prefs.reorderMembers {
            work = TypeMemberOrganizer.reorderAndMark(in: work,
                                                      style: prefs.markStyle,
                                                      titles: prefs.titles)
        } else if prefs.insertMarks {
            work = TypeMemberMarker.insertMemberMarks(in: work,
                                                      style: prefs.markStyle,
                                                      titles: prefs.titles)
        }

        // 4) Ordenación top-level
        if prefs.reorderTopLevel {
            work = TopLevelSorter.sortTopLevel(in: work)
        }

        // 5) Marcar extensiones top-level
        if prefs.insertMarks {
            work = TopLevelMarker.insertExtensionMarks(in: work, style: prefs.markStyle)
        }

        // 6) Normalización de espacios
        work = WhitespaceNormalizer.removeBlankLineAfterMark(work)
        work = WhitespaceNormalizer.collapseBlankLines(work)

        return work
    }
}
