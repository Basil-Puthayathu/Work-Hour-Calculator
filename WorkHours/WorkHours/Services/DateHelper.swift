import Foundation

enum DateHelper {
    static let monthNames = ["January", "February", "March", "April", "May", "June",
                             "July", "August", "September", "October", "November", "December"]
    private static let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private static let calendar = Calendar(identifier: .gregorian)

    static func daysInMonth(year: Int, month: Int) -> Int {
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: date) else { return 30 }
        return range.count
    }

    /// `fixed30` mirrors the 30-row Excel sheet.
    static func dayCount(year: Int, month: Int, fixed30: Bool) -> Int {
        fixed30 ? 30 : daysInMonth(year: year, month: month)
    }

    static func weekdayLabel(year: Int, month: Int, day: Int) -> String {
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)),
              calendar.component(.month, from: date) == month else { return "" }
        return weekdayNames[calendar.component(.weekday, from: date) - 1]
    }

    static func isWeekend(year: Int, month: Int, day: Int) -> Bool {
        let l = weekdayLabel(year: year, month: month, day: day)
        return l == "Sat" || l == "Sun"
    }
}
