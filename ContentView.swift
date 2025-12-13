import SwiftUI

enum GameScreen {
    case title
    case stageSelect
    case game
}

struct ContentView: View {
    @StateObject private var stageManager = StageManager()
    @State private var currentScreen: GameScreen = .title
    @State private var selectedStage: Stage?
    @State private var game: GameModel?

    var body: some View {
        ZStack {
            switch currentScreen {
            case .title:
                TitleView(onStart: {
                    currentScreen = .stageSelect
                })
            case .stageSelect:
                StageSelectView(
                    stageManager: stageManager,
                    onStageSelected: { stage in
                        selectedStage = stage
                        game = GameModel(stage: stage)
                        currentScreen = .game
                    },
                    onBackToTitle: {
                        currentScreen = .title
                    }
                )
            case .game:
                if let game = game {
                    GameView(
                        game: game,
                        onBackToTitle: {
                            currentScreen = .title
                        },
                        onBackToStageSelect: {
                            currentScreen = .stageSelect
                        },
                        onNextStage: {
                            // 次のステージをアンロック
                            if let currentStage = game.currentStage {
                                let nextStageNumber = currentStage.number + 1
                                if nextStageNumber <= Stage.stages.count {
                                    stageManager.unlockStage(nextStageNumber)
                                }
                            }
                            currentScreen = .stageSelect
                        }
                    )
                }
            }
        }
    }
}

// タイトル画面
struct TitleView: View {
    let onStart: () -> Void

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 50) {
                Spacer()

                // タイトル
                VStack(spacing: 20) {
                    Text("マッチ3パズル")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                    Text("Match 3 Puzzle")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // ゲーム説明
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.white)
                        Text("隣接するタイルを入れ替えて")
                            .foregroundColor(.white)
                    }

                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("3つ以上揃えて消そう！")
                            .foregroundColor(.white)
                    }

                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.orange)
                        Text("目標: 3000点")
                            .foregroundColor(.white)
                    }

                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.green)
                        Text("残り手数: 5手")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(15)

                Spacer()

                // スタートボタン
                Button(action: onStart) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("START")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)

                Spacer()
            }
            .padding()
        }
    }
}

