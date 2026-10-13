import SwiftUI
import SwiftData

@main
struct WorkHoursApp: App {
    let container: ModelContainer = {
        do {
            return try ModelContainer(for: MonthRecord.self, DayRecord.self)
        } catch {
            fatalError("Could not open the local database: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            MainTabView()
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeInOut(duration: 0.4)) { showSplash = false }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { MonthSelectionView() }
                .tabItem { Label("Open", systemImage: "calendar") }
            NavigationStack { RecordsOverviewView() }
                .tabItem { Label("Records", systemImage: "tray.full") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
