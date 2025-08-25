//
//  Suggestion.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum SuggestionSeverity: String {
    case info = "Info"
    case warning = "Warning"
}

public enum SuggestionCategory: String {
    case imports
    case longFunc
    case longType
    case tooManyTopLevel
    case extensionStoredProp
    case manyParams
    case highComplexity
    case longFile
}

public struct Suggestion {
    public let line: Int         
    public let message: String
    public let severity: SuggestionSeverity
    public let category: SuggestionCategory
    
    public init(
        line: Int,
        message: String,
        severity: SuggestionSeverity,
        category: SuggestionCategory
    ) {
        self.line = line; self.message = message; self.severity = severity; self.category = category
    }
}
