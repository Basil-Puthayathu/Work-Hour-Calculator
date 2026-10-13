import SwiftUI
import SwiftData

struct EditTarget: Identifiable {
    let day: DayRecord
    let column: WorkColumn
    var id: String { "\(day.day)-\(column.rawValue)" }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct MonthRecordView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppSettings.fixed30Key) private var fixed30 = false
    @Bindable var record: MonthRecord

    @State private var editing: EditTarget?
    @State private var shareItem: ShareItem?
    @State private var savedFlash = false
    @State private var errorText: String?

    private let calculator = WorkHoursCalculator()

    var body: some View {
        let count = DateHelper.dayCount(year: record.year, month: record.month, fixed30: fixed30)
        let days = record.sortedDays.filter { $0.day <= count }
        let totals = calculator.totals(of: days.map(\.input))

        ScrollView {
            LazyVStack(spacing: 8, pinnedViews: [.sectionHeaders]) {
                headerCard
                Section {
                    ForEach(days) { day in
                        DayRow(day: day, year: record.year, month: record.month, calculator: calculator) { column in
                            editing = EditTarget(day: day, column: column)
                        }
                    }
                } header: {
                    ColumnHeaderRow()
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { TotalsBar(totals: totals) }
        .navigationTitle("\(record.monthName) \(String(record.year))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(savedFlash ? "Saved ✓" : "Save") { save(flash: true) }
                    .fontWeight(.semibold)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(ExportFormat.allCases) { format in
                        Button(format.title) { export(format, days: days, totals: totals) }
                    }
                } label: { Image(systemName: "square.and.arrow.up") }
            }
        }
        .sheet(item: $editing) { target in
            EntrySheet(
                title: "\(target.column.title) · Day \(target.day.day)",
                initial: target.day.entry(for: target.column),
                checkHours: calculator.config.checkHours
            ) { entry in
                target.day.setEntry(entry, for: target.column, calculator: calculator)
                save(flash: false)
            }
            .presentationDetents([.height(430)])
            .presentationBackground(Theme.background)
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(url: item.url).presentationDetents([.medium, .large])
        }
        .alert("Export failed", isPresented: Binding(
            get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorText ?? "") }
        .onAppear { record.ensureDays(count: count) }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { save(flash: false) }
        }
        .onDisappear { save(flash: false) }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WORK HOURS RECORD")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .tracking(2)
                .foregroundStyle(Theme.accent)

            field("Employee Name", text: $record.employeeName)
            field("Department", text: $record.department)

            HStack(spacing: 10) {
                pill("Month", record.monthName)
                pill("Year", String(record.year))
            }
        }
        .cardStyle()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(Theme.textSecondary)
            TextField(title, text: text)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Theme.cardHigh, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onChange(of: text.wrappedValue) { _, _ in record.updatedAt = .now }
        }
    }

    private func pill(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.body.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .background(Theme.cardHigh.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func save(flash: Bool) {
        record.updatedAt = .now
        do { try context.save() } catch { errorText = error.localizedDescription; return }
        guard flash else { return }
        withAnimation { savedFlash = true }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation { savedFlash = false }
        }
    }

    private func export(_ format: ExportFormat, days: [DayRecord], totals: WorkHoursCalculator.Totals) {
        let snapshot = ExportSnapshot(
            employee: record.employeeName, monthName: record.monthName, year: record.year,
            department: record.department,
            rows: days.map { d in
                ExportSnapshot.Row(day: d.day, ab: d.ab, bl: d.bl, ht: d.ht, ch: d.ch,
                                   hours: calculator.dailyHours(d.input))
            },
            totals: totals)
        do { shareItem = ShareItem(url: try MonthExporter().export(snapshot: snapshot, format: format)) }
        catch { errorText = error.localizedDescription }
    }
}

// MARK: - Rows

struct ColumnHeaderRow: View {
    var body: some View {
        HStack(spacing: Layout.spacing) {
            Text("Date").frame(width: Layout.dayWidth, alignment: .leading)
            ForEach(WorkColumn.allCases) { c in
                Text(c.title).frame(maxWidth: .infinity).foregroundStyle(Theme.color(for: c))
            }
            Text("Hours").frame(width: Layout.hoursWidth, alignment: .trailing)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.background)
    }
}

struct DayRow: View {
    let day: DayRecord
    let year: Int
    let month: Int
    let calculator: WorkHoursCalculator
    let onTap: (WorkColumn) -> Void

    var body: some View {
        let hours = calculator.dailyHours(day.input)
        let weekend = DateHelper.isWeekend(year: year, month: month, day: day.day)

        HStack(spacing: Layout.spacing) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(day.day)").font(.headline.monospacedDigit())
                Text(DateHelper.weekdayLabel(year: year, month: month, day: day.day))
                    .font(.caption2)
                    .foregroundStyle(weekend ? Theme.amber : Theme.textSecondary)
            }
            .frame(width: Layout.dayWidth, alignment: .leading)

            ForEach(WorkColumn.allCases) { column in
                EntryChip(entry: day.entry(for: column), column: column) { onTap(column) }
                    .accessibilityLabel("Day \(day.day), \(column.title), \(day.entry(for: column).displayText)")
            }

            Text(day.hasData ? hours.formatted(.number.precision(.fractionLength(2))) : "–")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(day.hasData ? Color.white : Theme.textSecondary)
                .frame(width: Layout.hoursWidth, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct EntryChip: View {
    let entry: Entry
    let column: WorkColumn
    let action: () -> Void

    private var tint: Color {
        switch entry.kind {
        case .empty: return Color.white.opacity(0.3)
        case .number: return Theme.color(for: column)
        case .check: return Theme.accent
        case .free: return Theme.blue
        case .krank: return Theme.red
        }
    }

    var body: some View {
        Button(action: action) {
            Text(entry.displayText)
                .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(entry.isEmpty ? Color.white.opacity(0.04) : tint.opacity(0.16),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct TotalsBar: View {
    let totals: WorkHoursCalculator.Totals

    private func value(_ column: WorkColumn) -> Double {
        switch column {
        case .ab: return totals.ab
        case .bl: return totals.bl
        case .ht: return totals.ht
        case .ch: return totals.ch
        }
    }

    var body: some View {
        HStack(spacing: Layout.spacing) {
            Text("TOTAL").font(.caption2.weight(.heavy))
                .frame(width: Layout.dayWidth, alignment: .leading)
                .foregroundStyle(Theme.textSecondary)
            ForEach(WorkColumn.allCases) { c in
                Text(value(c).formatted(.number.precision(.fractionLength(0...2))))
                    .font(.footnote.weight(.bold).monospacedDigit())
                    .minimumScaleFactor(0.6).lineLimit(1)
                    .foregroundStyle(Theme.color(for: c))
                    .frame(maxWidth: .infinity)
            }
            Text(totals.hours.formatted(.number.precision(.fractionLength(2))))
                .font(.subheadline.weight(.heavy).monospacedDigit())
                .minimumScaleFactor(0.6).lineLimit(1)
                .foregroundStyle(Theme.accent)
                .frame(width: Layout.hoursWidth + 10, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .background(Theme.cardHigh.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Monthly total \(totals.hours.formatted(.number.precision(.fractionLength(2)))) hours")
    }
}
