import SwiftUI

struct EntrySheet: View {
    let title: String
    let initial: Entry
    let checkHours: Double
    let onSave: (Entry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var kind: EntryKind
    @State private var text: String
    @State private var errorText: String?
    @FocusState private var focused: Bool

    private let kinds: [EntryKind] = [.number, .check, .free, .krank]

    init(title: String, initial: Entry, checkHours: Double, onSave: @escaping (Entry) -> Void) {
        self.title = title
        self.initial = initial
        self.checkHours = checkHours
        self.onSave = onSave
        _kind = State(initialValue: initial.kind == .empty ? .number : initial.kind)
        _text = State(initialValue: initial.kind == .number ? Entry.plain(initial.value) : "")
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 2) {
                Text(title).font(.headline)
                Text("Choose Entry").font(.subheadline).foregroundStyle(Theme.textSecondary)
            }

            Picker("Entry", selection: $kind) {
                ForEach(kinds) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)

            Group {
                if kind == .number {
                    VStack(spacing: 8) {
                        TextField("0", text: $text)
                            .keyboardType(.decimalPad)
                            .focused($focused)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .background(Theme.cardHigh, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .accessibilityLabel("Number")
                        if let errorText {
                            Text(errorText).font(.footnote).foregroundStyle(Theme.red)
                        }
                    }
                } else {
                    Text(explanation)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 90)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }

            HStack(spacing: 12) {
                Button("Clear") { onSave(.empty); dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Save") { commit() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(20)
        .onAppear { focused = (kind == .number) }
        .onChange(of: kind) { _, new in focused = (new == .number); errorText = nil }
        .onChange(of: text) { _, new in
            // Block accidental letters as the user types.
            let cleaned = new.filter { "0123456789.,".contains($0) }
            if cleaned != new { text = cleaned; errorText = "Numbers only." } else { errorText = nil }
        }
    }

    private var explanation: String {
        switch kind {
        case .check: return "Check counts as a full \(Entry.plain(checkHours))-hour day."
        case .free: return "Free day. Counts as 0 hours."
        case .krank: return "Krank (sick). Counts as 0 hours."
        default: return ""
        }
    }

    private func commit() {
        switch kind {
        case .number:
            guard let v = Entry.parse(text) else {
                errorText = "Enter a valid number (for example 3 or 3.5)."
                return
            }
            onSave(.number(v))
        case .check: onSave(.check)
        case .free: onSave(.free)
        case .krank: onSave(.krank)
        case .empty: onSave(.empty)
        }
        dismiss()
    }
}
