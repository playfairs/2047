import SwiftUI

private enum AppSection: String, CaseIterable, Identifiable {
    case game = "Play"
    case settings = "Settings"
    case statistics = "Stats"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .game: "play.fill"
        case .settings: "gearshape.fill"
        case .statistics: "chart.bar.xaxis"
        }
    }
}

struct AppNavigation: View {
    @StateObject private var model = GameViewModel()
    @State private var selection: AppSection? = .game
    @State private var phoneSelection: AppSection = .game
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    var body: some View {
        Group {
            #if os(macOS)
                sidebarLayout
            #else
                if horizontalSizeClass == .regular {
                    sidebarLayout
                } else {
                    phoneLayout
                }
            #endif
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }

    private var sidebarLayout: some View {
        NavigationSplitView {
            List {
                ForEach(AppSection.allCases) { section in
                    Button {
                        selection = section
                    } label: {
                        Text(section.rawValue)
                            .font(.system(size: 14, weight: selection == section ? .semibold : .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 7)
                            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .background {
                                if selection == section {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(Color.accentColor.opacity(0.12))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("2048")
            .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 260)
        } detail: {
            detailContent(for: selection ?? .game)
        }
        .navigationSplitViewStyle(.balanced)
        .background(AppTheme.background(darkModeEnabled).ignoresSafeArea())
        .onReceive(NotificationCenter.default.publisher(for: .startNewGame)) { _ in
            model.startNewGame()
            selection = .game
        }
    }

    private var phoneLayout: some View {
        TabView(selection: $phoneSelection) {
            NavigationStack {
                Group {
                    if model.isGameActive {
                        GameScreen(model: model)
                    } else {
                        PlayLandingView(model: model) {
                            model.beginGame()
                        }
                    }
                }
                .navigationTitle("Play")
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
            }
            .tabItem { Label("Play", systemImage: AppSection.game.symbol) }
            .tag(AppSection.game)

            NavigationStack {
                SettingsView(model: model)
                    .navigationTitle("Settings")
                    #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            .tabItem { Label("Settings", systemImage: AppSection.settings.symbol) }
            .tag(AppSection.settings)

            NavigationStack {
                StatisticsView(model: model)
                    .navigationTitle("Stats")
                    #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            .tabItem { Label("Stats", systemImage: AppSection.statistics.symbol) }
            .tag(AppSection.statistics)
        }
        .tint(Color(red: 0.65, green: 0.46, blue: 0.25))
        .onReceive(NotificationCenter.default.publisher(for: .startNewGame)) { _ in
            model.startNewGame()
            phoneSelection = .game
        }
        .onAppear {
            if model.boardSize > 4 { model.setBoardSize(4) }
        }
    }

    @ViewBuilder
    private func detailContent(for section: AppSection) -> some View {
        switch section {
        case .game:
            Group {
                if model.isGameActive {
                    GameScreen(model: model)
                } else {
                    PlayLandingView(model: model) {
                        model.beginGame()
                    }
                }
            }
            .navigationTitle("Play")
        case .statistics:
            StatisticsView(model: model)
                .navigationTitle("Stats")
        case .settings:
            SettingsView(model: model)
                .navigationTitle("Settings")
        }
    }
}
