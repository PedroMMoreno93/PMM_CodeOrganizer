//
//  OrganizerPrefs.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//
import Foundation

public enum MarkStyle: String, Codable { case noDash, withDash
    var prefix: String { self == .withDash ? "// MARK: - " : "// MARK: " }
}

public struct OrganizerPrefs: Codable, Equatable {
    public var sortImports: Bool = true
    public var insertMarks: Bool = true
    public var reorderMembers: Bool = false
    public var reorderTopLevel: Bool = false
    public var maxFunctionLines: Int = 80
    public var maxTypeLines: Int = 400
    public var markStyle: MarkStyle = .noDash
    public var titles = MarkTitles()           // 👈 custom titles

    public init() {}
}

public struct MarkTitles: Codable, Equatable {
    public var imports = "Imports"
    public var constants = "Constants"
    public var variables = "Variables"
    public var computed = "Computed"
    public var `initTitle` = "Init"
    public var body = "Body"
    public var publicMethods = "Public Methods"
    public var privateMethods = "Private Methods"
    public var nestedPrefix = ""               // i.e. "" → “// MARK: FooType”
}