// ステージ選択画面
struct StageSelectView: View {
    @ObservedObject var stageManager: StageManager
    let onStageSelected: (Stage) -> Void
    let onBackToTitle: () -> Void

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // タイトル
                Text("STAGE SELECT")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.top, 40)

                // ステージ一覧
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(stageManager.getAvailableStages(), id: \.number) { stage in
                            StageButton(
                                stage: stage,
                                isUnlocked: stage.isUnlocked,
                                onTap: {
                                    if stage.isUnlocked {
                                        onStageSelected(stage)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }

                // 戻るボタン
                Button(action: onBackToTitle) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back to Title")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(Color.gray.opacity(0.7))
                    .cornerRadius(15)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// ステージボタン
struct StageButton: View {
    let stage: Stage
    let isUnlocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // ステージ番号
                Text("STAGE \(stage.number)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 150, alignment: .leading)

                Spacer()

                // ステージ情報
                VStack(alignment: .trailing, spacing: 5) {
                    Text(stage.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    HStack(spacing: 15) {
                        HStack {
                            Image(systemName: "target")
                            Text("\(stage.targetScore)")
                                .font(.caption)
                        }
                        HStack {
                            Image(systemName: "hand.tap.fill")
                            Text("\(stage.maxMoves)")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.white.opacity(0.9))
                }

                // ロックアイコン
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.title2)
                        .padding(.leading, 10)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: isUnlocked ?
                        [Color.blue.opacity(0.8), Color.purple.opacity(0.8)] :
                        [Color.gray.opacity(0.5), Color.gray.opacity(0.7)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(15)
            .shadow(radius: isUnlocked ? 5 : 2)
        }
        .disabled(!isUnlocked)
    }
}

// ゲーム画面
struct GameView: View {
    @ObservedObject var game: GameModel
    let onBackToTitle: () -> Void
    let onBackToStageSelect: () -> Void
    let onNextStage: () -> Void

    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.1)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // ステージ情報とタイトル
                VStack(spacing: 5) {
                    if let stage = game.currentStage {
                        Text("STAGE \(stage.number) - \(stage.name)")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Text("Match3 Puzzle")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                // スコアと手数表示
                HStack(spacing: 40) {
                    VStack {
                        Text("SCORE")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(game.score))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }

                    VStack {
                        Text("TARGET")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(game.targetScore))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }

                    VStack {
                        Text("MOVES")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(game.movesLeft))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(game.movesLeft <= 2 ? .red : .black)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 5)

                // ゲームボード
                ZStack {
                    GameBoardView(game: game)
                        .padding()

                    // 連鎖ポップアップ
                    if game.showChainPopup && game.chainCount >= 2 {
                        ChainPopupView(chainCount: game.chainCount)
                    }
                }

                // ボタン群
                HStack(spacing: 15) {
                    Button(action: {
                        game.resetGame()
                    }) {
                        Text("Restart")
                            .font(.headline)
                            .padding()
                            .frame(width: 110)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: onBackToStageSelect) {
                        Text("Stages")
                            .font(.headline)
                            .padding()
                            .frame(width: 110)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: onBackToTitle) {
                        Text("Title")
                            .font(.headline)
                            .padding()
                            .frame(width: 110)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }

                // デバッグモード切り替えボタン
                Button(action: {
                    game.debugMode.toggle()
                }) {
                    HStack {
                        Image(systemName: game.debugMode ? "ant.fill" : "ant")
                        Text("Debug")
                    }
                    .font(.caption)
                    .padding(8)
                    .background(game.debugMode ? Color.red.opacity(0.8) : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                // デバッグパネル
                if game.debugMode {
                    DebugPanel(game: game)
                }
            }
            .padding()

            // ゲームオーバー/クリアのオーバーレイ
            if game.isGameOver {
                GameOverView(
                    isCleared: game.isGameCleared,
                    score: game.score,
                    hasNextStage: game.currentStage != nil && game.currentStage!.number < Stage.stages.count,
                    onRestart: {
                        game.resetGame()
                    },
                    onNextStage: onNextStage,
                    onBackToStageSelect: onBackToStageSelect,
                    onBackToTitle: onBackToTitle
                )
            }
        }
    }
}

// ゲームボードビュー
struct GameBoardView: View {
    @ObservedObject var game: GameModel

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let tileSize = (size - CGFloat(GameModel.gridSize + 1) * 4) / CGFloat(GameModel.gridSize)

            VStack(spacing: 4) {
                ForEach(0..<GameModel.gridSize, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<GameModel.gridSize, id: \.self) { col in
                            let position = Position(row: row, col: col)
                            if let tile = game.board[row][col] {
                                TileView(
                                    tile: tile,
                                    isSelected: game.selectedPosition == position,
                                    isMatched: game.matchedPositions.contains(position),
                                    isRemoving: game.removingPositions.contains(position),
                                    size: tileSize
                                )
                                .onTapGesture {
                                    handleTileTap(row: row, col: col)
                                }
                            } else {
                                // 空のタイル（nilの場合）- 穴か一時的な空白か判定
                                if isHole(position: position) {
                                    // 穴の場合は黒背景
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.8))
                                        .frame(width: tileSize, height: tileSize)
                                } else {
                                    // 一時的な空白（落下中）
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: tileSize, height: tileSize)
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: size, height: size)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(10)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func handleTileTap(row: Int, col: Int) {
        let position = Position(row: row, col: col)

        if let selected = game.selectedPosition {
            // 2つ目のタイルをタップ → スワップ実行
            game.swapTiles(from: selected, to: position)
        } else {
            // 1つ目のタイルを選択
            game.selectedPosition = position
        }
    }

    private func isHole(position: Position) -> Bool {
        guard let stage = game.currentStage else { return false }
        return stage.boardShape.holes.contains(position)
    }
}

// タイルビュー
struct TileView: View {
    let tile: Tile
    let isSelected: Bool
    let isMatched: Bool
    let isRemoving: Bool
    let size: CGFloat
    @State private var specialScale: CGFloat = 0.3

    var body: some View {
        ZStack {
            // タイル本体
            RoundedRectangle(cornerRadius: 8)
                .fill(tile.type.color)
                .frame(width: size, height: size)
                .shadow(radius: isSelected ? 5 : 2)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .opacity(isRemoving ? 0 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
                .animation(.easeOut(duration: 0.3), value: isRemoving)

            // 障害物の表示（最優先）
            ObstacleOverlay(obstacle: tile.obstacle, size: size)

            // 特殊タイルのマーク（アニメーション付き）
            if tile.special != .none {
                SpecialTileOverlay(specialType: tile.special, size: size)
                    .scaleEffect(specialScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                            specialScale = 1.1
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                specialScale = 1.0
                            }
                        }
                    }
            }

            // 選択時の白枠
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: size, height: size)
            }

            // マッチ時の光るエフェクト
            if isMatched {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.6))
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.yellow, lineWidth: 4)
                    )
                    .scaleEffect(1.2)
                    .animation(.easeInOut(duration: 0.3).repeatCount(2, autoreverses: true), value: isMatched)
            }

            // 消去時のパーティクルエフェクト
            if isRemoving {
                ZStack {
                    ForEach(0..<8, id: \.self) { i in
                        Circle()
                            .fill(tile.type.color)
                            .frame(width: size * 0.2, height: size * 0.2)
                            .offset(
                                x: cos(Double(i) * .pi / 4) * size * 0.6,
                                y: sin(Double(i) * .pi / 4) * size * 0.6
                            )
                            .opacity(0)
                            .animation(.easeOut(duration: 0.3), value: isRemoving)
                    }
                }
            }
        }
    }
}

