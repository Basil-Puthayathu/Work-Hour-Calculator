import SwiftUI
import SwiftData

struct MonthYearPicker: View {
    @Binding var month: Int
    @Binding var year: Int

    var body: some View {
        HStack(spacing: 0) {
            Picker("Month", selection: $month) {
                ForEach(1...12, id: \.self) { Text(DateHelper.monthNames[$0 - 1]).tag($0) }
            }
            .pickerStyle(.wheel)
            Picker("Year", selection: $year) {
                ForEach(2020...2070, id: \.self) { Text(String($0)).tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(width: 110)
        }
        .frame(height: 150)
    }
}

struct MonthSelectionView: View {
    @Environment(\.modelContext) private var context
    @State private var month = Calendar.current.component(.month, from: .now)
    @State private var year = Calendar.current.component(.year, from: .now)
    @State private var opened: MonthRecord?
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Select Month")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    Text("Pick a month and year. Saved data loads automatically; new months start empty.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
                    MonthYearPicker(month: $month, year: $year)
                    Text("\(DateHelper.monthNames[month - 1]) \(String(year))")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
                .cardStyle()

                Button("Open Month") { open() }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Work Hours")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $opened) { MonthRecordView(record: $0) }
        .alert("Could not open month", isPresented: Binding(
            get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorText ?? "") }
    }

    private func open() {
        do { opened = try MonthStore.openOrCreate(month: month, year: year, context: context) }
        catch { errorText = error.localizedDescription }
    }
}
