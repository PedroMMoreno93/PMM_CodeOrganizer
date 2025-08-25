//
//  TopLevelSorter.swift
//  PMM_CodeOrganizerCore
//
//  Created by Pedro M Moreno on 25/8/25.
//

import Foundation
import Foundation

public enum TopLevelSorter {
    private static let importRx     = try! NSRegularExpression(pattern: #"^\s*(@testable\s+)?import\s+\w+"#, options: [.anchorsMatchLines])
    private static let markImports  = try! NSRegularExpression(pattern: #"^\s*//\s*MARK:\s*.*Imports\b"#, options: [.anchorsMatchLines, .caseInsensitive])
    private static let protoRx      = try! NSRegularExpression(pattern: #"^\s*(public|internal|private|fileprivate)?\s*protocol\s+\w+"#, options: [.anchorsMatchLines])
    private static let enumRx       = try! NSRegularExpression(pattern: #"^\s*(public|internal|private|fileprivate)?\s*enum\s+\w+"#, options: [.anchorsMatchLines])
    private static let classRx      = try! NSRegularExpression(pattern: #"^\s*(public|internal|private|fileprivate)?\s*(final\s+)?class\s+\w+"#, options: [.anchorsMatchLines])
    private static let actorRx      = try! NSRegularExpression(pattern: #"^\s*(public|internal|private|fileprivate)?\s*actor\s+\w+"#, options: [.anchorsMatchLines])
    private static let structRx     = try! NSRegularExpression(pattern: #"^\s*(public|internal|private|fileprivate)?\s*struct\s+\w+"#, options: [.anchorsMatchLines])
    private static let extensionRx  = try! NSRegularExpression(pattern: #"^\s*extension\s+\w+"#, options: [.anchorsMatchLines])

    private enum Kind { case proto, enm, cls, act, strct, ext, other }

    /// Ordena: protocols → enums → classes → actors → structs → others → extensions.
    /// Conserva cabecera e imports (incl. MARK) tal cual; espacios limpios.
    public static func sortTopLevel(in lines: [String]) -> [String] {
        let importRegionEnd = indexAfterImports(in: lines)
        var prefix = Array(lines.prefix(importRegionEnd))
        let body   = Array(lines.suffix(from: importRegionEnd))

        let blocks = sliceTopLevelBlocks(in: body)

        var protos: [[String]] = [], enms: [[String]] = [], clss: [[String]] = []
        var acts: [[String]] = [], strs: [[String]] = [], exts: [[String]] = [], others: [[String]] = []

        for b in blocks {
            switch classify(block: b) {
            case .proto: protos.append(b)
            case .enm:   enms.append(b)
            case .cls:   clss.append(b)
            case .act:   acts.append(b)
            case .strct: strs.append(b)
            case .ext:   exts.append(b)
            case .other: others.append(b)
            }
        }

        var out: [String] = []
        func appendBlocks(_ arr: [[String]]) {
            for block in arr {
                if !out.isEmpty, !out.last!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    out.append("\n")
                }
                out.append(contentsOf: block)
                if let last = out.last, !last.hasSuffix("\n") { out[out.count-1] = last + "\n" }
            }
        }

        appendBlocks(protos)
        appendBlocks(enms)
        appendBlocks(clss)
        appendBlocks(acts)
        appendBlocks(strs)
        appendBlocks(others)
        appendBlocks(exts)

        prefix.append(contentsOf: out)
        return prefix
    }

    // MARK: - Helpers

    private static func indexAfterImports(in lines: [String]) -> Int {
        guard let firstImport = lines.firstIndex(where: { matches(importRx, $0) }) else { return 0 }
        var start = firstImport
        var k = firstImport - 1
        while k >= 0, lines[k].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { k -= 1 }
        if k >= 0, matches(markImports, lines[k]) { start = k }

        var end = firstImport
        var i = firstImport + 1
        while i < lines.count, matches(importRx, lines[i]) { end = i; i += 1 }

        var after = end + 1
        while after < lines.count, lines[after].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { after += 1 }
        return after
    }

    private static func sliceTopLevelBlocks(in body: [String]) -> [[String]] {
        var res: [[String]] = []
        var curr: [String] = []
        var depth = 0

        func flush() {
            while curr.first?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true { curr.removeFirst() }
            while curr.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true { curr.removeLast() }
            if !curr.isEmpty { res.append(curr) }
            curr.removeAll()
        }

        for line in body {
            if depth == 0, matches(protoRx, line) || matches(enumRx, line) || matches(classRx, line) || matches(actorRx, line) || matches(structRx, line) || matches(extensionRx, line) {
                flush()
                curr.append(line)
            } else {
                curr.append(line)
            }
            depth += line.filter { $0 == "{" }.count
            depth -= line.filter { $0 == "}" }.count
        }
        flush()
        return res
    }

    private static func classify(block: [String]) -> Kind {
        guard let first = block.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { return .other }
        if matches(protoRx, first)     { return .proto }
        if matches(enumRx, first)      { return .enm }
        if matches(classRx, first)     { return .cls }
        if matches(actorRx, first)     { return .act }
        if matches(structRx, first)    { return .strct }
        if matches(extensionRx, first) { return .ext }
        return .other
    }

    private static func matches(_ rx: NSRegularExpression, _ line: String) -> Bool {
        rx.firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length)) != nil
    }
}
