import SwiftUI
#if os(iOS)
    import UIKit
#endif

struct SettingsView: View {
    @ObservedObject var model: GameViewModel
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("tilePalette") private var tilePaletteRawValue = TilePalette.warm.rawValue

    private var availableSizes: [Int] {
        #if os(iOS)
            UIDevice.current.userInterfaceIdiom == .phone ? [3, 4] : Array(3...8)
        #else
            Array(3...8)
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Make it yours")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))
                    Text("Choose a board that fits your play style.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Appearance", systemImage: darkModeEnabled ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))
                    Toggle("Dark mode", isOn: $darkModeEnabled)
                        .toggleStyle(.switch)
                    Text("Use a dark appearance across the app.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
                }
                .padding(18)
                .frame(maxWidth: 520, alignment: .leading)
                .background(
                    AppTheme.surface(colorScheme == .dark),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(AppTheme.border(colorScheme == .dark), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Tile colors", systemImage: "paintpalette.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))

                    Picker("Tile colors", selection: $tilePaletteRawValue) {
                        ForEach(TilePalette.allCases) { palette in
                            Text(palette.title).tag(palette.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(
                        "Warm keeps the classic colors. Cool uses ocean blues and violets. This setting is independent of light and dark mode."
                    )
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: 520, alignment: .leading)
                .background(
                    AppTheme.surface(colorScheme == .dark),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(AppTheme.border(colorScheme == .dark), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Label("Board size", systemImage: "square.grid.3x3")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))

                    Picker(
                        "Board size",
                        selection: Binding(
                            get: { model.boardSize },
                            set: { model.setBoardSize($0) }
                        )
                    ) {
                        ForEach(availableSizes, id: \.self) { size in
                            Text("\(size) × \(size)").tag(size)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Changing the board size starts a fresh game. Your all-time statistics stay saved.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: 520, alignment: .leading)
                .background(
                    AppTheme.surface(colorScheme == .dark),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(AppTheme.border(colorScheme == .dark), lineWidth: 1)
                }
            }
            .frame(maxWidth: 620, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background(colorScheme == .dark).ignoresSafeArea())
    }
}
