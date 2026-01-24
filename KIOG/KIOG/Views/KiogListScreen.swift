import SwiftUI
import FirebaseFirestore

struct KiogListScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var reports: [Report] = []
    @State private var isLoading = true

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if reports.isEmpty {
                    Spacer()
                    Text("KIOGはありません")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.grayText)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(reports) { report in
                                ReportCard(dateText: report.dateText) {
                                    navigationManager.navigateTo(.reportDetail(report: report))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await fetchReports()
        }
    }

    private var headerSection: some View {
        HStack(spacing: 0) {
            BackButton {
                navigationManager.goBack()
            }

            Text("KIOG")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.black)
                .tracking(1.8)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private func fetchReports() async {
        do {
            let snapshot = try await db.collection("reports")
                .whereField("unitId", isEqualTo: navigationManager.unitId)
                .order(by: "createdAt", descending: true)
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
        KiogListScreen()
            .environmentObject({
                let manager = NavigationManager()
                manager.unitId = "ABC12345"
                return manager
            }())
    }
}
