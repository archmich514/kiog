import FirebaseFunctions

class DebugService {
    static let shared = DebugService()

    private lazy var functions = Functions.functions()

    private init() {}

    /// デバッグ用：レポート生成を即時実行
    func triggerReportGeneration(unitId: String) async throws {
        let callable = functions.httpsCallable("debugGenerateReport")
        _ = try await callable.call(["unitId": unitId])
    }

    /// デバッグ用：質問生成を即時実行
    func triggerQuestionGeneration(timeSlot: String) async throws {
        let callable = functions.httpsCallable("debugGenerateQuestions")
        _ = try await callable.call(["timeSlot": timeSlot])
    }

    /// デバッグ用：質問マスターデータをシード
    func seedQuestions() async throws {
        let callable = functions.httpsCallable("debugSeedQuestions")
        _ = try await callable.call()
    }
}
