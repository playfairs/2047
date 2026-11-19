import SwiftUI
#if os(iOS)
    import UIKit
#endif

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
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    private var isPhoneDevice: Bool {
        #if os(iOS)
            UIDevice.current.userInterfaceIdiom == .phone
        #else
            false
        #endif
    }

    private var usesCompactPhoneSidebar: Bool {
        isPhoneDevice && verticalSizeClass == .compact
    }

    var body: some View {
        Group {
            #if os(macOS)
                sidebarLayout
            #else
                if usesCompactPhoneSidebar || horizontalSizeClass == .regular {
                    sidebarLayout
                } else {
                    phoneLayout
                }
            #endif
        }
        .onAppear {
            if isPhoneDevice, model.boardSize > 4 { model.setBoardSize(4) }
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
                        Group {
                            if usesCompactPhoneSidebar {
                                Image(systemName: section.symbol)
                                    .font(
                                        .system(size: 17, weight: selection == section ? .semibold : .regular)
                                    )
                                    .frame(maxWidth: .infinity, minHeight: 42)
                            } else {
                                Text(section.rawValue)
                                    .font(
                                        .system(size: 14, weight: selection == section ? .semibold : .medium)
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .accessibilityLabel(section.rawValue)
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
            .navigationTitle(usesCompactPhoneSidebar ? "" : "2048")
            .navigationSplitViewColumnWidth(
                min: usesCompactPhoneSidebar ? 64 : 180,
                ideal: usesCompactPhoneSidebar ? 68 : 210,
                max: usesCompactPhoneSidebar ? 72 : 260
            )
        } detail: {
            detailContent(for: selection ?? .game)
        }
        .navigationSplitViewStyle(.balanced)
        .background(AppTheme.background(darkModeEnabled).ignoresSafeArea())
        #if os(iOS)
            .toolbar(model.isGameActive ? .hidden : .visible, for: .navigationBar)
        #endif
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
                    .toolbar(model.isGameActive ? .hidden : .visible, for: .navigationBar)
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
