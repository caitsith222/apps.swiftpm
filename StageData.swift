import Foundation

// ステージ設定
struct Stage {
    let number: Int
    let name: String
    let targetScore: Int
    let maxMoves: Int
    let isUnlocked: Bool

    static let stages: [Stage] = [
        Stage(number: 1, name: "初級", targetScore: 1000, maxMoves: 10, isUnlocked: true),
        Stage(number: 2, name: "中級", targetScore: 2000, maxMoves: 8, isUnlocked: false),
        Stage(number: 3, name: "上級", targetScore: 3000, maxMoves: 7, isUnlocked: false),
        Stage(number: 4, name: "超級", targetScore: 4000, maxMoves: 6, isUnlocked: false),
        Stage(number: 5, name: "極級", targetScore: 5000, maxMoves: 5, isUnlocked: false)
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
