import Foundation

struct AnswerItem: Identifiable, Hashable {
    let id: String
    let userName: String
    let questionText: String
    let answer: String
    let userId: String
    let timeSlot: String
    let date: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AnswerItem, rhs: AnswerItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension AnswerItem {
    init?(documentId: String, from dictionary: [String: Any]) {
        guard let userName = dictionary["userName"] as? String,
              let questionText = dictionary["questionText"] as? String,
              let answer = dictionary["answer"] as? String else {
            return nil
        }

        self.id = documentId
        self.userName = userName
        self.questionText = questionText
        self.answer = answer
        self.userId = dictionary["userId"] as? String ?? ""
        self.timeSlot = dictionary["timeSlot"] as? String ?? ""
        self.date = dictionary["date"] as? String ?? ""
    }
}

struct PredictionData: Hashable {
    let predictorId: String
    let predictorName: String
    let prediction: String
}
