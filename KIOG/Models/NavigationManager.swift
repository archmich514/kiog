import SwiftUI

enum AppRoute: Hashable {
    case registration
    case unitSelect(gender: Gender)
    case living
    case kiogList
    case reportDetail(report: Report)
    case recording
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

    var dateText: String {
        "\(month)/\(day)"
    }
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