// 障害物のオーバーレイ表示
struct ObstacleOverlay: View {
    let obstacle: ObstacleType
    let size: CGFloat

    var body: some View {
        switch obstacle {
        case .none:
            EmptyView()

        case .frozen:
            // 凍結エフェクト
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cyan.opacity(0.4))
                    .frame(width: size, height: size)
                Image(systemName: "snowflake")
                    .foregroundColor(.white)
                    .font(.system(size: size * 0.35, weight: .bold))
                    .shadow(color: .cyan, radius: 4, x: 0, y: 0)
            }

        case .chained:
            // 鎖エフェクト
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: size, height: size)
                Image(systemName: "lock.fill")
                    .foregroundColor(.white)
                    .font(.system(size: size * 0.35, weight: .bold))
                    .shadow(color: .black, radius: 4, x: 0, y: 0)
            }

        case .breakable(let hp):
            // 壊せるブロックエフェクト
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.brown.opacity(0.6))
                    .frame(width: size, height: size)
                VStack(spacing: 2) {
                    Image(systemName: "cube.fill")
                        .foregroundColor(.white)
                        .font(.system(size: size * 0.25, weight: .bold))
                    Text("HP\(hp)")
                        .foregroundColor(.white)
                        .font(.system(size: size * 0.2, weight: .bold))
                }
                .shadow(color: .black, radius: 3, x: 0, y: 0)
            }

        case .hole:
            // 穴（タイル表示しない）
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.8))
                .frame(width: size, height: size)
        }
    }
}

// 特殊タイルのオーバーレイ表示
struct SpecialTileOverlay: View {
    let specialType: SpecialType
    let size: CGFloat

    var body: some View {
        ZStack {
            switch specialType {
            case .none:
                EmptyView()
            case .horizontalLine:
                // 背景の円
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: size * 0.6, height: size * 0.6)
                Image(systemName: "arrow.left.and.right")
                    .foregroundColor(.white)
                    .font(.system(size: size * 0.5, weight: .black))
                    .shadow(color: .black, radius: 3, x: 0, y: 0)
            case .verticalLine:
                // 背景の円
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: size * 0.6, height: size * 0.6)
                Image(systemName: "arrow.up.and.down")
                    .foregroundColor(.white)
                    .font(.system(size: size * 0.5, weight: .black))
                    .shadow(color: .black, radius: 3, x: 0, y: 0)
            case .bomb:
                // 背景の円
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: size * 0.6, height: size * 0.6)
                Image(systemName: "burst.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: size * 0.5, weight: .black))
                    .shadow(color: .black, radius: 3, x: 0, y: 0)
            case .rainbow:
                // 背景の円（グラデーション）
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.7, height: size * 0.7)
                Image(systemName: "star.fill")
                    .foregroundColor(.white)
                    .font(.system(size: size * 0.5, weight: .black))
                    .shadow(color: .black, radius: 3, x: 0, y: 0)
            }
        }
    }
}

// 連鎖ポップアップ
struct ChainPopupView: View {
    let chainCount: Int

    var body: some View {
        VStack {
            Text("\(chainCount) CHAIN!")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            Text("×\(String(format: "%.1f", calculateMultiplier(chain: chainCount)))")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.yellow)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(20)
        .scaleEffect(1.2)
        .animation(.spring(response: 0.3), value: chainCount)
    }

