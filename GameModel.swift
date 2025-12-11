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
    static let baseScore = 100  // 3タイル消去の基本点

    @Published var board: [[TileType?]]
    @Published var score: Int = 0
    @Published var movesLeft: Int = 0
    @Published var isGameOver: Bool = false
    @Published var isGameCleared: Bool = false
    @Published var selectedPosition: Position?
    @Published var isAnimating: Bool = false
    @Published var matchedPositions: Set<Position> = []  // マッチしたタイルの位置
    @Published var removingPositions: Set<Position> = []  // 消去中のタイルの位置

    var currentStage: Stage?
    var targetScore: Int = 3000
    var maxMoves: Int = 5

    init(stage: Stage? = nil) {
        // ステージ設定を適用
        if let stage = stage {
            self.currentStage = stage
            self.targetScore = stage.targetScore
            self.maxMoves = stage.maxMoves
        }

        // 初期盤面をランダムに生成（3つ揃いがない状態）
        board = [[TileType?]]()
        for _ in 0..<GameModel.gridSize {
            var row = [TileType?]()
            for _ in 0..<GameModel.gridSize {
                row.append(TileType.random())
            }
            board.append(row)
        }

        // 手数を初期化
        movesLeft = maxMoves

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
            var col = 0
            while col < GameModel.gridSize {
                guard let currentTile = board[row][col] else {
                    col += 1
                    continue
                }

                var matchLength = 1
                var checkCol = col + 1

                while checkCol < GameModel.gridSize, board[row][checkCol] == currentTile {
                    matchLength += 1
                    checkCol += 1
                }

                if matchLength >= 3 {
                    for i in col..<(col + matchLength) {
                        matches.insert(Position(row: row, col: i))
                    }
                }

                col = checkCol
            }
        }

        // 縦方向のマッチを検出
        for col in 0..<GameModel.gridSize {
            var row = 0
            while row < GameModel.gridSize {
                guard let currentTile = board[row][col] else {
                    row += 1
                    continue
                }

                var matchLength = 1
                var checkRow = row + 1

                while checkRow < GameModel.gridSize, board[checkRow][col] == currentTile {
                    matchLength += 1
                    checkRow += 1
                }

                if matchLength >= 3 {
                    for i in row..<(row + matchLength) {
                        matches.insert(Position(row: i, col: col))
                    }
                }

                row = checkRow
            }
        }

        return matches
    }

    // タイルを交換
    func swapTiles(from: Position, to: Position) {
        guard !isAnimating else { return }
        guard isAdjacentPosition(from, to) else { return }

        // 両方のタイルが存在することを確認
        guard board[from.row][from.col] != nil, board[to.row][to.col] != nil else {
            selectedPosition = nil
            return
        }

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
                // マッチがない場合は元に戻す（手数は減らさない）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self = self else { return }
                    let temp = self.board[from.row][from.col]
                    self.board[from.row][from.col] = self.board[to.row][to.col]
                    self.board[to.row][to.col] = temp
                    self.isAnimating = false
                }
            } else {
                // マッチがある場合は手数を減らして処理
                DispatchQueue.main.async {
                    self.movesLeft -= 1
                }
                self.processMatches(matches)
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
        DispatchQueue.main.async {
            self.matchedPositions = matches
        }

        // スコア加算：消去数 × 基本点
        let matchCount = matches.count
        DispatchQueue.main.async {
            self.score += matchCount * GameModel.baseScore

            // スコア更新直後にゲーム状態をチェック
            self.checkGameState()

            // ゲーム終了条件を満たした場合は、アニメーションを中断して画面を表示
            if self.isGameOver {
                self.isAnimating = false
                self.matchedPositions = []
                self.removingPositions = []
                return
            }
        }

        // 0.5秒後に消去エフェクト開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            // ゲーム終了の場合は処理を中断
            if self.isGameOver {
                self.isAnimating = false
                return
            }

            self.removingPositions = matches
            self.matchedPositions = []

            // 0.3秒後にタイル消去
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }

                // ゲーム終了の場合は処理を中断
                if self.isGameOver {
                    self.isAnimating = false
                    return
                }

                self.removeMatches(matches)
                self.removingPositions = []

                // 落下アニメーション
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    guard let self = self, !self.isGameOver else { return }
                    self.applyGravity()

                    // 補充アニメーション
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                        guard let self = self, !self.isGameOver else { return }
                        self.refillBoard()

                        // 連鎖チェック
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                            guard let self = self, !self.isGameOver else { return }
                            self.checkForCascade()
                        }
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
            // 連鎖終了後に最終的なゲーム状態をチェック
            checkGameState()
        }
    }

    // マッチしたタイルを削除（nilに設定）
    private func removeMatches(_ matches: Set<Position>) {
        for match in matches {
            board[match.row][match.col] = nil
        }
    }

    // 重力適用（タイルを下に落とす）
    private func applyGravity() {
        // 各列ごとに処理
        for col in 0..<GameModel.gridSize {
            // 下から上に向かって、nilでないタイルを配列に集める
            var tiles = [TileType?]()
            for row in stride(from: GameModel.gridSize - 1, through: 0, by: -1) {
                if let tile = board[row][col] {
                    tiles.append(tile)
                }
            }

            // 列を下から埋めていく
            var writeRow = GameModel.gridSize - 1
            for tile in tiles {
                board[writeRow][col] = tile
                writeRow -= 1
            }

            // 残りのマスをnilで埋める
            while writeRow >= 0 {
                board[writeRow][col] = nil
                writeRow -= 1
            }
        }
    }

    // 盤面を補充（nilのマスに新しいタイルを追加）
    private func refillBoard() {
        for row in 0..<GameModel.gridSize {
            for col in 0..<GameModel.gridSize {
                if board[row][col] == nil {
                    board[row][col] = TileType.random()
                }
            }
        }
    }

    // ゲーム状態チェック
    private func checkGameState() {
        if score >= targetScore {
            isGameCleared = true
            isGameOver = true
        } else if movesLeft <= 0 {
            isGameOver = true
        }
    }

    // ゲームリセット
    func resetGame() {
        board = [[TileType?]]()
        for _ in 0..<GameModel.gridSize {
            var row = [TileType?]()
            for _ in 0..<GameModel.gridSize {
                row.append(TileType.random())
            }
            board.append(row)
        }
        removeInitialMatches()
        score = 0
        movesLeft = maxMoves
        isGameOver = false
        isGameCleared = false
        selectedPosition = nil
        matchedPositions = []
        removingPositions = []
        isAnimating = false
    }
}
