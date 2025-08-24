//
//  TypeMemberMarker.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum TypeMemberMarker {
    
    // REGEX
    private static let typeDeclRx = try! NSRegularExpression(
        pattern: #"^\s*(public|internal|private|fileprivate)?\s*(final\s+)?(struct|class|actor|enum)\s+\w+"#,
        options: [.anchorsMatchLines]
    )
    private static let constRx = try! NSRegularExpression(
        pattern: #"^\s*(public|internal|private|fileprivate)?\s*(static\s+)?let\s+\w+"#,
        options: [.anchorsMatchLines]
    )
    private static let varRx = try! NSRegularExpression(
        pattern: #"^\s*(public|internal|private|fileprivate)?\s*(static\s+)?var\s+\w+"#,
        options: [.anchorsMatchLines]
    )
    private static let bodyRx = try! NSRegularExpression(
        pattern: #"^\s*(public|internal|private|fileprivate)?\s*(override\s+)?var\s+body\s*:\s*some\s+View\b"#,
        options: [.anchorsMatchLines, .caseInsensitive]
    )
    private static let initRx = try! NSRegularExpression(
        pattern: #"^\s*(public|internal|private|fileprivate)?\s*(required\s+)?(convenience\s+)?init\s*\("#,
        options: [.anchorsMatchLines]
    )
    private static let funcPublicRx = try! NSRegularExpression(
        pattern: #"^\s*(public|open)\s+(override\s+)?(static\s+)?func\b"#,
        options: [.anchorsMatchLines]
    )
    private static let funcPrivateRx = try! NSRegularExpression(
        pattern: #"^\s*(private|fileprivate)\s+(override\s+)?(static\s+)?func\b"#,
        options: [.anchorsMatchLines]
    )
    private static let nestedTypeRx = try! NSRegularExpression(
        pattern: #"^\s*(public|internal|private|fileprivate)?\s*(final\s+)?(struct|class|actor|enum)\s+(\w+)"#,
        options: [.anchorsMatchLines]
    )
    private static let markLineRx = try! NSRegularExpression(
        pattern: #"^\s*//\s*MARK:\s*"#, options: [.anchorsMatchLines, .caseInsensitive]
    )
    
    public static func insertMemberMarks(
        in lines: [String],
        style: MarkStyle = .noDash,
        titles: MarkTitles = .init()
    ) -> [String] {
            var out = lines
            var i = 0
            
            while i < out.count {
                guard matches(typeDeclRx, out[i]) else { i += 1; continue }
                guard let openIdx = findOpenBrace(in: out, startingAt: i) else { i += 1; continue }
                
                var depth = 1
                var j = openIdx + 1
                
                var firstConst: Int?
                var firstVarStored: Int?
                var firstVarComputed: Int?
                var firstInit: Int?
                var firstBody: Int?
                var firstFuncPublic: Int?
                var firstFuncPrivate: Int?
                var nestedTypes: [(idx: Int, name: String)] = []
                
                while j < out.count {
                    // Salta bloques de preprocesador enteros en depth==1
                    if depth == 1, isIfDirective(out[j]) {
                        if let end = findMatchingEndIf(in: out, from: j) {
                            j = end + 1
                            continue
                        }
                    }
                    
                    if depth == 1 {
                        let line = out[j]
                        if matches(bodyRx, line) { firstBody = firstBody ?? j }
                        if matches(initRx, line) { firstInit = firstInit ?? j }
                        if matches(constRx, line) { firstConst = firstConst ?? j }
                        if matches(varRx, line) {
                            if isComputedVar(lines: out, at: j) {
                                firstVarComputed = firstVarComputed ?? j
                            } else {
                                firstVarStored = firstVarStored ?? j
                            }
                        }
                        if matches(funcPublicRx, line) {
                            firstFuncPublic = firstFuncPublic ?? j
                        }
                        if matches(funcPrivateRx, line) {
                            firstFuncPrivate = firstFuncPrivate ?? j
                        }
                        if let m = match(nestedTypeRx, line) {
                            let name = (line as NSString).substring(with: m.range(at: 4))
                            nestedTypes.append((j, name))
                        }
                    }
                    
                    depth += out[j].filter { $0 == "{" }.count
                    depth -= out[j].filter { $0 == "}" }.count
                    if depth == 0 { break }
                    j += 1
                }
                
                let p = style.prefix
                var inserts: [(pos: Int, text: String)] = []
                
                if let idx = firstConst,
                   let pos = safeMarkPosition(in: out, itemIndex: idx, blockOpen: openIdx),
                   !hasMarkBetween(out, from: openIdx+1, to: pos, token: titles.constants) {
                    inserts.append((pos, indentation(of: out[pos]) + p + "\(titles.constants)\n"))
                }
                if let idx = firstVarStored,
                   let pos = safeMarkPosition(in: out, itemIndex: idx, blockOpen: openIdx),
                   !hasMarkBetween(out, from: openIdx+1, to: pos, token: titles.variables) {
                    inserts.append((pos, indentation(of: out[pos]) + p + "\(titles.variables)\n"))
                }
                if let idx = firstVarComputed,
                   let pos = safeMarkPosition(in: out, itemIndex: idx, blockOpen: openIdx),
                   !hasMarkBetween(out, from: openIdx+1, to: pos, token: titles.computed) {
                    inserts.append((pos, indentation(of: out[pos]) + p + "\(titles.computed)\n"))
                }
                if let idx = firstInit,
                   let pos = safeMarkPosition(in: out, itemIndex: idx, blockOpen: openIdx),
                   !hasMarkBetween(out, from: openIdx+1, to: pos, token: titles.initTitle) {
                    inserts.append((pos, indentation(of: out[pos]) + p + "\(titles.initTitle)\n"))
                }
                if let idx = firstBody,
                   let pos = safeMarkPosition(in: out, itemIndex: idx, blockOpen: openIdx),
                   !hasMarkBetween(out, from: openIdx+1, to: pos, token: titles.body) {
                    inserts.append((pos, indentation(of: out[pos]) + p + "\(titles.body)\n"))
                }
                if let idx = firstFuncPublic,
                   let pos = safeMarkPosition(in: out, itemIndex: idx, blockOpen: openIdx),
                   !hasMarkBetween(out, from: openIdx+1, to: pos, token: titles.publicMethods) {
                    inserts.append((pos, indentation(of: out[pos]) + p + "\(titles.publicMethods)\n"))
                }
                if let idx = firstFuncPrivate,
                   let pos = safeMarkPosition(in: out, itemIndex: idx, blockOpen: openIdx),
                   !hasMarkBetween(out, from: openIdx+1, to: pos, token: titles.privateMethods) {
                    inserts.append((pos, indentation(of: out[pos]) + p + "\(titles.privateMethods)\n"))
                }
                for (idx, name) in nestedTypes {
                    if let pos = safeMarkPosition(in: out, itemIndex: idx, blockOpen: openIdx),
                       !hasMarkBetween(out, from: openIdx+1, to: pos, token: name) {
                        let title = titles.nestedPrefix.isEmpty ? name : "\(titles.nestedPrefix) \(name)"
                        inserts.append((pos, indentation(of: out[pos]) + p + "\(title)\n"))
                    }
                }
                
                inserts.sort { $0.pos > $1.pos }
                for ins in inserts {
                    out.insert(ins.text, at: ins.pos)
                }
                
                i = (j + inserts.count) + 1
            }
            return out
        }
    
    // MARK: - Helpers
    
    private static func matches(
        _ rx: NSRegularExpression,
        _ line: String
    ) -> Bool {
        rx.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) != nil
    }
    
    private static func match(
        _ rx: NSRegularExpression,
        _ line: String
    ) -> NSTextCheckingResult? {
        rx.firstMatch(
            in: line,
            range: NSRange(location: 0, length: line.utf16.count)
        )
    }
    
    private static func indentation(
        of line: String
    ) -> String {
        String(line.prefix { $0 == " " || $0 == "\t" })
    }
    
    private static func findOpenBrace(
        in lines: [String],
        startingAt idx: Int
    ) -> Int? {
        var k = idx
        while k < lines.count { if lines[k].contains("{") { return k }; k += 1 }
        return nil
    }
    
    // Inserta el MARK por encima del bloque de atributos @... contiguo (si lo hay)
    private static func safeMarkPosition(
        in lines: [String],
        itemIndex: Int,
        blockOpen: Int
    ) -> Int? {
        var pos = itemIndex
        // sube líneas en blanco
        while pos > blockOpen+1 && lines[pos - 1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pos -= 1
        }
        // sube atributos @... contiguos
        while pos > blockOpen+1 && lines[pos - 1].trimmingCharacters(in: .whitespaces).hasPrefix("@") {
            pos -= 1
        }
        return pos
    }
    
    // Var computada heurística: '{' en la línea o en la siguiente no vacía/comentada
    private static func isComputedVar(
        lines: [String],
        at idx: Int
    ) -> Bool {
        if lines[idx].contains("{") {
            return true
        }
        var k = idx + 1
        
        while k < lines.count {
            let t = lines[k].trimmingCharacters(in: .whitespaces)
            if t.isEmpty || t.hasPrefix("//") {
                k += 1
                continue
            }
            return t.hasPrefix("{") || t.hasPrefix("get") || t.hasPrefix("willSet") || t.hasPrefix("didSet")
        }
        return false
    }
    
    // Preprocesador
    private static func isIfDirective(
        _ line: String
    ) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        return t.hasPrefix("#if") || t.hasPrefix("#elseif") || t.hasPrefix("#else")
    }
    
    private static func findMatchingEndIf(
        in lines: [String],
        from start: Int
    ) -> Int? {
        var level = 0
        var i = start
        while i < lines.count {
            let t = lines[i].trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("#if") {
                level += 1
            } else if t.hasPrefix("#endif") {
                level -= 1
                if level == 0 {
                    return i
                }
            }
            i += 1
        }
        return nil
    }
    
    private static func hasMarkBetween(
        _ lines: [String],
        from: Int,
        to: Int,
        token: String
    ) -> Bool {
        guard from < to else {
            return false
        }
        
        for i in from..<to {
            let l = lines[i]
            if markLineRx.firstMatch(
                in: l,
                range: NSRange(location: 0, length: (l as NSString).length)
            ) != nil,
               l.localizedCaseInsensitiveContains(token) {
                return true
            }
        }
        return false
    }
}

