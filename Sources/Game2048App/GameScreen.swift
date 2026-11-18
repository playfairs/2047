import SwiftUI

#if SWIFT_PACKAGE
import Game2048Core
#endif

private struct BoardTile: Identifiable {
    let id: UUID
    let index: Int
    let value: Int
}

struct GameScreen: View {
    @StateObject private var model = GameViewModel()
    @State private var showsStatistics = false
    #if os(macOS)
    @FocusState private var isBoardFocused: Bool
    #endif

    private let boardSpacing: CGFloat = 10
    private let background = Color(red: 0.96, green: 0.95, blue: 0.91)

    var body: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width - 44, max(240, geometry.size.height - 350), 520)

            ZStack {
                background.ignoresSafeArea()
                RadialGradient(
                    colors: [Color.white.opacity(0.8), background.opacity(0)],
                    center: .top,
                    startRadius: 20,
                    endRadius: 650
                )
                .ignoresSafeArea()

                ScrollView(.vertical) {
                    VStack(spacing: 24) {
                        header
                        scores
                        board(size: boardSize)
                        controls
                        timerFooter
                    }
                    .frame(maxWidth: 560)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 28)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(NotificationCenter.default.publisher(for: .startNewGame)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                model.startNewGame()
            }
        }
        .sheet(isPresented: $showsStatistics) {
            StatisticsView(model: model)
        }
        #if os(macOS)
        .focusable()
        .focused($isBoardFocused)
        .onMoveCommand { command in
            switch command {
            case .left: move(.left)
            case .right: move(.right)
            case .up: move(.up)
            case .down: move(.down)
            @unknown default: break
            }
        }
        .onAppear {
            isBoardFocused = true
        }
        #endif
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("2048")
                    .font(.system(size: 43, weight: .black, design: .rounded))
                    .tracking(-2.2)
                    .foregroundStyle(Color(red: 0.31, green: 0.29, blue: 0.25))
                Text("Join the numbers.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.53, green: 0.50, blue: 0.45))
            }
            Spacer(minLength: 4)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    model.startNewGame()
                }
            } label: {
                Label("New game", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.34, green: 0.32, blue: 0.29))
                    .padding(.horizontal, 15)
                    .frame(height: 46)
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
            Button {
                showsStatistics = true
            } label: {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.37, green: 0.34, blue: 0.29))
                    .frame(width: 48, height: 48)
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(GameGlassButtonStyle())
            .accessibilityLabel("Statistics")
        }
    }

    private var timerFooter: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack {
                Text("Swipe or use the arrow keys")
                Spacer()
                Label(
                    formattedGameTime(model.elapsedTime(at: context.date)),
                    systemImage: "timer"
                )
                .monospacedDigit()
                .accessibilityLabel("Elapsed time \(formattedGameTime(model.elapsedTime(at: context.date)))")
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(Color(red: 0.48, green: 0.46, blue: 0.42))
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
                            Color(red: 0.57, green: 0.50, blue: 0.42)
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
        let cellSize = (size - boardSpacing * 5) / 4
        let visibleTiles = model.game.tiles.indices.compactMap { index -> BoardTile? in
            guard let id = model.game.tileIDs[index] else { return nil }
            return BoardTile(id: id, index: index, value: model.game.tiles[index])
        }

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color(red: 0.72, green: 0.67, blue: 0.59))
                .shadow(color: .black.opacity(0.13), radius: 20, y: 11)

            VStack(spacing: boardSpacing) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: boardSpacing) {
                        ForEach(0..<4, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: cellSize * 0.16, style: .continuous)
                                .fill(Color(red: 0.83, green: 0.79, blue: 0.72).opacity(0.55))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            .padding(boardSpacing)

            ForEach(visibleTiles) { boardTile in
                tile(boardTile.value, size: cellSize)
                    .position(
                        x: boardSpacing + CGFloat(boardTile.index % 4) * (cellSize + boardSpacing) + cellSize / 2,
                        y: boardSpacing + CGFloat(boardTile.index / 4) * (cellSize + boardSpacing) + cellSize / 2
                    )
                    .transition(.asymmetric(
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
        HStack(spacing: 12) {
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
                .foregroundStyle(Color(red: 0.37, green: 0.34, blue: 0.29))
                .frame(width: 50, height: 46)
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(GameGlassButtonStyle())
        .accessibilityLabel("Move \(String(describing: direction))")
    }

    private var gameOverOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.92))
            VStack(spacing: 12) {
                Image(systemName: model.isShowingWin ? "sparkles" : "flag.checkered")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color(red: 0.66, green: 0.49, blue: 0.24))
                Text(model.isShowingWin ? "You made it!" : "No more moves")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.31, green: 0.29, blue: 0.25))
                Text(model.isShowingWin ? "You reached 2048." : "Your score is \(model.game.score.formatted()).")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.48, green: 0.46, blue: 0.42))
                HStack(spacing: 10) {
                    if model.isShowingWin {
                        overlayButton("Keep playing") {
                            model.continuePlaying()
                        }
                    }
                    overlayButton("New game") {
                        model.startNewGame()
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
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
                .foregroundStyle(Color(red: 0.34, green: 0.32, blue: 0.29))
                .padding(.horizontal, 15)
                .frame(height: 42)
        }
        .buttonStyle(GameGlassButtonStyle())
    }

    private func move(_ direction: MoveDirection) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            model.move(direction)
        }
    }

    private func tileColors(for value: Int) -> (background: Color, foreground: Color) {
        switch value {
        case 0: (Color(red: 0.83, green: 0.79, blue: 0.72).opacity(0.55), .clear)
        case 2: (Color(red: 0.93, green: 0.90, blue: 0.84), Color(red: 0.42, green: 0.39, blue: 0.34))
        case 4: (Color(red: 0.92, green: 0.86, blue: 0.73), Color(red: 0.42, green: 0.39, blue: 0.34))
        case 8: (Color(red: 0.92, green: 0.67, blue: 0.46), .white)
        case 16: (Color(red: 0.91, green: 0.54, blue: 0.36), .white)
        case 32: (Color(red: 0.89, green: 0.43, blue: 0.34), .white)
        case 64: (Color(red: 0.84, green: 0.30, blue: 0.23), .white)
        case 128: (Color(red: 0.87, green: 0.70, blue: 0.36), .white)
        case 256: (Color(red: 0.85, green: 0.65, blue: 0.25), .white)
        case 512: (Color(red: 0.80, green: 0.58, blue: 0.18), .white)
        case 1024: (Color(red: 0.74, green: 0.50, blue: 0.12), .white)
        default: (Color(red: 0.68, green: 0.44, blue: 0.12), .white)
        }
    }
}
