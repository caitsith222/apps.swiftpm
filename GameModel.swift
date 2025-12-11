import Foundation
import SwiftUI

// タイルの種類（5種類）
enum TileType: Int, CaseIterable {
    case red = 0
    case blue = 1
    case green = 2
    case yellow = 3
    case purple = 4

    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .purple: return .purple
        }
    }

    static func random() -> TileType {
        TileType.allCases.randomElement()!
    }
}

// タイルの位置
struct Position: Equatable, Hashable {
    let row: Int
    let col: Int
}

// ゲーム状態を管理
class GameModel: ObservableObject {
    static let gridSize = 8
    static let maxMoves = 20
    static let targetScore = 3000
    static let baseScore = 100  // 3タイル消去の基本点

    @Published var board: [[TileType]]
    @Published var score: Int = 0
    @Published var movesLeft: Int = maxMoves
    @Published var isGameOver: Bool = false
    @Published var isGameCleared: Bool = false
    @Published var selectedPosition: Position?
    @Published var isAnimating: Bool = false
    @Published var matchedPositions: Set<Position> = []  // マッチしたタイルの位置
    @Published var removingPositions: Set<Position> = []  // 消去中のタイルの位置

    init() {
        // 初期盤面をランダムに生成（3つ揃いがない状態）
        board = [[TileType]]()
        for _ in 0..<GameModel.gridSize {
            var row = [TileType]()
            for _ in 0..<GameModel.gridSize {
                row.append(TileType.random())
            }
            board.append(row)
        }

        // 初期状態で3つ揃いがあれば消す
        removeInitialMatches()
    }

    // 初期盤面の揃いを除去
    private func removeInitialMatches() {
        var hasMatches = true
        while hasMatches {
            let matches = findAllMatches()
            if matches.isEmpty {
                hasMatches = false
            } else {
                removeMatches(matches)
                applyGravity()
                refillBoard()
            }
        }
    }

    // すべてのマッチを検出
    func findAllMatches() -> Set<Position> {
        var matches = Set<Position>()

        // 横方向のマッチを検出
        for row in 0..<GameModel.gridSize {
            var matchStart = 0
            for col in 1..<GameModel.gridSize {
                if board[row][col] != board[row][col - 1] {
                    if col - matchStart >= 3 {
                        for i in matchStart..<col {
                            matches.insert(Position(row: row, col: i))
                        }
                    }
                    matchStart = col
                }
            }
            // 行の最後をチェック
            if GameModel.gridSize - matchStart >= 3 {
                for i in matchStart..<GameModel.gridSize {
                    matches.insert(Position(row: row, col: i))
                }
            }
        }

        // 縦方向のマッチを検出
        for col in 0..<GameModel.gridSize {
            var matchStart = 0
            for row in 1..<GameModel.gridSize {
                if board[row][col] != board[row - 1][col] {
                    if row - matchStart >= 3 {
                        for i in matchStart..<row {
                            matches.insert(Position(row: i, col: col))
                        }
                    }
                    matchStart = row
                }
            }
            // 列の最後をチェック
            if GameModel.gridSize - matchStart >= 3 {
                for i in matchStart..<GameModel.gridSize {
                    matches.insert(Position(row: i, col: col))
                }
            }
        }

        return matches
    }

    // タイルを交換
    func swapTiles(from: Position, to: Position) {
        guard !isAnimating else { return }
        guard isAdjacentPosition(from, to) else { return }

        isAnimating = true

        // スワップアニメーション用に少し待つ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            // 交換実行
            let temp = self.board[from.row][from.col]
            self.board[from.row][from.col] = self.board[to.row][to.col]
            self.board[to.row][to.col] = temp

            // マッチがあるかチェック
            let matches = self.findAllMatches()

            if matches.isEmpty {
                // マッチがない場合は元に戻す
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self = self else { return }
                    let temp = self.board[from.row][from.col]
                    self.board[from.row][from.col] = self.board[to.row][to.col]
                    self.board[to.row][to.col] = temp
                    self.isAnimating = false
                }
            } else {
                // マッチがある場合は手数を減らして処理
                self.movesLeft -= 1
                self.processMatches(matches)
                self.checkGameState()
            }

            self.selectedPosition = nil
        }
    }

    // 隣接チェック
    private func isAdjacentPosition(_ pos1: Position, _ pos2: Position) -> Bool {
        let rowDiff = abs(pos1.row - pos2.row)
        let colDiff = abs(pos1.col - pos2.col)
        return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1)
    }

    // マッチ処理（消去→落下→補充のループ）
    private func processMatches(_ matches: Set<Position>) {
        // マッチしたタイルをハイライト表示
        matchedPositions = matches

        // スコア加算
        let matchCount = matches.count
        if matchCount == 3 {
            score += GameModel.baseScore
        } else if matchCount == 4 {
            score += GameModel.baseScore * 2
        } else if matchCount >= 5 {
            score += GameModel.baseScore * 3
        }

        // 0.5秒後に消去エフェクト開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.removingPositions = matches
            self.matchedPositions = []

            // 0.3秒後にタイル消去
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                self.removeMatches(matches)
                self.removingPositions = []

                // 落下アニメーション
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.applyGravity()
                    self?.refillBoard()

                    // 連鎖チェック
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.checkForCascade()
                    }
                }
            }
        }
    }

    // 連鎖チェック
    private func checkForCascade() {
        let matches = findAllMatches()
        if !matches.isEmpty {
            processMatches(matches)
        } else {
            isAnimating = false
        }
    }

    // マッチしたタイルを削除（新しいランダムタイルで置き換え）
    private func removeMatches(_ matches: Set<Position>) {
        for match in matches {
            board[match.row][match.col] = TileType.random()
        }
    }

    // 重力適用（タイルを下に落とす）
    private func applyGravity() {
        for col in 0..<GameModel.gridSize {
            var emptyRow = GameModel.gridSize - 1
            for row in stride(from: GameModel.gridSize - 1, through: 0, by: -1) {
                if board[row][col] != board[emptyRow][col] {
                    board[emptyRow][col] = board[row][col]
                }
                emptyRow -= 1
            }
        }
    }

    // 盤面を補充（上から新しいタイルを追加）
    private func refillBoard() {
        for row in 0..<GameModel.gridSize {
            for col in 0..<GameModel.gridSize {
                board[row][col] = TileType.random()
            }
        }
    }

    // ゲーム状態チェック
    private func checkGameState() {
        if score >= GameModel.targetScore {
            isGameCleared = true
            isGameOver = true
        } else if movesLeft <= 0 {
            isGameOver = true
        }
    }

    // ゲームリセット
    func resetGame() {
        board = [[TileType]]()
        for _ in 0..<GameModel.gridSize {
            var row = [TileType]()
            for _ in 0..<GameModel.gridSize {
                row.append(TileType.random())
            }
            board.append(row)
        }
        removeInitialMatches()
        score = 0
        movesLeft = GameModel.maxMoves
        isGameOver = false
        isGameCleared = false
        selectedPosition = nil
        matchedPositions = []
        removingPositions = []
        isAnimating = false
    }
}
