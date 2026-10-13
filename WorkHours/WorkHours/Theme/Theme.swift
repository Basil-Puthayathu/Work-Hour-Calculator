import SwiftUI

enum Theme {
    static let background = Color(red: 0.04, green: 0.05, blue: 0.09)
    static let card = Color(red: 0.08, green: 0.10, blue: 0.16)
    static let cardHigh = Color(red: 0.12, green: 0.14, blue: 0.22)
    static let accent = Color(red: 0.25, green: 0.86, blue: 0.69)
    static let blue = Color(red: 0.38, green: 0.62, blue: 1.0)
    static let red = Color(red: 1.0, green: 0.42, blue: 0.46)
    static let amber = Color(red: 1.0, green: 0.72, blue: 0.30)
    static let violet = Color(red: 0.70, green: 0.55, blue: 1.0)
    static let pink = Color(red: 1.0, green: 0.50, blue: 0.75)
    static let textSecondary = Color.white.opacity(0.55)

    static func color(for column: WorkColumn) -> Color {
        switch column {
        case .ab: return blue
        case .bl: return violet
        case .ht: return amber
        case .ch: return pink
        }
    }
}

enum Layout {
    static let dayWidth: CGFloat = 40
    static let hoursWidth: CGFloat = 58
    static let spacing: CGFloat = 6
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardModifier()) }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.black)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Theme.cardHigh, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
