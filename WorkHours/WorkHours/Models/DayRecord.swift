import Foundation
import SwiftData

@Model
final class DayRecord {
    var day: Int = 1
    var ab: Entry = Entry()
    var bl: Entry = Entry()
    var ht: Entry = Entry()
    var ch: Entry = Entry()
    /// Cached result; the UI always recomputes live through the calculator.
    var totalHours: Double = 0
    var record: MonthRecord?

    init(day: Int) { self.day = day }

    var input: DayInput { DayInput(ab: ab, bl: bl, ht: ht, ch: ch) }
    var hasData: Bool { !(ab.isEmpty && bl.isEmpty && ht.isEmpty && ch.isEmpty) }

    func entry(for column: WorkColumn) -> Entry {
        switch column {
        case .ab: return ab
        case .bl: return bl
        case .ht: return ht
        case .ch: return ch
        }
    }

    func setEntry(_ entry: Entry, for column: WorkColumn, calculator: WorkHoursCalculator) {
        switch column {
        case .ab: ab = entry
        case .bl: bl = entry
        case .ht: ht = entry
        case .ch: ch = entry
        }
        totalHours = calculator.dailyHours(input)
    }
}
