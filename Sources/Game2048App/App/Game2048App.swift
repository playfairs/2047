import SwiftUI

#if SWIFT_PACKAGE
    import Game2048Core
#endif

@main
struct Game2048App: App {
    var body: some Scene {
        WindowGroup {
            AppNavigation()
        }
        #if os(macOS)
            .defaultSize(width: 1040, height: 820)
            .windowResizability(.contentMinSize)
            .commands {
                CommandGroup(replacing: .newItem) {
                    Button("New Game") {
                        NotificationCenter.default.post(name: .startNewGame, object: nil)
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
        #endif
    }
}

extension Notification.Name {
    static let startNewGame = Notification.Name("startNewGame")
}
