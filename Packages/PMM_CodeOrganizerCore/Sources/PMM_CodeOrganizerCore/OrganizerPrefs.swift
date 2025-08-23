//
//  OrganizerPrefs.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//
import Foundation

public struct OrganizerPrefs: Codable {
    public var sortImports: Bool
    public var insertMarks: Bool
    public var reorderMembers: Bool
    public var reorderTopLevel: Bool
    public var maxFunctionLines: Int
    public var maxTypeLines: Int
    
    public init(
        sortImports: Bool = true,
        insertMarks: Bool = true,
        reorderMembers: Bool = false,
        reorderTopLevel: Bool = false,
        maxFunctionLines: Int = 80,
        maxTypeLines: Int = 400
    ) {
        self.sortImports = sortImports
        self.insertMarks = insertMarks
        self.reorderMembers = reorderMembers
        self.reorderTopLevel = reorderTopLevel
        self.maxFunctionLines = maxFunctionLines
        self.maxTypeLines = maxTypeLines
    }
}
