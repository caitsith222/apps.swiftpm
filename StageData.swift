import Foundation

// 障害物の配置情報
struct ObstaclePlacement {
    let row: Int
    let col: Int
    let obstacle: ObstacleType
}

// 盤面形状（穴の位置）
struct BoardShape {
    let holes: Set<Position>  // 穴の位置

    static let standard = BoardShape(holes: [])  // 通常の8x8

    // 四隅に穴
    static let cornerHoles = BoardShape(holes: [
        Position(row: 0, col: 0), Position(row: 0, col: 1),
        Position(row: 1, col: 0),
        Position(row: 0, col: 6), Position(row: 0, col: 7),
        Position(row: 1, col: 7),
        Position(row: 6, col: 0),
        Position(row: 7, col: 0), Position(row: 7, col: 1),
        Position(row: 6, col: 7),
        Position(row: 7, col: 6), Position(row: 7, col: 7)
    ])

    // 中央に穴
    static let centerHole = BoardShape(holes: [
        Position(row: 3, col: 3), Position(row: 3, col: 4),
        Position(row: 4, col: 3), Position(row: 4, col: 4)
    ])

    // クロス形状
    static let crossShape = BoardShape(holes: [
        Position(row: 0, col: 0), Position(row: 0, col: 1), Position(row: 0, col: 6), Position(row: 0, col: 7),
        Position(row: 1, col: 0), Position(row: 1, col: 1), Position(row: 1, col: 6), Position(row: 1, col: 7),
        Position(row: 6, col: 0), Position(row: 6, col: 1), Position(row: 6, col: 6), Position(row: 6, col: 7),
        Position(row: 7, col: 0), Position(row: 7, col: 1), Position(row: 7, col: 6), Position(row: 7, col: 7)
    ])
}

// ステージ設定
struct Stage {
    let number: Int
    let name: String
    let targetScore: Int
    let maxMoves: Int
    let isUnlocked: Bool
    let obstacles: [ObstaclePlacement]  // 初期障害物配置
    let boardShape: BoardShape  // 盤面形状

    static let stages: [Stage] = [
        // Stage 1: 初級 - 障害物なし
        Stage(
            number: 1,
            name: "初級",
            targetScore: 1000,
            maxMoves: 10,
            isUnlocked: true,
            obstacles: [],
            boardShape: .standard
        ),

        // Stage 2: 中級 - 凍結タイルを少し配置
        Stage(
            number: 2,
            name: "中級",
            targetScore: 2000,
            maxMoves: 8,
            isUnlocked: false,
            obstacles: [
                ObstaclePlacement(row: 2, col: 2, obstacle: .frozen),
                ObstaclePlacement(row: 2, col: 5, obstacle: .frozen),
                ObstaclePlacement(row: 5, col: 2, obstacle: .frozen),
                ObstaclePlacement(row: 5, col: 5, obstacle: .frozen)
            ],
            boardShape: .standard
        ),

        // Stage 3: 上級 - 壊せるブロックと四隅穴
        Stage(
            number: 3,
            name: "上級",
            targetScore: 3000,
            maxMoves: 7,
            isUnlocked: false,
            obstacles: [
                ObstaclePlacement(row: 3, col: 3, obstacle: .breakable(hp: 2)),
                ObstaclePlacement(row: 3, col: 4, obstacle: .breakable(hp: 2)),
                ObstaclePlacement(row: 4, col: 3, obstacle: .breakable(hp: 2)),
                ObstaclePlacement(row: 4, col: 4, obstacle: .breakable(hp: 2))
            ],
            boardShape: .cornerHoles
        ),

        // Stage 4: 超級 - 鎖タイルと中央穴
        Stage(
            number: 4,
            name: "超級",
            targetScore: 4000,
            maxMoves: 6,
            isUnlocked: false,
            obstacles: [
                ObstaclePlacement(row: 2, col: 1, obstacle: .chained),
                ObstaclePlacement(row: 2, col: 6, obstacle: .chained),
                ObstaclePlacement(row: 5, col: 1, obstacle: .chained),
                ObstaclePlacement(row: 5, col: 6, obstacle: .chained),
                ObstaclePlacement(row: 1, col: 3, obstacle: .breakable(hp: 3)),
                ObstaclePlacement(row: 1, col: 4, obstacle: .breakable(hp: 3)),
                ObstaclePlacement(row: 6, col: 3, obstacle: .breakable(hp: 3)),
                ObstaclePlacement(row: 6, col: 4, obstacle: .breakable(hp: 3))
            ],
            boardShape: .centerHole
        ),

        // Stage 5: 極級 - 全ての障害物 + クロス形状
        Stage(
            number: 5,
            name: "極級",
            targetScore: 5000,
            maxMoves: 5,
            isUnlocked: false,
            obstacles: [
                // 凍結タイル
                ObstaclePlacement(row: 2, col: 2, obstacle: .frozen),
                ObstaclePlacement(row: 2, col: 5, obstacle: .frozen),
                ObstaclePlacement(row: 5, col: 2, obstacle: .frozen),
                ObstaclePlacement(row: 5, col: 5, obstacle: .frozen),
                // 鎖タイル
                ObstaclePlacement(row: 3, col: 2, obstacle: .chained),
                ObstaclePlacement(row: 3, col: 5, obstacle: .chained),
                ObstaclePlacement(row: 4, col: 2, obstacle: .chained),
                ObstaclePlacement(row: 4, col: 5, obstacle: .chained),
                // 壊せるブロック
                ObstaclePlacement(row: 3, col: 3, obstacle: .breakable(hp: 3)),
                ObstaclePlacement(row: 3, col: 4, obstacle: .breakable(hp: 3)),
                ObstaclePlacement(row: 4, col: 3, obstacle: .breakable(hp: 3)),
                ObstaclePlacement(row: 4, col: 4, obstacle: .breakable(hp: 3))
            ],
            boardShape: .crossShape
        )
    ]
}

// ステージのアンロック状態を管理
class StageManager: ObservableObject {
    @Published var unlockedStages: Set<Int> = [1]  // 最初はステージ1のみアンロック

    // ステージをアンロック
    func unlockStage(_ stageNumber: Int) {
        unlockedStages.insert(stageNumber)
    }

    // ステージがアンロックされているかチェック
    func isStageUnlocked(_ stageNumber: Int) -> Bool {
        return unlockedStages.contains(stageNumber)
    }

    // すべてのステージ情報を取得（アンロック状態を反映）
    func getAvailableStages() -> [Stage] {
        return Stage.stages.map { stage in
            Stage(
                number: stage.number,
                name: stage.name,
                targetScore: stage.targetScore,
                maxMoves: stage.maxMoves,
                isUnlocked: isStageUnlocked(stage.number)
            )
        }
    }
}
