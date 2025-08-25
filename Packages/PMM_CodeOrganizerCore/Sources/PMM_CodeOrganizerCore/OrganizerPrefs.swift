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
/*
 public struct OrganizerPrefs: Codable, Equatable {

     public var maxFunctionLines: Int = 80
     public var maxTypeLines: Int = 400

     // 👇 para el motor de sugerencias
     public var maxFileLines: Int = 1200
     public var maxTopLevelTypes: Int = 2
     public var maxParamsPerFunc: Int = 5
     public var maxComplexityTokens: Int = 12

     public var markStyle: MarkStyle = .noDash
     public var titles = MarkTitles()

     public init() {}
 }

 */
public struct OrganizerPrefs: Codable, Equatable {
    public var sortImports: Bool = true
    public var insertMarks: Bool = true
    public var reorderMembers: Bool = true
    public var reorderTopLevel: Bool = true
    
    public var maxFunctionLines: Int
    public var maxTypeLines: Int
    
    public var maxFileLines: Int = 1200
    public var maxTopLevelTypes: Int = 2
    public var maxParamsPerFunc: Int = 5
    public var maxComplexityTokens: Int = 12
    
    public var markStyle: MarkStyle = .noDash
    public var titles = MarkTitles()
    
    public init(
        sortImports: Bool = true,
        insertMarks: Bool = true,
        reorderMembers: Bool = true,
        reorderTopLevel: Bool = true,
        maxFunctionLines: Int = 80,
        maxTypeLines: Int = 400,
        maxFileLines: Int = 1200,
        maxTopLevelTypes: Int = 2,
        maxParamsPerFunc: Int = 5,
        maxComplexityTokens: Int = 12,
        markStyle: MarkStyle = .noDash,
        titles: MarkTitles = MarkTitles()
    ) {
        self.sortImports = sortImports
        self.insertMarks = insertMarks
        self.reorderMembers = reorderMembers
        self.reorderTopLevel = reorderTopLevel
        self.maxFunctionLines = maxFunctionLines
        self.maxTypeLines = maxTypeLines
        self.maxFileLines = maxFileLines
        self.maxTopLevelTypes = maxTopLevelTypes
        self.maxParamsPerFunc = maxParamsPerFunc
        self.maxComplexityTokens = maxComplexityTokens
        self.markStyle = markStyle
        self.titles = titles
    }
}

public struct MarkTitles: Codable, Equatable {
    public var imports: String
    public var constants: String
    public var variables: String
    public var computed: String
    public var initTitle: String
    public var body: String
    public var publicMethods: String
    public var privateMethods: String
    public var nestedPrefix: String
    public var funcs: String                 // 👈 para extensiones

    public init(
        imports: String = "Imports",
        constants: String = "Constants",
        variables: String = "Variables",
        computed: String = "Computed Properties",
        initTitle: String = "Init",
        body: String = "Body",
        publicMethods: String = "Public Funcs",
        privateMethods: String = "Private Funcs",
        nestedPrefix: String = "",
        funcs: String = "Funcs"
    ) {
        self.imports = imports
        self.constants = constants
        self.variables = variables
        self.computed = computed
        self.initTitle = initTitle
        self.body = body
        self.publicMethods = publicMethods
        self.privateMethods = privateMethods
        self.nestedPrefix = nestedPrefix
        self.funcs = funcs
    }
}
