import SwiftUI
#if os(macOS)
    import AppKit
#endif
#if os(iOS)
    import UIKit
#endif

#if SWIFT_PACKAGE
    import Game2048Core
#endif

private struct BoardTile: Identifiable {
    let id: UUID
    let index: Int
    let value: Int
}

struct GameScreen: View {
    @ObservedObject var model: GameViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AppStorage("tilePalette") private var tilePaletteRawValue = TilePalette.warm.rawValue

    private let boardSpacing: CGFloat = 10
    private var background: Color { AppTheme.background(colorScheme == .dark) }
    private var tilePalette: TilePalette { TilePalette(rawValue: tilePaletteRawValue) ?? .warm }
    private var directionButtonSize: CGFloat {
        #if os(iOS)
            verticalSizeClass == .compact ? 42 : 50
        #else
            50
        #endif
    }
    private var directionButtonSpacing: CGFloat {
        #if os(iOS)
            verticalSizeClass == .compact ? 8 : 12
        #else
            12
        #endif
    }
    private var newGameButtonTitle: String {
        #if os(iOS)
            "Restart"
        #else
            "New game"
        #endif
    }

    var body: some View {
        GeometryReader { geometry in
            #if os(iOS)
                let boardDimension: CGFloat =
                    verticalSizeClass == .compact
                    ? min(geometry.size.height - 28, max(180, geometry.size.width - 280), 460)
                    : min(geometry.size.width - 32, max(220, geometry.size.height - 250), 560)
            #else
                let boardDimension = min(geometry.size.width - 44, max(200, geometry.size.height - 360), 680)
            #endif

            ZStack {
                background.ignoresSafeArea()
                RadialGradient(
                    colors: [Color.white.opacity(colorScheme == .dark ? 0.06 : 0.8), background.opacity(0)],
                    center: .top,
                    startRadius: 20,
                    endRadius: 650
                )
                .ignoresSafeArea()

                #if os(iOS)
                    if verticalSizeClass == .compact {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 10) {
                                header
                                compactScores
                                controls
                                timerFooter
                            }
                            .frame(width: 220)

                            board(size: boardDimension)
                        }
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 12) {
                            header
                            scores
                            board(size: boardDimension)
                            controls
                            timerFooter
                        }
                        .frame(maxWidth: 560)
                        .padding(.horizontal, 16)
                        .padding(.top, 0)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                #else
                    ScrollView(.vertical) {
                        VStack(spacing: 18) {
                            header
                            scores
                            board(size: boardDimension)
                            controls
                            timerFooter
                        }
                        .frame(maxWidth: 760)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollIndicators(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                #endif
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        #if os(macOS)
            .background {
                MacArrowKeyHandler { direction in
                    move(direction)
                }
            }
        #endif
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("2048")
                    #if os(iOS)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    #else
                        .font(.system(size: 43, weight: .black, design: .rounded))
                    #endif
                    .tracking(-2.2)
                    .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))
                #if os(iOS)
                    if verticalSizeClass != .compact {
                        Text("Merge the numbers to make bigger ones")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                #else
                    Text("Merge the numbers to make bigger ones")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
                #endif
            }
            Spacer(minLength: 4)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    model.startNewGame()
                }
            } label: {
                Label(newGameButtonTitle, systemImage: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))
                    .padding(.horizontal, 12)
                    .frame(height: 42)
            }
            .buttonStyle(GameGlassButtonStyle())
            .accessibilityHint("Starts a new game and resets the current score")
        }
    }

    private var scores: some View {
        HStack(spacing: 12) {
            scoreCard(title: "SCORE", value: model.game.score)
            scoreCard(title: "BEST", value: model.bestScore)
            Spacer(minLength: 0)
            Label("\(model.boardSize) × \(model.boardSize)", systemImage: "square.grid.3x3")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
        }
    }

    private var compactScores: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                scoreCard(title: "SCORE", value: model.game.score)
                scoreCard(title: "BEST", value: model.bestScore)
            }
            Label("\(model.boardSize) × \(model.boardSize) board", systemImage: "square.grid.3x3")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
        }
    }

    private var timerFooter: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack {
                #if os(iOS)
                    Text("Swipe to move")
                #else
                    Text("Use the arrow keys to move")
                #endif
                Spacer()
                Label(
                    formattedGameTime(model.elapsedTime(at: context.date)),
                    systemImage: "timer"
                )
                .monospacedDigit()
                .accessibilityLabel("Elapsed time \(formattedGameTime(model.elapsedTime(at: context.date)))")
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
        }
    }

    private func scoreCard(title: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.76))
            Text(value.formatted())
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .foregroundStyle(.white)
        }
        .frame(minWidth: 76, minHeight: 55)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.68, green: 0.61, blue: 0.52),
                            Color(red: 0.57, green: 0.50, blue: 0.42),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.55), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
    }

    private func board(size: CGFloat) -> some View {
        let side = model.game.boardSize
        let spacing = max(5, min(boardSpacing, size / CGFloat(side * 14)))
        let cellSize = (size - spacing * CGFloat(side + 1)) / CGFloat(side)
        let visibleTiles = model.game.tiles.indices.compactMap { index -> BoardTile? in
            guard let id = model.game.tileIDs[index] else { return nil }
            return BoardTile(id: id, index: index, value: model.game.tiles[index])
        }

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color(red: 0.72, green: 0.67, blue: 0.59))
                .shadow(color: .black.opacity(0.13), radius: 20, y: 11)

            VStack(spacing: spacing) {
                ForEach(0..<side, id: \.self) { _ in
                    HStack(spacing: spacing) {
                        ForEach(0..<side, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: cellSize * 0.16, style: .continuous)
                                .fill(Color(red: 0.83, green: 0.79, blue: 0.72).opacity(0.55))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            .padding(spacing)

            ForEach(visibleTiles) { boardTile in
                tile(boardTile.value, size: cellSize)
                    .position(
                        x: spacing + CGFloat(boardTile.index % side) * (cellSize + spacing) + cellSize / 2,
                        y: spacing + CGFloat(boardTile.index / side) * (cellSize + spacing) + cellSize / 2
                    )
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.55).combined(with: .opacity),
                            removal: .opacity
                        ))
            }
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .strokeBorder(.white.opacity(0.65), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .contentShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 22)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    guard max(abs(horizontal), abs(vertical)) > 28 else { return }
                    if abs(horizontal) > abs(vertical) {
                        move(horizontal > 0 ? .right : .left)
                    } else {
                        move(vertical > 0 ? .down : .up)
                    }
                }
        )
        .overlay {
            if model.isShowingWin || model.game.isGameOver {
                gameOverOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: model.game.tiles)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: model.game.tileIDs)
        .animation(.easeInOut(duration: 0.22), value: model.isShowingWin)
        .animation(.easeInOut(duration: 0.22), value: model.game.isGameOver)
        .accessibilityLabel("2048 game board")
    }

    private func tile(_ value: Int, size: CGFloat) -> some View {
        let colors = tileColors(for: value)
        let digits = value.formatted().count
        let fontSize = size * (digits >= 4 ? 0.32 : digits == 3 ? 0.38 : 0.46)

        return RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
            .fill(colors.background)
            .overlay {
                if value > 0 {
                    Text(value.formatted())
                        .font(.system(size: fontSize, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundStyle(colors.foreground)
                        .contentTransition(.numericText())
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: size, height: size)
            .shadow(color: value >= 8 ? colors.background.opacity(0.3) : .clear, radius: 8, y: 3)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(value == 0 ? "Empty" : "\(value)")
    }

    private var controls: some View {
        HStack(spacing: directionButtonSpacing) {
            directionButton(.left, symbol: "arrow.left")
            directionButton(.up, symbol: "arrow.up")
            directionButton(.down, symbol: "arrow.down")
            directionButton(.right, symbol: "arrow.right")
        }
        .padding(.top, 1)
    }

    private func directionButton(_ direction: MoveDirection, symbol: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                move(direction)
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))
                .frame(width: directionButtonSize, height: directionButtonSize - 4)
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(GameGlassButtonStyle())
        .accessibilityLabel("Move \(String(describing: direction))")
    }

    private var gameOverOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(AppTheme.surface(colorScheme == .dark).opacity(0.98))
                .overlay {
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .strokeBorder(AppTheme.border(colorScheme == .dark), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.16), radius: 22, y: 10)
            VStack(spacing: 7) {
                Image(systemName: model.isShowingWin ? "sparkles" : "flag.checkered")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(red: 0.66, green: 0.49, blue: 0.24))
                Text(model.isShowingWin ? "You made it!" : "No more moves")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))
                Text(
                    model.isShowingWin
                        ? "You reached 2048." : "Your score is \(model.game.score.formatted())."
                )
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
                if model.isShowingWin {
                    overlayButton("Keep playing") {
                        model.continuePlaying()
                    }
                }
                overlayButton("Restart") {
                    model.startNewGame()
                }
                overlayButton("Main menu") {
                    model.endGame()
                }
                .padding(.top, 2)
            }
            .padding(16)
            .frame(maxWidth: 300)
        }
        .padding(boardSpacing)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func overlayButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82), action)
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
        }
        .buttonStyle(GameGlassButtonStyle())
    }

    private func move(_ direction: MoveDirection) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            model.move(direction)
        }
    }

    private func tileColors(for value: Int) -> (background: Color, foreground: Color) {
        tilePalette.colors(for: value)
    }
}

