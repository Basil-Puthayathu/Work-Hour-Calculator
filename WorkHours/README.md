# Work Hours (SwiftUI + SwiftData, iOS 17+)

## Run it
Option A (XcodeGen): `brew install xcodegen && xcodegen && open WorkHours.xcodeproj`
Option B (manual): Xcode → New iOS App "WorkHours" (SwiftUI, SwiftData off), delete the generated files,
drag in `WorkHours/` and `WorkHoursTests/` (add tests to a unit-test target), set deployment target iOS 17.
Then ⌘U runs the tests, ⌘R runs the app.

## Layout
- Models/: Entry, DayRecord, MonthRecord (SwiftData)
- Services/: WorkHoursCalculator (all rules), MonthStore, DateHelper, MonthExporter (CSV/PDF/XLSX)
- Views/: Splash, MonthSelection, RecordsOverview, MonthRecord, EntrySheet, Settings
- Theme/: dark palette + styles

## Rules (edit WorkHoursCalculator.Config)
Free/Krank in any cell of a day -> 0. Else Check in any cell -> 8. Else
AB/3.03 + BL/3.24 + CH*1.40/15. HT tracked, not counted (set `htDivisor` to include).