    private func calculateMultiplier(chain: Int) -> Double {
        switch chain {
        case 2: return 1.2
        case 3: return 1.5
        case 4: return 2.0
        case 5: return 2.5
        default: return 3.0
        }
    }
}

// デバッグパネル
struct DebugPanel: View {
    @ObservedObject var game: GameModel

    var body: some View {
        VStack(spacing: 10) {
            Text("🐛 DEBUG MODE")
                .font(.headline)
                .foregroundColor(.red)

            // ゲーム情報
            VStack(alignment: .leading, spacing: 5) {
                Text("Chain: \(game.chainCount)")
                    .font(.caption)
                Text("Animating: \(game.isAnimating ? "YES" : "NO")")
                    .font(.caption)
                Text("Selected: \(game.selectedPosition != nil ? "(\(game.selectedPosition!.row), \(game.selectedPosition!.col))" : "None")")
                    .font(.caption)
            }
            .padding(8)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)

            // 特殊タイル生成ボタン
            if let pos = game.selectedPosition {
                Text("Special Tiles at (\(pos.row), \(pos.col))")
                    .font(.caption)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Button(action: {
                        game.debugCreateSpecialTile(at: pos, type: .horizontalLine)
                    }) {
                        Image(systemName: "arrow.left.and.right")
                            .frame(width: 35, height: 35)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }

                    Button(action: {
                        game.debugCreateSpecialTile(at: pos, type: .verticalLine)
                    }) {
                        Image(systemName: "arrow.up.and.down")
                            .frame(width: 35, height: 35)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }

                    Button(action: {
                        game.debugCreateSpecialTile(at: pos, type: .bomb)
                    }) {
                        Image(systemName: "burst.fill")
                            .frame(width: 35, height: 35)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }

                    Button(action: {
                        game.debugCreateSpecialTile(at: pos, type: .rainbow)
                    }) {
                        Image(systemName: "star.fill")
                            .frame(width: 35, height: 35)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.red, .yellow, .green, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }

                Text("Obstacles at (\(pos.row), \(pos.col))")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.top, 5)

                HStack(spacing: 8) {
                    Button(action: {
                        game.debugSetObstacle(at: pos, obstacle: .frozen)
                    }) {
                        Image(systemName: "snowflake")
                            .frame(width: 35, height: 35)
                            .background(Color.cyan)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }

                    Button(action: {
                        game.debugSetObstacle(at: pos, obstacle: .chained)
                    }) {
                        Image(systemName: "lock.fill")
                            .frame(width: 35, height: 35)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }

                    Button(action: {
                        game.debugSetObstacle(at: pos, obstacle: .breakable(hp: 2))
                    }) {
                        Text("HP2")
                            .font(.caption.bold())
                            .frame(width: 35, height: 35)
                            .background(Color.brown)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }

                    Button(action: {
                        game.debugSetObstacle(at: pos, obstacle: .none)
                    }) {
                        Image(systemName: "xmark")
                            .frame(width: 35, height: 35)
                            .background(Color.red.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            } else {
                Text("Select a tile for debug options")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(15)
    }
}

// ゲームオーバービュー
struct GameOverView: View {
    let isCleared: Bool
    let score: Int
    let hasNextStage: Bool
    let onRestart: () -> Void
    let onNextStage: () -> Void
    let onBackToStageSelect: () -> Void
    let onBackToTitle: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text(isCleared ? "🎉 CLEAR!" : "GAME OVER")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                Text("Score: " + String(score))
                    .font(.title)
                    .foregroundColor(.white)

                VStack(spacing: 15) {
                    if isCleared && hasNextStage {
                        Button(action: onNextStage) {
                            HStack {
                                Text("Next Stage")
                                Image(systemName: "chevron.right")
                            }
                            .font(.title2)
                            .padding()
                            .frame(width: 220)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }

                    Button(action: onRestart) {
                        Text(isCleared ? "Play Again" : "Retry")
                            .font(.headline)
                            .padding()
                            .frame(width: 220)
                            .background(isCleared ? Color.blue : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }

                    Button(action: onBackToStageSelect) {
                        Text("Stage Select")
                            .font(.headline)
                            .padding()
                            .frame(width: 220)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }

                    Button(action: onBackToTitle) {
                        Text("Back to Title")
                            .font(.headline)
                            .padding()
                            .frame(width: 220)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
            }
            .padding(40)
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)
        }
    }
}
