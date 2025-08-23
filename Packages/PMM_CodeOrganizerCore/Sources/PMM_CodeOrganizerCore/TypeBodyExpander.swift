//
//  TypeBodyExpander.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum TypeBodyExpander {
    // Convierte: `struct A { let x = 0 }` -> `struct A {\n    let x = 0\n}`
    public static func expandOneLineTypeBodies(in lines: [String]) -> [String] {
        // Regex: tipo con { ... } y contenido dentro en la MISMA línea
        let rx = try! NSRegularExpression(
            pattern: #"^(\s*(?:public|internal|private|fileprivate)?\s*(?:final\s+)?(?:struct|class|actor|enum)\s+[^\{]*)\{\s*([^}]*)\s*\}\s*$"#,
            options: [.anchorsMatchLines]
        )
        var out: [String] = []
        for line in lines {
            let ns = line as NSString
            let range = NSRange(location: 0, length: ns.length)
            if let m = rx.firstMatch(in: line, range: range) {
                let prefix = ns.substring(with: m.range(at: 1))
                let inside = ns.substring(with: m.range(at: 2)).trimmingCharacters(in: .whitespaces)
                // indent = espacios/tabs del principio del prefix
                let indent = String(prefix.prefix { $0 == " " || $0 == "\t" })
                // separa por ';' si hubiera varias sentencias
                let parts = inside.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                out.append(prefix + "{\n")
                for p in parts {
                    out.append(indent + "    " + p + "\n")
                }
                out.append(indent + "}\n")
            } else {
                out.append(line)
            }
        }
        return out
    }
}
