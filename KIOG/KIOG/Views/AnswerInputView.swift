import SwiftUI

struct AnswerInputView: View {
    let question: QuestionItem
    let unitId: String
    let userId: String
    let userName: String
    let onComplete: () -> Void

    @EnvironmentObject var navigationManager: NavigationManager

    @State private var answerText = ""
    @State private var isSubmitting = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // ヘッダー
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                Spacer()

                // 質問表示
                VStack(spacing: 16) {
                    if question.isAI {
                        Text("AI")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.green)
                            .cornerRadius(4)
                    }

                    Text(question.text)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // 回答入力
                TextField("回答を入力", text: $answerText, axis: .vertical)
                    .font(.system(size: 16))
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .lineLimit(3...6)

                Spacer()

                // 送信ボタン
                Button(action: submitAnswer) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("回答する")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(answerText.isEmpty ? Color.gray : Color.black)
                .disabled(answerText.isEmpty || isSubmitting)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private func submitAnswer() {
        isSubmitting = true

        Task {
            // ダミーデータチェック（開発用）
            #if DEBUG
            if question.questionId?.hasPrefix("debug") == true || question.questionId == nil {
                print("[DEBUG] Dummy question detected, skipping Firestore update")
                await MainActor.run {
                    // NavigationManagerに回答済みを通知
                    navigationManager.answeredQuestionTextToAdd = question.text
                    isSubmitting = false
                    onComplete()
                    dismiss()
                }
                return
            }
            #endif

            do {
                try await AnswerService.shared.submitAnswer(
                    question: question,
                    answer: answerText,
                    unitId: unitId,
                    userId: userId,
                    userName: userName
                )

                await MainActor.run {
                    onComplete()
                    dismiss()
                }
            } catch {
                print("Failed to submit answer: \(error)")
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    AnswerInputView(
        question: QuestionItem(questionId: "q001", text: "今日の晩ごはんは何がいい？", isAI: false),
        unitId: "ABC12345",
        userId: "user123",
        userName: "太郎",
        onComplete: {}
    )
    .environmentObject(NavigationManager())
}
