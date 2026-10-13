import Foundation

struct DayInput: Equatable {
    var ab = Entry()
    var bl = Entry()
    var ht = Entry()
    var ch = Entry()
}

/// All business rules live here. Change a rule here, nowhere else.
struct WorkHoursCalculator {
    struct Config: Equatable {
        var abDivisor = 3.03
        var blDivisor = 3.24
        var chMultiplier = 1.40
        var chDivisor = 15.0
        /// nil = HT is tracked but does not add hours. Set e.g. 4.0 to include HT later.
        var htDivisor: Double? = nil
        var checkHours = 8.0
    }

    struct Totals: Equatable {
        var ab = 0.0, bl = 0.0, ht = 0.0, ch = 0.0, hours = 0.0
    }

    var config = Config()

    /// Priority: Free/Krank (0) > Check (8) > formula. Empty cells add 0.
    func dailyHours(_ input: DayInput) -> Double {
        let all = [input.ab, input.bl, input.ht, input.ch]
        if all.contains(where: { $0.kind == .free || $0.kind == .krank }) { return 0 }
        if all.contains(where: { $0.kind == .check }) { return config.checkHours }

        var hours = input.ab.numericValue / config.abDivisor
            + input.bl.numericValue / config.blDivisor
            + (input.ch.numericValue * config.chMultiplier) / config.chDivisor
        if let d = config.htDivisor, d != 0 {
            hours += input.ht.numericValue / d
        }
        return hours
    }

    func dailyHours(ab: Entry, bl: Entry, ht: Entry, ch: Entry) -> Double {
        dailyHours(DayInput(ab: ab, bl: bl, ht: ht, ch: ch))
    }

    func totals(of inputs: [DayInput]) -> Totals {
        var t = Totals()
        for i in inputs {
            t.ab += i.ab.numericValue
            t.bl += i.bl.numericValue
            t.ht += i.ht.numericValue
            t.ch += i.ch.numericValue
            t.hours += dailyHours(i)
        }
        return t
    }
}
