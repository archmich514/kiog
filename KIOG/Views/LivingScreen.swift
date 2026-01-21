import SwiftUI

struct LivingScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var showAnswerInput = false
    @State private var selectedQuestion: Question?
    @State private var answerText = ""

    private let sampleReports = [
        Report(month: 1, day: 15, content: "今日は二人でカフェに行った。新しいメニューを試してみて、とても美味しかった。"),
        Report(month: 1, day: 14, content: "映画を観に行った。久しぶりのデートで楽しかった。"),
        Report(month: 1, day: 13, content: "一緒に料理を作った。ハンバーグを作って大成功!")
    ]

    private let sampleQuestions = [
        Question(text: "今日の晩ごはんは何がいい?"),
        Question(text: "週末どこに行きたい?"),
        Question(text: "最近ハマっていることは?")
    ]

    private let sampleAnswer = Answer(
        name: "太郎",
        question: "今日の晩ごはんは何がいい?",
        answerText: "カレーが食べたいな"
    )

    private var hasKiog: Bool {
        !sampleReports.isEmpty
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        headerSection

                        if hasKiog {
                            kiogSection
                            queSection
                            answerSection
                        } else {
                            emptyKiogSection
                        }
                    }
                }

                footerSection
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("回答を入力", isPresented: $showAnswerInput) {
            TextField("回答を入力してください", text: $answerText)
            Button("送信") {
                answerText = ""
            }
            Button("キャンセル", role: .cancel) {
                answerText = ""
            }
        } message: {
            if let question = selectedQuestion {
                Text(question.text)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LIVING")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.black)
                .tracking(1.8)

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

                Button(action: {
                    navigationManager.navigateTo(.kiogList)
                }) {
                    Text("ALL →")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                        .tracking(1.8)
                }
            }

            VStack(spacing: 16) {
                ForEach(sampleReports.prefix(3)) { report in
                    ReportCard(dateText: report.dateText) {
                        navigationManager.navigateTo(.reportDetail(report: report))
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var emptyKiogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("KIOG")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .tracking(1.8)

            Text("KIOGはありません")
                .font(.system(size: 16))
                .foregroundColor(AppColors.grayText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var queSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Que")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .tracking(1.8)

            VStack(spacing: 16) {
                ForEach(sampleQuestions) { question in
                    QuestionCard(questionText: question.text) {
                        selectedQuestion = question
                        showAnswerInput = true
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Answer")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .tracking(1.8)

            AnswerCard(
                name: sampleAnswer.name,
                question: sampleAnswer.question,
                answer: sampleAnswer.answerText
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var footerSection: some View {
        VStack {
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
        }
        .padding(.vertical, 32)
        .background(AppColors.background)
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
