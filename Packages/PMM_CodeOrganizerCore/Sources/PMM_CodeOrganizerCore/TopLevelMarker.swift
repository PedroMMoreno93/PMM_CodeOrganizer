//
//  TopLevelMarker.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum TopLevelMarker {
    private static let extensionRx = try! NSRegularExpression(
          pattern: #"^\s*extension\s+(\w+)(\s*:\s*[^ {]+)?"#, options: [.anchorsMatchLines]
      )
    
    public static func insertExtensionMarks(in lines: [String], style: MarkStyle = .noDash) -> [String] {
        var out = lines
        var i = 0
        while i < out.count {
            let l = out[i]
            guard let m = extensionRx.firstMatch(in: l, range: NSRange(location: 0, length: (l as NSString).length)) else {
                i += 1; continue
            }
            // ¿ya hay MARK justo encima (ignorando blancos)?
            var look = i - 1
            while look >= 0, out[look].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { look -= 1 }
            let hasMarkAbove = look >= 0 && out[look].contains("// MARK:")
            if !hasMarkAbove {
                let ns = l as NSString
                let typeName = ns.substring(with: m.range(at: 1))
                let proto = (m.range(at: 2).location != NSNotFound) ? ns.substring(with: m.range(at: 2)).trimmingCharacters(in: .whitespaces) : ""
                let title = proto.isEmpty ? "Extension \(typeName)" : "Extension \(typeName) \(proto)"
                // exactamente UNA línea en blanco antes del MARK (si no es principio)
                if i > 0, out[i-1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    out.insert("\n", at: i)
                    i += 1
                }
                out.insert(style.prefix + title + "\n", at: i)
                // no insertamos blanco entre el MARK y la 'extension'
                i += 1
            }
            i += 1
        }
        return out
    }
    
    private static func indentation(
        of line: String
    ) -> String {
        String(line.prefix { $0 == " " || $0 == "\t" })
    }
}
