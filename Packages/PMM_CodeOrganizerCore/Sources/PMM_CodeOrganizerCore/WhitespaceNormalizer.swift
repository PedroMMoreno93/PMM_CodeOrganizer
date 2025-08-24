//
//  WhitespaceNormalizer.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum WhitespaceNormalizer {
    /// Reduce cualquier racha de líneas en blanco a 1 sola. No toca líneas no vacías.
    public static func collapseBlankLines(_ lines: [String]) -> [String] {
        var out: [String] = []
        var blanks = 0
        for l in lines {
            if l.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                blanks += 1
                if blanks == 1 { out.append("\n") } // unifica línea en blanco
            } else {
                blanks = 0
                out.append(l)
            }
        }
        // elimina blancos al principio
        while out.first?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            out.removeFirst()
        }
        return out
    }

    /// Asegura que NO haya línea en blanco inmediatamente después de un `// MARK:`
    public static func removeBlankLineAfterMark(_ lines: [String]) -> [String] {
        var out = lines
        var i = 0
        while i < out.count - 1 {
            if out[i].trimmingCharacters(in: .whitespaces).hasPrefix("// MARK:") &&
               out[i+1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                out.remove(at: i+1)
                continue // vuelve a comprobar por si hay más de una
            }
            i += 1
        }
        return out
    }
}
