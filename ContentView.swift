import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameModel()

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
                        Text("\(game.score)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    VStack {
                        Text("TARGET")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(GameModel.targetScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }

                    VStack {
                        Text("MOVES")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(game.movesLeft)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(game.movesLeft <= 5 ? .red : .primary)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 5)

                // ゲームボード
                GameBoardView(game: game)
                    .padding()

                // リセットボタン
                Button(action: {
                    game.resetGame()
                }) {
                    Text("New Game")
                        .font(.headline)
                        .padding()
                        .frame(width: 200)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
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
                    }
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
                            TileView(
                                tileType: game.board[row][col],
                                isSelected: game.selectedPosition == Position(row: row, col: col),
                                size: tileSize
                            )
                            .onTapGesture {
                                handleTileTap(row: row, col: col)
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
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(tileType.color)
                .frame(width: size, height: size)
                .shadow(radius: isSelected ? 5 : 2)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)

            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: size, height: size)
            }
        }
    }
}

// ゲームオーバービュー
struct GameOverView: View {
    let isCleared: Bool
    let score: Int
    let onRestart: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text(isCleared ? "🎉 CLEAR!" : "GAME OVER")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                Text("Score: \(score)")
                    .font(.title)
                    .foregroundColor(.white)

                Button(action: onRestart) {
                    Text("Play Again")
                        .font(.title2)
                        .padding()
                        .frame(width: 200)
                        .background(isCleared ? Color.green : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
            }
            .padding(40)
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)
        }
    }
}
