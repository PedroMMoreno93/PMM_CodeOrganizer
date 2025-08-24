//
//  TypeMemberOrganizer.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum TypeMemberOrganizer {

    private enum MemberKind {
        case constant
        case storedVar
        case initK
        case computedVar
        case bodyProp
        case funcPublic
        case funcPrivate
        case funcOther
        case otherBlock
    }

    private static let typeDeclRx = try! NSRegularExpression(
        pattern: #"^\s*(public|internal|private|fileprivate)?\s*(final\s+)?(struct|class|actor|enum)\s+\w+"#,
        options: [.anchorsMatchLines]
    )
    
    private static let extensionRx = try! NSRegularExpression(
        pattern: #"^\s*extension\s+(\w+)\b"#, options: [.anchorsMatchLines]
    )
    
    private static let constRx = try! NSRegularExpression(
        pattern: #"^\s*(public|internal|private|fileprivate)?\s*(static\s+)?let\s+\w+"#, options: [.anchorsMatchLines]
    )
    
    private static let varRx = try! NSRegularExpression(
        pattern: #"^\s*(public|internal|private|fileprivate)?\s*(static\s+)?var\s+\w+"#, options: [.anchorsMatchLines]
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
    
    private static let funcAnyRx = try! NSRegularExpression(
        pattern: #"^\s*(public|internal|private|fileprivate|open)?\s*(override\s+)?(static\s+)?func\b"#,
        options: [.anchorsMatchLines]
    )
    
    private static let markLineRx = try! NSRegularExpression(
        pattern: #"^\s*//\s*MARK:"#,
        options: [.anchorsMatchLines, .caseInsensitive]
    )

    public static func reorderAndMark(
        in lines: [String],
        style: MarkStyle,
        titles: MarkTitles
    ) -> [String] {
        var out = lines
        var i = 0
        while i < out.count {
            let line = out[i]
            let isType = match(typeDeclRx, line) != nil
            let isExt  = match(extensionRx, line) != nil
            
            guard isType || isExt
            else {
                i += 1
                continue
            }

            guard let openIdx = findOpenBrace(in: out, startingAt: i),
                  let closeIdx = findMatchingClose(in: out, openIndex: openIdx)
            else {
                i += 1
                continue
            }

            // extrae miembros de depth==1 (ignorando MARKs y líneas en blanco sueltas)
            let body = Array(out[(openIdx+1)..<closeIdx])
            let members = sliceMembers(in: body)

            // Clasifica y reordena
            let groups = groupMembers(members, isExtension: isExt)
            let rebuiltBody = rebuildBody(
                groups: groups,
                originalBody: body,
                style: style,
                titles: titles,
                afterOpenBraceIndent: indentation(of: out[openIdx]) + "    "
            )

            // Reensambla: header + "{" + cuerpo reordenado + "}"
            var newBlock: [String] = []
            newBlock.append(contentsOf: out[i...openIdx])                  // header + "{"
            newBlock.append(contentsOf: rebuiltBody)
            newBlock.append(indentation(of: out[closeIdx]) + "}\n")

            // Sustituye en 'out'
            out.replaceSubrange(i...(closeIdx), with: newBlock)
            i += newBlock.count
        }
        return out
    }

    // MARK: - Parseado de miembros

    private struct Range { let start: Int; let end: Int; let kind: MemberKind }

    private static func sliceMembers(in body: [String]) -> [Range] {
        var res: [Range] = []
        var idx = 0
        var depth = 0
        while idx < body.count {
            let line = body[idx]
            // Salta MARKs y líneas en blanco (no se conservan, normalizamos)
            if matches(markLineRx, line) || line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                idx += 1; continue
            }
            // Bloques #if … #endif como "otherBlock" entero
            if isIfDirective(line) {
                if let endIf = findMatchingEndIf(in: body, from: idx) {
                    res.append(Range(start: idx, end: endIf, kind: .otherBlock))
                    idx = endIf + 1; continue
                }
            }
            // Atributos @… pegados a la declaración
            var start = idx
            while start > 0 && body[start-1].trimmingCharacters(in: .whitespaces).hasPrefix("@") {
                start -= 1
            }

            // Identifica kind y rango
            let kind = classify(line: line, body: body, index: idx)
            let end = findMemberEnd(in: body, from: idx)
            res.append(Range(start: start, end: end, kind: kind))
            idx = end + 1
        }
        return res
    }

    private static func classify(
        line: String,
        body: [String],
        index: Int
    ) -> MemberKind {
        if matches(bodyRx, line) {
            return .bodyProp
        }
        if matches(initRx, line) {
            return .initK
        }
        if matches(constRx, line) {
            return .constant
        }
        if matches(varRx, line) {
            return isComputedVar(
                lines: body,
                at: index
            ) ? .computedVar : .storedVar
        }
        if matches(funcPublicRx, line) {
            return .funcPublic
        }
        if matches(funcPrivateRx, line) {
            return .funcPrivate
        }
        if matches(funcAnyRx, line) {
            return .funcOther
        }
        return .otherBlock
    }

    // end de un miembro: si abre '{', balancea; si no, 1 línea
    private static func findMemberEnd(
        in body: [String],
        from idx: Int
    ) -> Int {
        var i = idx
        var local = 0
        var sawBrace = false
        while i < body.count {
            let opens = body[i].filter { $0 == "{" }.count
            let closes = body[i].filter { $0 == "}" }.count
            local += opens
            local -= closes
            if opens > 0 {
                sawBrace = true
            }
            if sawBrace && local == 0 {
                return i
            }
            if !sawBrace {
                // stored var / una sola línea
                return i
            }
            i += 1
        }
        return idx
    }

    // MARK: - Agrupado y reconstrucción

    private static func groupMembers(
        _ members: [Range],
        isExtension: Bool
    ) -> [(title: String, items: [Range])] {
        // Filtra MARKs y vacíos (ya lo hicimos), agrupamos por tipo
        var constants: [Range] = []
        var stored: [Range] = []
        var inits: [Range] = []
        var computed: [Range] = []
        var bodyProp: [Range] = []
        var fPub: [Range] = []
        var fPriv: [Range] = []
        var fOther: [Range] = []
        var others: [Range] = []

        for r in members {
            switch r.kind {
            case .constant: constants.append(r)
            case .storedVar: stored.append(r)
            case .initK: inits.append(r)
            case .computedVar: computed.append(r)
            case .bodyProp: bodyProp.append(r)
            case .funcPublic: fPub.append(r)
            case .funcPrivate: fPriv.append(r)
            case .funcOther: fOther.append(r)
            case .otherBlock: others.append(r)
            }
        }

        if isExtension {
            // En extensión: Computed Properties → Funcs (todas), y dejamos otros bloques tal cual detrás
            let funcs = fPub + fPriv + fOther
               var groups: [(String, [Range])] = []
               if !computed.isEmpty || !bodyProp.isEmpty { groups.append( ("__COMP__", computed + bodyProp) ) } // 👈 clave unificada
               if !funcs.isEmpty { groups.append( ("__FUNCS__", funcs) ) }
               if !others.isEmpty { groups.append( ("__OTHERS__", others) ) }
               return groups
            return groups
        } else {
            // En tipo: Constants → Variables → Init → Computed Properties → Public Funcs → Private Funcs → Others
            var groups: [(String, [Range])] = []
            if !constants.isEmpty { groups.append(("__CONST__", constants)) }
            if !stored.isEmpty { groups.append(("__VARS__", stored)) }
            if !inits.isEmpty { groups.append(("__INIT__", inits)) }
            if !computed.isEmpty || !bodyProp.isEmpty { groups.append(("__COMP__", computed + bodyProp)) }
            if !fPub.isEmpty { groups.append(("__FPUB__", fPub)) }
            if !fPriv.isEmpty { groups.append(("__FPRIV__", fPriv)) }
            let rest = fOther + others
            if !rest.isEmpty { groups.append(("__OTHERS__", rest)) }
            return groups
        }
    }

    private static func rebuildBody(
        groups: [(title: String, items: [Range])],
        originalBody: [String],
        style: MarkStyle,
        titles: MarkTitles,
        afterOpenBraceIndent: String
    ) -> [String] {
        var out: [String] = []
        let mark = {
            (t: String, indent: String) in indent + style.prefix + t + "\n"
        }

        for (idx, g) in groups.enumerated() {
            // salto de línea ANTES del MARK salvo si es el primer grupo (para que quede pegado al "{")
            if idx > 0 {
                out.append("\n")
            }

            let title: String = {
                switch g.title {
                case "__CONST__":
                    return titles.constants
                case "__VARS__":
                    return titles.variables
                case "__INIT__":
                    return titles.initTitle
                case "__COMP__":
                    return titles.computed
                case "__FPUB__":
                    return titles.publicMethods
                case "__FPRIV__":
                    return titles.privateMethods
                case "__FUNCS__":
                    return titles.funcs
                default:
                    return titles.nestedPrefix.isEmpty ? "Section" : titles.nestedPrefix
                }
            }()

            // Indentar el MARK con la indentación del primer item del grupo
            let firstLine = originalBody[g.items[0].start]
            let indent = indentation(of: firstLine).isEmpty ? afterOpenBraceIndent : indentation(of: firstLine)
            out.append(mark(title, indent))

            // El contenido VA PEGADO al MARK (sin línea en blanco entremedias)
            for r in g.items {
                let chunk = originalBody[r.start...r.end]
                out.append(contentsOf: chunk)
                // NO añadimos líneas en blanco entre elementos; respetamos lo que traen
            }
        }
        return out
    }

    // MARK: - Helpers
    private static func matches(
        _ rx: NSRegularExpression,
        _ line: String
    ) -> Bool {
        rx.firstMatch(
            in: line,
            range: NSRange(location: 0, length: (line as NSString).length)
        ) != nil
    }
    
    private static func match(
        _ rx: NSRegularExpression,
        _ line: String
    ) -> NSTextCheckingResult? {
        rx.firstMatch(
            in: line,
            range: NSRange(location: 0, length: (line as NSString).length)
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
        while k < lines.count {
            if lines[k].contains("{") {
                return k
            }
            k += 1
        }
        return nil
    }
    
    private static func findMatchingClose(
        in lines: [String],
        openIndex: Int
    ) -> Int? {
        var d = 1, i = openIndex + 1
        while i < lines.count {
            d += lines[i].filter { $0 == "{" }.count
            d -= lines[i].filter { $0 == "}" }.count
            if d == 0 {
                return i
            }
            i += 1
        }
        return nil
    }
    
    private static func isIfDirective(
        _ line: String
    ) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        return t.hasPrefix("#if") || t.hasPrefix("#elseif") || t.hasPrefix("#else")
    }
    
    private static func findMatchingEndIf(in lines: [String], from start: Int) -> Int? {
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
}
