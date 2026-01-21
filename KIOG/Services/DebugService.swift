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
}
