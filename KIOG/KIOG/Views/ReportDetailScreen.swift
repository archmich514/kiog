import SwiftUI

struct ReportDetailScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    let report: Report

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                headerSection

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 質問回答セクション（あれば表示）
                        if !report.questionAnswers.isEmpty {
                            questionAnswersSection
                        }

                        // レポート本文セクション
                        reportContentSection
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var headerSection: some View {
        HStack(spacing: 0) {
            BackButton {
                navigationManager.goBack()
            }

            Text(report.dateText)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.black)
                .tracking(1.8)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private var questionAnswersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今日の質問への回答")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            ForEach(Array(report.questionAnswers.enumerated()), id: \.offset) { _, qa in
                VStack(alignment: .leading, spacing: 12) {
                    // 質問
                    Text("【質問】\(qa.questionText)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    // 各回答
                    ForEach(Array(qa.answers.enumerated()), id: \.offset) { _, answerData in
                        VStack(alignment: .leading, spacing: 8) {
                            // 予想がある場合は表示
                            ForEach(Array(answerData.predictions.enumerated()), id: \.offset) { _, prediction in
                                HStack(alignment: .top, spacing: 4) {
                                    Text("\(prediction.predictorName)さんの予想:")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.grayText)
                                    Text(prediction.prediction)
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
                                }
                            }

                            // 実際の回答
                            HStack(alignment: .top, spacing: 4) {
                                Text("\(answerData.userName)さんの回答:")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.salmon)
                                Text(answerData.answer)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.leading, 8)
                    }

                    Divider()
                        .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private var reportContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今日の会話")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            Text(report.content)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        ReportDetailScreen(
            report: Report(
                month: 1,
                day: 15,
                content: "今日は二人でカフェに行った。新しいメニューを試してみて、とても美味しかった。帰りに公園を散歩して、とても楽しい一日だった。",
                questionAnswers: [
                    QuestionAnswerData(
                        questionText: "好きなお菓子は？",
                        answers: [
                            AnswerData(
                                userName: "太郎",
                                answer: "チョコ",
                                predictions: [
                                    PredictionItem(predictorName: "花子", prediction: "ポテチ")
                                ]
                            ),
                            AnswerData(
                                userName: "花子",
                                answer: "グミ",
                                predictions: [
                                    PredictionItem(predictorName: "太郎", prediction: "チョコレート")
                                ]
                            )
                        ]
                    )
                ]
            )
        )
        .environmentObject(NavigationManager())
    }
}
