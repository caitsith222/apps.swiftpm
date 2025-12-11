import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameModel()
    @State private var showTitle = true

    var body: some View {
        ZStack {
            if showTitle {
                TitleView(onStart: {
                    showTitle = false
                })
            } else {
                GameView(game: game, onBackToTitle: {
                    game.resetGame()
                    showTitle = true
                })
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
                        Text("残り手数: 20手")
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

// ゲーム画面
struct GameView: View {
    @ObservedObject var game: GameModel
    let onBackToTitle: () -> Void

    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.1)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // タイトル
                Text("Match3 Puzzle")
                    .font(.largeTitle)
                    .fontWeight(.bold)

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
                        Text(String(GameModel.targetScore))
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
                            .foregroundColor(game.movesLeft <= 5 ? .red : .black)
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
                HStack(spacing: 20) {
                    Button(action: {
                        game.resetGame()
                    }) {
                        Text("Restart")
                            .font(.headline)
                            .padding()
                            .frame(width: 140)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: onBackToTitle) {
                        Text("Title")
                            .font(.headline)
                            .padding()
                            .frame(width: 140)
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
                    onRestart: {
                        game.resetGame()
                    },
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
    let onRestart: () -> Void
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
                    Button(action: onRestart) {
                        Text("Play Again")
                            .font(.title2)
                            .padding()
                            .frame(width: 200)
                            .background(isCleared ? Color.green : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }

                    Button(action: onBackToTitle) {
                        Text("Back to Title")
                            .font(.headline)
                            .padding()
                            .frame(width: 200)
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
