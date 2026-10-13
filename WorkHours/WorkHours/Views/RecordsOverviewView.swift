import SwiftUI
import SwiftData

struct RecordsOverviewView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\MonthRecord.year), SortDescriptor(\MonthRecord.month)])
    private var records: [MonthRecord]
    @AppStorage(AppSettings.fixed30Key) private var fixed30 = false

    @State private var year = Calendar.current.component(.year, from: .now)
    @State private var opened: MonthRecord?
    @State private var showAdd = false
    @State private var pendingDelete: MonthRecord?
    @State private var errorText: String?

    private let calculator = WorkHoursCalculator()

    var body: some View {
        List {
            Section {
                HStack {
                    Button { year -= 1 } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    Spacer()
                    Text(String(year)).font(.system(.title2, design: .rounded).weight(.bold))
                    Spacer()
                    Button { year += 1 } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                }
                .buttonStyle(.plain)
                .listRowBackground(Theme.card)
            }

            Section {
                ForEach(1...12, id: \.self) { m in row(for: m) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Records")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Label("Add New Month", systemImage: "plus") }
            }
        }
        .navigationDestination(item: $opened) { MonthRecordView(record: $0) }
        .sheet(isPresented: $showAdd) {
            AddMonthSheet { month, y in
                showAdd = false
                year = y
                open(month: month, year: y)
            }
            .presentationDetents([.height(420)])
            .presentationBackground(Theme.background)
        }
        .alert("Delete this month's record?", isPresented: Binding(
            get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let r = pendingDelete {
                    context.delete(r)
                    try? context.save()
                }
                pendingDelete = nil
            }
        } message: {
            if let r = pendingDelete {
                Text("All entries for \(r.monthName) \(String(r.year)) will be permanently removed.")
            }
        }
        .alert("Could not open month", isPresented: Binding(
            get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorText ?? "") }
    }

    @ViewBuilder
    private func row(for month: Int) -> some View {
        let record = records.first { $0.year == year && $0.month == month }
        let filled = record?.hasData ?? false
        Button { open(month: month, year: year) } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(filled ? Theme.accent : Color.white.opacity(0.12))
                    .frame(width: 10, height: 10)
                Text(DateHelper.monthNames[month - 1])
                    .font(.headline)
                    .foregroundStyle(filled ? Color.white : Theme.textSecondary)
                Spacer()
                if let record, filled {
                    Text(totalText(for: record)).font(.subheadline.monospacedDigit()).foregroundStyle(Theme.accent)
                }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.textSecondary)
            }
            .frame(minHeight: 44)
        }
        .listRowBackground(Theme.card)
        .swipeActions {
            if let record {
                Button("Delete", role: .destructive) { pendingDelete = record }
            }
        }
        .accessibilityLabel("\(DateHelper.monthNames[month - 1]) \(String(year)), \(filled ? "has data" : "empty")")
    }

    private func totalText(for record: MonthRecord) -> String {
        let count = DateHelper.dayCount(year: record.year, month: record.month, fixed30: fixed30)
        let days = record.sortedDays.filter { $0.day <= count }
        let t = calculator.totals(of: days.map(\.input))
        return t.hours.formatted(.number.precision(.fractionLength(2))) + " h"
    }

    private func open(month: Int, year: Int) {
        do { opened = try MonthStore.openOrCreate(month: month, year: year, context: context) }
        catch { errorText = error.localizedDescription }
    }
}

struct AddMonthSheet: View {
    @State private var month = Calendar.current.component(.month, from: .now)
    @State private var year = Calendar.current.component(.year, from: .now)
    let onAdd: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Add New Month").font(.headline)
            MonthYearPicker(month: $month, year: $year)
            Button("Add / Open") { onAdd(month, year) }
                .buttonStyle(PrimaryButtonStyle())
            Text("If this month already exists it is opened as-is, nothing is overwritten.")
                .font(.footnote).foregroundStyle(Theme.textSecondary)
        }
        .padding(20)
    }
}
