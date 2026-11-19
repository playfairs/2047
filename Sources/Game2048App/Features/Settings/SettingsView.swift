import SwiftUI
#if os(macOS)
    import AppKit
#endif
#if os(iOS)
    import UIKit
#endif

struct SettingsView: View {
    @ObservedObject var model: GameViewModel
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("tilePalette") private var tilePaletteRawValue = TilePalette.warm.rawValue
    #if os(macOS)
        @EnvironmentObject private var discordRPCManager: DiscordRPCManager
        @AppStorage("secretSettingsUnlocked") private var secretSettingsUnlocked = false
        @AppStorage("repeatArrowKeysEnabled") private var repeatArrowKeysEnabled = false
        @AppStorage("discordRPCEnabled") private var discordRPCEnabled = false
    #endif

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

                #if os(macOS)
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Discord Rich Presence", systemImage: "gamecontroller.fill")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))

                        Toggle("Show my game activity on Discord", isOn: $discordRPCEnabled)
                            .toggleStyle(.switch)

                        Text(discordRPCManager.statusMessage)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))

                        Text(
                            "Shows your score and high score while playing, or “In Menus” when the app is open. Requires Discord desktop and “Display current activity as a status message” enabled under Discord’s Activity Privacy settings."
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
                #endif

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

                #if os(macOS)
                    if secretSettingsUnlocked {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Secret settings", systemImage: "sparkles")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))

                            Toggle("Repeat moves while holding arrow keys", isOn: $repeatArrowKeysEnabled)
                                .toggleStyle(.switch)

                            Text("Hold one or more arrow keys to repeat those moves.")
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
                    }
                #endif
            }
            .frame(maxWidth: 620, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background(colorScheme == .dark).ignoresSafeArea())
        #if os(macOS)
            .overlay {
                MacShiftSequenceDetector {
                    secretSettingsUnlocked = true
                }
                .frame(width: 1, height: 1)
                .opacity(0)
                .allowsHitTesting(false)
            }
        #endif
    }
}

#if os(macOS)
    private struct MacShiftSequenceDetector: NSViewRepresentable {
        let onUnlock: () -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(onUnlock: onUnlock)
        }

        func makeNSView(context: Context) -> NSView {
            let view = NSView(frame: .zero)
            context.coordinator.start()
            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {
            context.coordinator.onUnlock = onUnlock
        }

        static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
            coordinator.stop()
        }

        @MainActor
        final class Coordinator: @unchecked Sendable {
            var onUnlock: () -> Void
            private var eventMonitor: Any?
            private var shiftPresses: [Date] = []

            init(onUnlock: @escaping () -> Void) {
                self.onUnlock = onUnlock
            }

            func start() {
                guard eventMonitor == nil else { return }
                eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {
                    [weak self] event in
                    guard let self,
                        (event.keyCode == 56 || event.keyCode == 60),
                        event.modifierFlags.contains(.shift)
                    else {
                        return event
                    }

                    let now = Date()
                    self.shiftPresses.removeAll { now.timeIntervalSince($0) > 2 }
                    self.shiftPresses.append(now)
                    if self.shiftPresses.count >= 5 {
                        self.shiftPresses.removeAll()
                        self.onUnlock()
                    }
                    return event
                }
            }

            func stop() {
                guard let eventMonitor else { return }
                NSEvent.removeMonitor(eventMonitor)
                self.eventMonitor = nil
                shiftPresses.removeAll()
            }
        }
    }
#endif
