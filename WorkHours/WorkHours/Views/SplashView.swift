import SwiftUI

struct SplashView: View {
    @State private var ring: CGFloat = 0
    @State private var minuteAngle = 0.0
    @State private var textOpacity = 0.0
    @State private var scale: CGFloat = 0.85

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 30) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: ring)
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Capsule().fill(Color.white)
                        .frame(width: 4, height: 38)
                        .offset(y: -19)
                        .rotationEffect(.degrees(minuteAngle))
                    Capsule().fill(Theme.accent)
                        .frame(width: 5, height: 26)
                        .offset(y: -13)
                        .rotationEffect(.degrees(minuteAngle / 12))
                    Circle().fill(Color.white).frame(width: 10, height: 10)
                }
                .frame(width: 120, height: 120)
                .scaleEffect(scale)

                Text("WORK HOURS RECORD")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .tracking(3)
                    .foregroundStyle(.white)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4)) {
                ring = 1
                minuteAngle = 360
                scale = 1
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.3)) { textOpacity = 1 }
        }
        .accessibilityHidden(true)
    }
}
