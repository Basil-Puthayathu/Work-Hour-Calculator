import Foundation

enum WorkColumn: String, CaseIterable, Identifiable, Codable {
    case ab = "AB", bl = "BL", ht = "HT", ch = "CH"
    var id: String { rawValue }
    var title: String { rawValue }
}

enum EntryKind: String, Codable, CaseIterable, Identifiable {
    case empty, number, check, free, krank
    var id: String { rawValue }
    var label: String {
        switch self {
        case .empty: return "Empty"
        case .number: return "Number"
        case .check: return "Check"
        case .free: return "Free"
        case .krank: return "Krank"
        }
    }
}

/// What the user typed/picked for one cell (AB, BL, HT or CH on one day).
struct Entry: Codable, Equatable, Hashable {
    var kind: EntryKind = .empty
    var value: Double = 0

    static let empty = Entry()
    static let check = Entry(kind: .check)
    static let free = Entry(kind: .free)
    static let krank = Entry(kind: .krank)
    static func number(_ v: Double) -> Entry { Entry(kind: .number, value: v) }

    var isEmpty: Bool { kind == .empty }
    /// Only real numbers feed the formula and the column totals.
    var numericValue: Double { kind == .number ? value : 0 }

    /// Shown in the UI. Always full words, never "F" / "K" / "C".
    var displayText: String {
        switch kind {
        case .empty: return "–"
        case .number: return value.formatted(.number.precision(.fractionLength(0...2)))
        case .check: return "Check"
        case .free: return "Free"
        case .krank: return "Krank"
        }
    }

    /// Locale-independent text for exports.
    var plainText: String {
        switch kind {
        case .empty: return ""
        case .number: return Entry.plain(value)
        case .check: return "Check"
        case .free: return "Free"
        case .krank: return "Krank"
        }
    }

    static func plain(_ v: Double) -> String {
        let r = (v * 10000).rounded() / 10000
        var s = String(r)
        if s.hasSuffix(".0") { s.removeLast(2) }
        return s
    }

    /// Accepts "3", "3.5", "3,5". Rejects letters, negatives, absurd values.
    static func parse(_ text: String) -> Double? {
        let t = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !t.isEmpty,
              t.allSatisfy({ ($0 >= "0" && $0 <= "9") || $0 == "." }),
              t.filter({ $0 == "." }).count <= 1,
              let v = Double(t), v.isFinite, v >= 0, v <= 1000 else { return nil }
        return v
    }
}