#if os(macOS)
    private struct MacArrowKeyHandler: NSViewRepresentable {
        let onMove: (MoveDirection) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(onMove: onMove)
        }

        func makeNSView(context: Context) -> NSView {
            let view = NSView(frame: .zero)
            context.coordinator.start()
            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {
        }

        static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
            coordinator.stop()
        }

        @MainActor
        final class Coordinator: @unchecked Sendable {
            let onMove: (MoveDirection) -> Void
            private var eventMonitor: Any?

            init(onMove: @escaping (MoveDirection) -> Void) {
                self.onMove = onMove
            }

            func start() {
                guard eventMonitor == nil else { return }
                eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    guard event.modifierFlags.intersection([.command, .control, .option]).isEmpty,
                        let direction = Self.direction(for: event.keyCode)
                    else {
                        return event
                    }

                    Task { @MainActor [weak self] in
                        self?.onMove(direction)
                    }
                    return nil
                }
            }

            func stop() {
                guard let eventMonitor else { return }
                NSEvent.removeMonitor(eventMonitor)
                self.eventMonitor = nil
            }

            private static func direction(for keyCode: UInt16) -> MoveDirection? {
                switch keyCode {
                case 123: .left
                case 124: .right
                case 125: .down
                case 126: .up
                default: nil
                }
            }
        }
    }
#endif
