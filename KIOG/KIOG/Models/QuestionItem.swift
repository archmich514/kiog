import Foundation

struct QuestionItem: Identifiable, Hashable {
    // Identifiable用のユニークなID
    var id: String { stableId }

    let questionId: String?  // Firestoreの質問ID（AI生成の場合はnil）
    let text: String
    let isAI: Bool

    // 安定したID（questionIdがなければUUIDを生成）
    private let _stableId: String

    var stableId: String { _stableId }

    init(questionId: String?, text: String, isAI: Bool) {
        self.questionId = questionId
        self.text = text
        self.isAI = isAI
        self._stableId = questionId ?? UUID().uuidString
    }
}

extension QuestionItem {
    init(from dictionary: [String: Any]) {
        let questionId = dictionary["id"] as? String
        self.questionId = questionId
        self.text = dictionary["text"] as? String ?? ""
        self.isAI = dictionary["isAI"] as? Bool ?? false
        self._stableId = questionId ?? UUID().uuidString
    }
}
