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
                GameBoardView(game: game)
                    .padding()

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
                                    tileType: tile,
                                    isSelected: game.selectedPosition == position,
                                    isMatched: game.matchedPositions.contains(position),
                                    isRemoving: game.removingPositions.contains(position),
                                    size: tileSize
                                )
                                .onTapGesture {
                                    handleTileTap(row: row, col: col)
                                }
                            } else {
                                // 空のタイル（nilの場合）
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: tileSize, height: tileSize)
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
}

// タイルビュー
struct TileView: View {
    let tileType: TileType
    let isSelected: Bool
    let isMatched: Bool
    let isRemoving: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            // タイル本体
            RoundedRectangle(cornerRadius: 8)
                .fill(tileType.color)
                .frame(width: size, height: size)
                .shadow(radius: isSelected ? 5 : 2)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .opacity(isRemoving ? 0 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
                .animation(.easeOut(duration: 0.3), value: isRemoving)

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
                            .fill(tileType.color)
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
