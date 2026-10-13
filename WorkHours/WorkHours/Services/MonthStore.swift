import Foundation
import SwiftData

enum AppSettings {
    static let fixed30Key = "fixed30Days"
    static let employeeKey = "defaultEmployee"
    static let departmentKey = "defaultDepartment"
}

enum MonthStore {
    /// Returns the saved record, or creates an empty one. Never overwrites.
    @MainActor
    static func openOrCreate(month: Int, year: Int, context: ModelContext) throws -> MonthRecord {
        let key = MonthRecord.makeKey(year: year, month: month)
        var descriptor = FetchDescriptor<MonthRecord>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first { return existing }

        let defaults = UserDefaults.standard
        let record = MonthRecord(
            month: month, year: year,
            employeeName: defaults.string(forKey: AppSettings.employeeKey) ?? "",
            department: defaults.string(forKey: AppSettings.departmentKey) ?? "")
        record.ensureDays(count: DateHelper.daysInMonth(year: year, month: month))
        context.insert(record)
        try context.save()
        return record
    }
}
