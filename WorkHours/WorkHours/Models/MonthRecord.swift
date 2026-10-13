import Foundation
import SwiftData

@Model
final class MonthRecord {
    var id: UUID = UUID()
    /// "2026-10" – one record per year/month, enforced by the store.
    @Attribute(.unique) var key: String = ""
    var month: Int = 1
    var year: Int = 2026
    var employeeName: String = ""
    var department: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \DayRecord.record)
    var days: [DayRecord] = []

    init(month: Int, year: Int, employeeName: String = "", department: String = "") {
        self.key = MonthRecord.makeKey(year: year, month: month)
        self.month = month
        self.year = year
        self.employeeName = employeeName
        self.department = department
    }

    static func makeKey(year: Int, month: Int) -> String {
        String(format: "%04d-%02d", year, month)
    }

    var monthName: String { DateHelper.monthNames[month - 1] }
    var sortedDays: [DayRecord] { days.sorted { $0.day < $1.day } }
    var hasData: Bool { days.contains { $0.hasData } }

    /// Only ever ADDS missing days. Never removes anything.
    func ensureDays(count: Int) {
        let existing = Set(days.map(\.day))
        for d in 1...max(count, 1) where !existing.contains(d) {
            days.append(DayRecord(day: d))
        }
    }
}
