import SwiftUI

#if SWIFT_PACKAGE
import Game2048Core
#endif

@main
struct Game2048App: App {
    var body: some Scene {
        WindowGroup {
            GameScreen()
        }
        #if os(macOS)
        .defaultSize(width: 720, height: 880)
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
