import XCTest
import SwiftData
@testable import WorkHours

final class CalculatorTests: XCTestCase {
    let calc = WorkHoursCalculator()
    let e = Entry.empty

    func testABExample() { XCTAssertEqual(calc.dailyHours(ab: .number(3.03), bl: e, ht: e, ch: e), 1, accuracy: 1e-9) }
    func testBLExample() { XCTAssertEqual(calc.dailyHours(ab: e, bl: .number(3.24), ht: e, ch: e), 1, accuracy: 1e-9) }
    func testCHExample() { XCTAssertEqual(calc.dailyHours(ab: e, bl: e, ht: e, ch: .number(15)), 1.4, accuracy: 1e-9) }
    func testCheckIsEight() { XCTAssertEqual(calc.dailyHours(ab: .check, bl: e, ht: e, ch: e), 8) }
    func testCheckInAnyColumn() {
        XCTAssertEqual(calc.dailyHours(ab: e, bl: e, ht: .check, ch: e), 8)
        XCTAssertEqual(calc.dailyHours(ab: e, bl: e, ht: e, ch: .check), 8)
    }
    func testFreeIsZero() { XCTAssertEqual(calc.dailyHours(ab: .free, bl: .number(5), ht: e, ch: e), 0) }
    func testKrankIsZero() { XCTAssertEqual(calc.dailyHours(ab: .krank, bl: e, ht: e, ch: .number(9)), 0) }
    func testEmptyIsZero() { XCTAssertEqual(calc.dailyHours(ab: e, bl: e, ht: e, ch: e), 0) }
    func testHTDoesNotCount() { XCTAssertEqual(calc.dailyHours(ab: e, bl: e, ht: .number(7), ch: e), 0) }
    func testHTCanBeEnabledLater() {
        var c = WorkHoursCalculator(); c.config.htDivisor = 2
        XCTAssertEqual(c.dailyHours(ab: e, bl: e, ht: .number(7), ch: e), 3.5, accuracy: 1e-9)
    }
    func testDecimals() {
        XCTAssertEqual(calc.dailyHours(ab: .number(6.06), bl: e, ht: e, ch: e), 2, accuracy: 1e-9)
        XCTAssertEqual(Entry.parse("3,5"), 3.5)
        XCTAssertEqual(Entry.parse("3.5"), 3.5)
    }
    func testValidationRejectsLetters() {
        XCTAssertNil(Entry.parse("abc")); XCTAssertNil(Entry.parse("1e5")); XCTAssertNil(Entry.parse("-3"))
        XCTAssertNil(Entry.parse("")); XCTAssertNil(Entry.parse("1.2.3"))
    }
    func testMonthlyTotal() {
        let days = [
            DayInput(ab: .check),                     // 8
            DayInput(ab: .number(19.695)),            // 6.5
            DayInput(ab: .free),                      // 0
            DayInput()                                // 0
        ]
        let t = calc.totals(of: days)
        XCTAssertEqual(t.hours, 14.5, accuracy: 1e-9)
        XCTAssertEqual(t.ab, 19.695, accuracy: 1e-9)
    }
    func testLeapYear() {
        XCTAssertEqual(DateHelper.daysInMonth(year: 2024, month: 2), 29)
        XCTAssertEqual(DateHelper.daysInMonth(year: 2026, month: 2), 28)
        XCTAssertEqual(DateHelper.daysInMonth(year: 2100, month: 2), 28)
        XCTAssertEqual(DateHelper.daysInMonth(year: 2026, month: 1), 31)
        XCTAssertEqual(DateHelper.daysInMonth(year: 2026, month: 4), 30)
        XCTAssertEqual(DateHelper.dayCount(year: 2026, month: 2, fixed30: true), 30)
    }
}

@MainActor
final class PersistenceTests: XCTestCase {
    private func memoryContainer() throws -> ModelContainer {
        try ModelContainer(for: MonthRecord.self, DayRecord.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    func testCreateEditAndReload() throws {
        let container = try memoryContainer()
        let ctx = ModelContext(container)
        let r = try MonthStore.openOrCreate(month: 10, year: 2026, context: ctx)
        XCTAssertEqual(r.days.count, 31)
        r.sortedDays[0].setEntry(.check, for: .ab, calculator: WorkHoursCalculator())
        try ctx.save()

        let fresh = ModelContext(container)
        let again = try MonthStore.openOrCreate(month: 10, year: 2026, context: fresh)
        XCTAssertEqual(again.sortedDays[0].ab, .check)
        XCTAssertEqual(try fresh.fetch(FetchDescriptor<MonthRecord>()).count, 1)   // not duplicated
    }

    func testSwitchingMonthsKeepsData() throws {
        let ctx = ModelContext(try memoryContainer())
        let oct = try MonthStore.openOrCreate(month: 10, year: 2026, context: ctx)
        oct.sortedDays[2].setEntry(.number(5), for: .bl, calculator: WorkHoursCalculator())
        let nov = try MonthStore.openOrCreate(month: 11, year: 2026, context: ctx)
        XCTAssertFalse(nov.hasData)
        XCTAssertEqual(nov.days.count, 30)
        let octAgain = try MonthStore.openOrCreate(month: 10, year: 2026, context: ctx)
        XCTAssertEqual(octAgain.sortedDays[2].bl, .number(5))
    }

    func testFebruaryLeapYearRecord() throws {
        let ctx = ModelContext(try memoryContainer())
        XCTAssertEqual(try MonthStore.openOrCreate(month: 2, year: 2024, context: ctx).days.count, 29)
        XCTAssertEqual(try MonthStore.openOrCreate(month: 2, year: 2025, context: ctx).days.count, 28)
    }

    func testEnsureDaysNeverRemoves() throws {
        let ctx = ModelContext(try memoryContainer())
        let r = try MonthStore.openOrCreate(month: 1, year: 2026, context: ctx)
        r.ensureDays(count: 10)
        XCTAssertEqual(r.days.count, 31)
    }

    func testSurvivesAppRestart() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("wh-\(UUID().uuidString).store")
        do {
            let c = try ModelContainer(for: MonthRecord.self, DayRecord.self, configurations: ModelConfiguration(url: url))
            let ctx = ModelContext(c)
            let r = try MonthStore.openOrCreate(month: 3, year: 2026, context: ctx)
            r.employeeName = "Basil"
            r.sortedDays[0].setEntry(.number(3.03), for: .ab, calculator: WorkHoursCalculator())
            try ctx.save()
        }
        let c2 = try ModelContainer(for: MonthRecord.self, DayRecord.self, configurations: ModelConfiguration(url: url))
        let r2 = try MonthStore.openOrCreate(month: 3, year: 2026, context: ModelContext(c2))
        XCTAssertEqual(r2.employeeName, "Basil")
        XCTAssertEqual(r2.sortedDays[0].ab, .number(3.03))
    }

    func testDeleteOnlyWhenExplicit() throws {
        let ctx = ModelContext(try memoryContainer())
        _ = try MonthStore.openOrCreate(month: 5, year: 2026, context: ctx)
        _ = try MonthStore.openOrCreate(month: 6, year: 2026, context: ctx)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<MonthRecord>()).count, 2)
    }
}
