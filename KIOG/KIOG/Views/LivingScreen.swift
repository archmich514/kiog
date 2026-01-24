import SwiftUI
import FirebaseFirestore

struct LivingScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var reports: [Report] = []
    @State private var isLoading = true

    // QUE/ANS関連
    @State private var currentQuestions: [QuestionItem] = []
    @State private var answeredQuestions: Set<String> = []
    @State private var pendingAnswers: [AnswerItem] = []
    @State private var selectedQuestion: QuestionItem?

    // Debug用
    #if DEBUG
    @State private var isDebugLoading = false
    @State private var showDebugAlert = false
    @State private var showDebugError = false
    @State private var debugErrorMessage = ""
    #endif

    private let db = Firestore.firestore()

    var unansweredQuestions: [QuestionItem] {
        currentQuestions.filter { !answeredQuestions.contains($0.text) }
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        headerSection
                        kiogSection

                        // QUEセクション（未回答の質問がある場合）
                        if !unansweredQuestions.isEmpty {
                            queSection
                        }

                        // ANSセクション（予想待ちの回答がある場合）
                        if !pendingAnswers.isEmpty {
                            ansSection
                        }
                    }
                }

                footerSection
            }

            #if DEBUG
            if isDebugLoading {
                debugLoadingOverlay
            }
            #endif
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await fetchReports()
            await fetchQuestionsAndAnswers()
        }
        .onAppear {
            // PredictionScreenから戻ってきた時にデータを更新
            Task {
                await fetchQuestionsAndAnswers()
            }
        }
        .sheet(item: $selectedQuestion) { question in
            AnswerInputView(
                question: question,
                unitId: navigationManager.unitId,
                userId: AuthService.shared.userId ?? "",
                userName: navigationManager.userName,
                onComplete: {
                    Task { await fetchQuestionsAndAnswers() }
                }
            )
        }
        #if DEBUG
        .alert("デバッグ実行", isPresented: $showDebugAlert) {
            Button("実行") {
                Task { await triggerDebugReport() }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("レポートを即時生成しますか？\n（録音データが必要です）")
        }
        .alert("エラー", isPresented: $showDebugError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(debugErrorMessage)
        }
        #endif
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("LIVING")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.black)
                    .tracking(1.8)

                Spacer()
            }

            Text("#\(navigationManager.unitId)")
                .font(.system(size: 24))
                .foregroundColor(.black)
                .tracking(1.8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private var kiogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("KIOG")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .tracking(1.8)

                Spacer()

                if !reports.isEmpty {
                    Button(action: {
                        navigationManager.navigateTo(.kiogList)
                    }) {
                        Text("ALL →")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                            .tracking(1.8)
                    }
                }
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else if reports.isEmpty {
                Text("KIOGはありません")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.grayText)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 16) {
                    ForEach(reports.prefix(3)) { report in
                        ReportCard(dateText: report.dateText) {
                            navigationManager.navigateTo(.reportDetail(report: report))
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var queSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("QUE")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .tracking(1.8)

            VStack(spacing: 12) {
                ForEach(unansweredQuestions, id: \.stableId) { question in
                    QuestionCard(questionText: question.text) {
                        selectedQuestion = question
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var ansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ANS")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .tracking(1.8)

            VStack(spacing: 12) {
                ForEach(pendingAnswers) { answer in
                    AnswerCard(
                        name: answer.userName,
                        question: answer.questionText,
                        action: {
                            navigationManager.navigateTo(.prediction(answer: answer))
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var footerSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                navigationManager.navigateTo(.recording)
            }) {
                Text("RECをはじめる")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.black)
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)

            #if DEBUG
            debugButtonsSection
            #endif
        }
        .padding(.bottom, 16)
        .background(AppColors.background)
    }

    #if DEBUG
    private var debugButtonsSection: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.top, 16)

            Text("DEBUG MODE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)

            HStack(spacing: 8) {
                // ダミーデータ投入
                Button(action: insertDummyData) {
                    VStack(spacing: 2) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("QUE/ANS")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.blue)
                    .frame(width: 60, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }

                // リセット＆再投入
                Button(action: resetAndInsertDummyData) {
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 16))
                        Text("リセット")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.orange)
                    .frame(width: 60, height: 44)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // クリア
                Button(action: clearAllDummyData) {
                    VStack(spacing: 2) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 16))
                        Text("クリア")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.red)
                    .frame(width: 60, height: 44)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                // レポート即時生成
                Button(action: { showDebugAlert = true }) {
                    VStack(spacing: 2) {
                        Image(systemName: "doc.badge.gearshape.fill")
                            .font(.system(size: 16))
                        Text("レポート")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.purple)
                    .frame(width: 60, height: 44)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
    #endif

    #if DEBUG
    private var debugLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("レポート生成中...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(40)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
        }
    }
    #endif

    private func fetchReports() async {
        do {
            let snapshot = try await db.collection("reports")
                .whereField("unitId", isEqualTo: navigationManager.unitId)
                .order(by: "createdAt", descending: true)
                .limit(to: 10)
                .getDocuments()

            let fetchedReports = snapshot.documents.compactMap { doc -> Report? in
                let data = doc.data()
                guard let date = data["date"] as? String,
                      let content = data["content"] as? String else { return nil }

                let components = date.split(separator: "-")
                guard components.count == 3,
                      let month = Int(components[1]),
                      let day = Int(components[2]) else { return nil }

                // 質問回答データをパース
                let questionAnswers = parseQuestionAnswers(data["questionAnswers"])

                return Report(month: month, day: day, content: content, questionAnswers: questionAnswers)
            }

            await MainActor.run {
                self.reports = fetchedReports
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch reports: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    private func fetchQuestionsAndAnswers() async {
        guard let userId = AuthService.shared.userId else { return }
        let unitId = navigationManager.unitId

        do {
            // 現在の質問を取得
            let questions = try await AnswerService.shared.fetchCurrentQuestions(unitId: unitId)

            // 自分の回答済み質問を取得
            let answered = try await AnswerService.shared.fetchMyAnsweredQuestions(unitId: unitId, userId: userId)

            // 予想待ちの回答を取得
            let pending = try await AnswerService.shared.fetchPendingAnswers(unitId: unitId, userId: userId)

            await MainActor.run {
                self.currentQuestions = questions
                self.answeredQuestions = answered
                self.pendingAnswers = pending
            }
        } catch {
            print("Failed to fetch questions and answers: \(error)")
        }
    }

    #if DEBUG
    private func triggerDebugReport() async {
        await MainActor.run {
            isDebugLoading = true
        }

        do {
            try await DebugService.shared.triggerReportGeneration(unitId: navigationManager.unitId)
            await fetchReports()
        } catch {
            print("Debug report generation failed: \(error)")
            await MainActor.run {
                debugErrorMessage = "レポート生成に失敗しました。\n録音データがあるか確認してください。"
                showDebugError = true
            }
        }

        await MainActor.run {
            isDebugLoading = false
        }
    }

    private func insertDummyData() {
        // ダミーの質問（QUE）
        currentQuestions = [
            QuestionItem(questionId: "debug001", text: "今日の晩ごはんは何がいい？", isAI: false),
            QuestionItem(questionId: "debug002", text: "今一番したいことは？", isAI: false),
            QuestionItem(questionId: nil, text: "昨日カレー食べたいって言ってたけど、今日は何食べたい？", isAI: true)
        ]
        answeredQuestions = []

        // ダミーの回答（ANS）- 予想待ち
        pendingAnswers = [
            AnswerItem(
                documentId: "dummy_answer_001",
                from: [
                    "userName": "テスト太郎",
                    "questionText": "好きなお菓子は？",
                    "answer": "チョコレート",
                    "userId": "dummy_user_001",
                    "timeSlot": "morning",
                    "date": "2026-01-24"
                ]
            )!,
            AnswerItem(
                documentId: "dummy_answer_002",
                from: [
                    "userName": "テスト太郎",
                    "questionText": "子供の頃好きだった遊びは？",
                    "answer": "かくれんぼ",
                    "userId": "dummy_user_001",
                    "timeSlot": "evening",
                    "date": "2026-01-24"
                ]
            )!
        ]
    }

    private func resetAndInsertDummyData() {
        // 回答済みをクリア
        answeredQuestions = []
        // ダミーデータを再投入
        insertDummyData()
    }

    private func clearAllDummyData() {
        currentQuestions = []
        answeredQuestions = []
        pendingAnswers = []
    }
    #endif

    private func parseQuestionAnswers(_ data: Any?) -> [QuestionAnswerData] {
        guard let qaArray = data as? [[String: Any]] else { return [] }

        return qaArray.compactMap { qaDict -> QuestionAnswerData? in
            guard let questionText = qaDict["questionText"] as? String,
                  let answersArray = qaDict["answers"] as? [[String: Any]] else { return nil }

            let answers = answersArray.compactMap { ansDict -> AnswerData? in
                guard let userName = ansDict["userName"] as? String,
                      let answer = ansDict["answer"] as? String else { return nil }

                let predictionsArray = ansDict["predictions"] as? [[String: Any]] ?? []
                let predictions = predictionsArray.compactMap { predDict -> PredictionItem? in
                    guard let predictorName = predDict["predictorName"] as? String,
                          let prediction = predDict["prediction"] as? String else { return nil }
                    return PredictionItem(predictorName: predictorName, prediction: prediction)
                }

                return AnswerData(userName: userName, answer: answer, predictions: predictions)
            }

            return QuestionAnswerData(questionText: questionText, answers: answers)
        }
    }
}


#Preview {
    NavigationStack {
        LivingScreen()
            .environmentObject({
                let manager = NavigationManager()
                manager.unitId = "ABC12345"
                return manager
            }())
    }
}
