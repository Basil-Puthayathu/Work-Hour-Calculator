import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.fixed30Key) private var fixed30 = false
    @AppStorage(AppSettings.employeeKey) private var employee = ""
    @AppStorage(AppSettings.departmentKey) private var department = ""

    var body: some View {
        Form {
            Section("Defaults for new months") {
                TextField("Employee Name", text: $employee)
                TextField("Department", text: $department)
            }
            .listRowBackground(Theme.card)

            Section {
                Toggle("Always use 30 rows", isOn: $fixed30)
            } header: {
                Text("Days")
            } footer: {
                Text("Off: each month shows its real length (28/29/30/31). On: like the Excel sheet, exactly 30 rows. Days beyond 30 are kept in the database but not shown or counted while this is on.")
            }
            .listRowBackground(Theme.card)

            Section("Calculation") {
                let c = WorkHoursCalculator().config
                Text("Hours = AB / \(Entry.plain(c.abDivisor)) + BL / \(Entry.plain(c.blDivisor)) + (CH × \(Entry.plain(c.chMultiplier))) / \(Entry.plain(c.chDivisor))")
                    .font(.footnote.monospaced())
                Text("Check = \(Entry.plain(c.checkHours)) h. Free or Krank = 0 h. HT is tracked but not part of the formula.")
                    .font(.footnote).foregroundStyle(Theme.textSecondary)
            }
            .listRowBackground(Theme.card)

            Section("Data") {
                Text("Everything is stored on this device and works offline. Nothing is deleted unless you confirm deleting a month.")
                    .font(.footnote).foregroundStyle(Theme.textSecondary)
            }
            .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Settings")
    }
}
