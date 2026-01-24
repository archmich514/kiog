import Foundation
import FirebaseFirestore

class AnswerService: ObservableObject {
    static let shared = AnswerService()
    private let db = Firestore.firestore()

    private init() {}

    // 回答を送信
    func submitAnswer(
        question: QuestionItem,
        answer: String,
        unitId: String,
        userId: String,
        userName: String
    ) async throws {
        let answerData: [String: Any] = [
            "unitId": unitId,
            "date": getToday(),
            "timeSlot": getCurrentTimeSlot(),
            "questionId": question.questionId as Any,
            "questionText": question.text,
            "userId": userId,
            "userName": userName,
            "answer": answer,
            "isAIQuestion": question.isAI,
            "createdAt": FieldValue.serverTimestamp(),
            "predictions": [],
            "viewedBy": []
        ]

        try await db.collection("answers").addDocument(data: answerData)
    }

    // 予想を送信
    func submitPrediction(
        answerId: String,
        prediction: String,
        userId: String,
        userName: String
    ) async throws {
        let predictionData: [String: Any] = [
            "predictorId": userId,
            "predictorName": userName,
            "prediction": prediction,
            "predictedAt": Timestamp(date: Date())
        ]

        let answerRef = db.collection("answers").document(answerId)
        try await answerRef.updateData([
            "predictions": FieldValue.arrayUnion([predictionData]),
            "viewedBy": FieldValue.arrayUnion([userId])
        ])
    }

    // 現在の質問を取得
    func fetchCurrentQuestions(unitId: String) async throws -> [QuestionItem] {
        let doc = try await db.collection("currentQuestions").document(unitId).getDocument()

        guard let data = doc.data(),
              let questions = data["questions"] as? [[String: Any]] else {
            return []
        }

        return questions.map { QuestionItem(from: $0) }
    }

    // 今日の自分の回答済み質問を取得
    func fetchMyAnsweredQuestions(unitId: String, userId: String) async throws -> Set<String> {
        let today = getToday()

        let snapshot = try await db.collection("answers")
            .whereField("unitId", isEqualTo: unitId)
            .whereField("date", isEqualTo: today)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        return Set(snapshot.documents.compactMap { doc -> String? in
            doc.data()["questionText"] as? String
        })
    }

    // 予想待ちの回答を取得（パートナーの回答で、まだ予想していないもの）
    func fetchPendingAnswers(unitId: String, userId: String) async throws -> [AnswerItem] {
        let today = getToday()

        let snapshot = try await db.collection("answers")
            .whereField("unitId", isEqualTo: unitId)
            .whereField("date", isEqualTo: today)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> AnswerItem? in
            let data = doc.data()
            let answererUserId = data["userId"] as? String ?? ""
            let viewedBy = data["viewedBy"] as? [String] ?? []

            // 自分の回答は除外、既に予想済みも除外
            if answererUserId == userId || viewedBy.contains(userId) {
                return nil
            }

            return AnswerItem(documentId: doc.documentID, from: data)
        }
    }

    // 今日の日付を取得（YYYY-MM-DD形式）
    private func getToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: Date())
    }

    // 現在の時間帯を取得
    private func getCurrentTimeSlot() -> String {
        let calendar = Calendar(identifier: .gregorian)
        var calendarWithTimeZone = calendar
        calendarWithTimeZone.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        let hour = calendarWithTimeZone.component(.hour, from: Date())

        if hour >= 5 && hour < 12 {
            return "morning"
        } else if hour >= 12 && hour < 18 {
            return "afternoon"
        } else {
            return "evening"
        }
    }
}
