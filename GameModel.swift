import Foundation
import SwiftUI

// 特殊タイルの種類
enum SpecialType {
    case none           // 通常タイル
    case horizontalLine // 横ライン爆弾（4個横消し）
    case verticalLine   // 縦ライン爆弾（4個縦消し）
    case bomb           // 爆弾（3×3消去、L字/T字）
    case rainbow        // レインボー（5個直線消し）
}

// タイル（通常色 + 特殊タイプ）
struct Tile: Equatable {
    let type: TileType
    let special: SpecialType

    init(type: TileType, special: SpecialType = .none) {
        self.type = type
        self.special = special
    }

    static func random() -> Tile {
        Tile(type: TileType.random(), special: .none)
    }
}

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

    @Published var board: [[Tile?]]
    @Published var score: Int = 0
    @Published var movesLeft: Int = 0
    @Published var isGameOver: Bool = false
    @Published var isGameCleared: Bool = false
    @Published var selectedPosition: Position?
    @Published var isAnimating: Bool = false
    @Published var matchedPositions: Set<Position> = []  // マッチしたタイルの位置
    @Published var removingPositions: Set<Position> = []  // 消去中のタイルの位置
    @Published var chainCount: Int = 0  // 連鎖カウント
    @Published var showChainPopup: Bool = false  // 連鎖ポップアップ表示

    var currentStage: Stage?
    var targetScore: Int = 3000
    var maxMoves: Int = 5
    private var currentChainMultiplier: Double = 1.0

    init(stage: Stage? = nil) {
        // ステージ設定を適用
        if let stage = stage {
            self.currentStage = stage
            self.targetScore = stage.targetScore
            self.maxMoves = stage.maxMoves
        }

        // 初期盤面をランダムに生成（3つ揃いがない状態）
        board = [[Tile?]]()
        for _ in 0..<GameModel.gridSize {
            var row = [Tile?]()
            for _ in 0..<GameModel.gridSize {
                row.append(Tile.random())
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

                while checkCol < GameModel.gridSize,
                      let tile = board[row][checkCol],
                      tile.type == currentTile.type {
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

                while checkRow < GameModel.gridSize,
                      let tile = board[checkRow][col],
                      tile.type == currentTile.type {
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

    // 特殊パターンを検出（4個消し、5個消し、L/T字）
    private func findSpecialPatterns(_ matches: Set<Position>) -> [Position: SpecialType] {
        var specialTiles = [Position: SpecialType]()

        // 5個直線マッチ → レインボー
        for pos in matches {
            // 横方向チェック
            var horizontalCount = 0
            for col in 0..<GameModel.gridSize {
                if matches.contains(Position(row: pos.row, col: col)) {
                    horizontalCount += 1
                }
            }
            if horizontalCount >= 5 {
                specialTiles[pos] = .rainbow
                continue
            }

            // 縦方向チェック
            var verticalCount = 0
            for row in 0..<GameModel.gridSize {
                if matches.contains(Position(row: row, col: pos.col)) {
                    verticalCount += 1
                }
            }
            if verticalCount >= 5 {
                specialTiles[pos] = .rainbow
                continue
            }
        }

        // L字/T字 → 爆弾
        for pos in matches {
            if isLOrTShape(pos, in: matches) {
                specialTiles[pos] = .bomb
            }
        }

        // 4個マッチ → ライン爆弾（レインボーと爆弾でない場合のみ）
        for pos in matches {
            if specialTiles[pos] != nil { continue }

            // 横4個チェック
            var horizontalCount = 0
            var minCol = pos.col
            var maxCol = pos.col
            for col in 0..<GameModel.gridSize {
                let checkPos = Position(row: pos.row, col: col)
                if matches.contains(checkPos),
                   let tile = board[checkPos.row][checkPos.col],
                   let currentTile = board[pos.row][pos.col],
                   tile.type == currentTile.type {
                    horizontalCount += 1
                    minCol = min(minCol, col)
                    maxCol = max(maxCol, col)
                }
            }
            if horizontalCount >= 4 && (maxCol - minCol + 1) == horizontalCount {
                specialTiles[pos] = .horizontalLine
                continue
            }

            // 縦4個チェック
            var verticalCount = 0
            var minRow = pos.row
            var maxRow = pos.row
            for row in 0..<GameModel.gridSize {
                let checkPos = Position(row: row, col: pos.col)
                if matches.contains(checkPos),
                   let tile = board[checkPos.row][checkPos.col],
                   let currentTile = board[pos.row][pos.col],
                   tile.type == currentTile.type {
                    verticalCount += 1
                    minRow = min(minRow, row)
                    maxRow = max(maxRow, row)
                }
            }
            if verticalCount >= 4 && (maxRow - minRow + 1) == verticalCount {
                specialTiles[pos] = .verticalLine
            }
        }

        return specialTiles
    }

    // L字またはT字パターンかチェック
    private func isLOrTShape(_ pos: Position, in matches: Set<Position>) -> Bool {
        guard let tile = board[pos.row][pos.col] else { return false }

        // 中心点から上下左右のマッチをカウント
        var up = 0, down = 0, left = 0, right = 0

        // 上方向
        var checkRow = pos.row - 1
        while checkRow >= 0,
              matches.contains(Position(row: checkRow, col: pos.col)),
              let checkTile = board[checkRow][pos.col],
              checkTile.type == tile.type {
            up += 1
            checkRow -= 1
        }

        // 下方向
        checkRow = pos.row + 1
        while checkRow < GameModel.gridSize,
              matches.contains(Position(row: checkRow, col: pos.col)),
              let checkTile = board[checkRow][pos.col],
              checkTile.type == tile.type {
            down += 1
            checkRow += 1
        }

        // 左方向
        var checkCol = pos.col - 1
        while checkCol >= 0,
              matches.contains(Position(row: pos.row, col: checkCol)),
              let checkTile = board[pos.row][checkCol],
              checkTile.type == tile.type {
            left += 1
            checkCol -= 1
        }

        // 右方向
        checkCol = pos.col + 1
        while checkCol < GameModel.gridSize,
              matches.contains(Position(row: pos.row, col: checkCol)),
              let checkTile = board[pos.row][checkCol],
              checkTile.type == tile.type {
            right += 1
            checkCol += 1
        }

        let vertical = up + down + 1
        let horizontal = left + right + 1

        // T字: 縦3+横3以上、または縦と横が両方3以上
        // L字: 縦3+横3で交差
        return (vertical >= 3 && horizontal >= 3)
    }

    // 特殊タイルの効果を発動
    private func activateSpecialTile(at position: Position) -> Set<Position> {
        guard let tile = board[position.row][position.col] else { return [] }

        var affectedPositions = Set<Position>()

        switch tile.special {
        case .none:
            break

        case .horizontalLine:
            // 横一列を消す
            for col in 0..<GameModel.gridSize {
                if board[position.row][col] != nil {
                    affectedPositions.insert(Position(row: position.row, col: col))
                }
            }

        case .verticalLine:
            // 縦一列を消す
            for row in 0..<GameModel.gridSize {
                if board[row][position.col] != nil {
                    affectedPositions.insert(Position(row: row, col: position.col))
                }
            }

        case .bomb:
            // 周囲3×3を消す
            for dr in -1...1 {
                for dc in -1...1 {
                    let row = position.row + dr
                    let col = position.col + dc
                    if row >= 0 && row < GameModel.gridSize &&
                       col >= 0 && col < GameModel.gridSize &&
                       board[row][col] != nil {
                        affectedPositions.insert(Position(row: row, col: col))
                    }
                }
            }

        case .rainbow:
            // 同じ色のタイルを全て消す（レインボー自身は除く）
            for row in 0..<GameModel.gridSize {
                for col in 0..<GameModel.gridSize {
                    let pos = Position(row: row, col: col)
                    if pos != position,
                       let checkTile = board[row][col],
                       checkTile.type == tile.type {
                        affectedPositions.insert(pos)
                    }
                }
            }
            // レインボー自身も消す
            affectedPositions.insert(position)
        }

        return affectedPositions
    }

    // タイルを交換
    func swapTiles(from: Position, to: Position) {
        guard !isAnimating else { return }
        guard isAdjacentPosition(from, to) else { return }

        // 両方のタイルが存在することを確認
        guard let fromTile = board[from.row][from.col],
              let toTile = board[to.row][to.col] else {
            selectedPosition = nil
            return
        }

        isAnimating = true

        // レインボータイルとの交換かチェック
        let isRainbowSwap = (fromTile.special == .rainbow || toTile.special == .rainbow)

        // スワップアニメーション用に少し待つ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            // 交換実行
            let temp = self.board[from.row][from.col]
            self.board[from.row][from.col] = self.board[to.row][to.col]
            self.board[to.row][to.col] = temp

            // レインボータイルとの交換の場合、特殊処理
            if isRainbowSwap {
                var affectedPositions = Set<Position>()

                if fromTile.special == .rainbow {
                    // レインボーを移動先の色と同じ色のタイルを消す
                    for row in 0..<GameModel.gridSize {
                        for col in 0..<GameModel.gridSize {
                            if let tile = self.board[row][col],
                               tile.type == toTile.type {
                                affectedPositions.insert(Position(row: row, col: col))
                            }
                        }
                    }
                    affectedPositions.insert(from)
                } else {
                    // toがレインボー
                    for row in 0..<GameModel.gridSize {
                        for col in 0..<GameModel.gridSize {
                            if let tile = self.board[row][col],
                               tile.type == fromTile.type {
                                affectedPositions.insert(Position(row: row, col: col))
                            }
                        }
                    }
                    affectedPositions.insert(to)
                }

                DispatchQueue.main.async {
                    self.movesLeft -= 1
                    self.chainCount = 0
                    self.currentChainMultiplier = 1.0
                }
                self.processMatches(affectedPositions)
                self.selectedPosition = nil
                return
            }

            // 通常のマッチチェック
            var matches = self.findAllMatches()

            // 特殊タイルがマッチに含まれている場合、その効果を追加
            var specialActivated = false
            let matchesCopy = matches
            for pos in matchesCopy {
                if let tile = self.board[pos.row][pos.col],
                   tile.special != .none {
                    let specialMatches = self.activateSpecialTile(at: pos)
                    matches.formUnion(specialMatches)
                    specialActivated = true
                }
            }

            if matches.isEmpty && !specialActivated {
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
                    // プレイヤーの操作なので連鎖カウンターをリセット
                    self.chainCount = 0
                    self.currentChainMultiplier = 1.0
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
        // 連鎖カウンターを増加
        chainCount += 1

        // 連鎖倍率を計算
        currentChainMultiplier = calculateChainMultiplier(chain: chainCount)

        // 特殊パターンを検出
        let specialPatterns = findSpecialPatterns(matches)

        // マッチしたタイルをハイライト表示
        DispatchQueue.main.async {
            self.matchedPositions = matches

            // 連鎖ポップアップ表示（2連鎖以上）
            if self.chainCount >= 2 {
                self.showChainPopup = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.showChainPopup = false
                }
            }
        }

        // スコア加算：消去数 × 基本点 × 連鎖倍率
        let matchCount = matches.count
        DispatchQueue.main.async {
            let basePoints = matchCount * GameModel.baseScore
            let finalPoints = Int(Double(basePoints) * self.currentChainMultiplier)
            self.score += finalPoints

            // スコア更新直後にゲーム状態をチェック
            self.checkGameState()

            // ゲーム終了条件を満たした場合は、アニメーションを中断して画面を表示
            if self.isGameOver {
                self.isAnimating = false
                self.matchedPositions = []
                self.removingPositions = []
                self.chainCount = 0
                self.showChainPopup = false
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

            // 0.3秒後にタイル消去と特殊タイル生成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }

                // ゲーム終了の場合は処理を中断
                if self.isGameOver {
                    self.isAnimating = false
                    return
                }

                // 特殊タイルを生成（マッチを消す前に）
                self.createSpecialTiles(specialPatterns)

                // マッチしたタイルを消去
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

    // 特殊タイルを生成
    private func createSpecialTiles(_ specialPatterns: [Position: SpecialType]) {
        // 特殊パターンがある位置に特殊タイルを配置
        // 優先順位: レインボー > 爆弾 > ライン爆弾
        var createdPositions = Set<Position>()

        // レインボーを最優先で生成
        for (pos, specialType) in specialPatterns where specialType == .rainbow {
            if let tile = board[pos.row][pos.col] {
                board[pos.row][pos.col] = Tile(type: tile.type, special: .rainbow)
                createdPositions.insert(pos)
                break // レインボーは1個だけ生成
            }
        }

        // 爆弾を生成（レインボーがない場所）
        if createdPositions.isEmpty {
            for (pos, specialType) in specialPatterns where specialType == .bomb {
                if !createdPositions.contains(pos),
                   let tile = board[pos.row][pos.col] {
                    board[pos.row][pos.col] = Tile(type: tile.type, special: .bomb)
                    createdPositions.insert(pos)
                    break // 爆弾は1個だけ生成
                }
            }
        }

        // ライン爆弾を生成（レインボーと爆弾がない場所）
        if createdPositions.isEmpty {
            for (pos, specialType) in specialPatterns where specialType == .horizontalLine || specialType == .verticalLine {
                if !createdPositions.contains(pos),
                   let tile = board[pos.row][pos.col] {
                    board[pos.row][pos.col] = Tile(type: tile.type, special: specialType)
                    createdPositions.insert(pos)
                    break // ライン爆弾は1個だけ生成
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
            // 連鎖終了
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.chainCount = 0
                self?.currentChainMultiplier = 1.0
            }
        }
    }

    // 連鎖倍率を計算
    private func calculateChainMultiplier(chain: Int) -> Double {
        switch chain {
        case 1: return 1.0   // 初回
        case 2: return 1.2   // 2連鎖：1.2倍
        case 3: return 1.5   // 3連鎖：1.5倍
        case 4: return 2.0   // 4連鎖：2.0倍
        case 5: return 2.5   // 5連鎖：2.5倍
        default: return 3.0  // 6連鎖以上：3.0倍
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
            var tiles = [Tile?]()
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
                    board[row][col] = Tile.random()
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
        board = [[Tile?]]()
        for _ in 0..<GameModel.gridSize {
            var row = [Tile?]()
            for _ in 0..<GameModel.gridSize {
                row.append(Tile.random())
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
        chainCount = 0
        showChainPopup = false
        currentChainMultiplier = 1.0
    }
}
