import SwiftUI

enum AppRoute: Hashable {
    case registration
    case unitSelect(gender: Gender)
    case living
    case kiogList
    case reportDetail(report: Report)
    case recording
    case prediction(answer: AnswerItem)
}

enum Gender: String, Hashable, CaseIterable {
    case male = "男性"
    case female = "女性"
}

struct Report: Hashable, Identifiable {
    let id = UUID()
    let month: Int
    let day: Int
    let content: String
    let questionAnswers: [QuestionAnswerData]

    init(month: Int, day: Int, content: String, questionAnswers: [QuestionAnswerData] = []) {
        self.month = month
        self.day = day
        self.content = content
        self.questionAnswers = questionAnswers
    }

    var dateText: String {
        "\(month)/\(day)"
    }
}

struct QuestionAnswerData: Hashable {
    let questionText: String
    let answers: [AnswerData]
}

struct AnswerData: Hashable {
    let userName: String
    let answer: String
    let predictions: [PredictionItem]
}

struct PredictionItem: Hashable {
    let predictorName: String
    let prediction: String
}

struct Question: Identifiable {
    let id = UUID()
    let text: String
}

struct Answer: Identifiable {
    let id = UUID()
    let name: String
    let question: String
    let answerText: String
}

class NavigationManager: ObservableObject {
    @Published var path = NavigationPath()
    @Published var userName: String = ""
    @Published var userGender: Gender?
    @Published var unitId: String = ""

    // ダミーデータ用（DEBUGビルドのみ）
    #if DEBUG
    @Published var isUsingDummyData: Bool = false
    @Published var shouldClearAllQuestions: Bool = false
    @Published var pendingAnswerIdToRemove: String? = nil
    #endif

    func navigateTo(_ route: AppRoute) {
        path.append(route)
    }

    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func goToRoot() {
        path = NavigationPath()
    }

    func goToLiving() {
        path = NavigationPath()
        path.append(AppRoute.living)
    }
}
