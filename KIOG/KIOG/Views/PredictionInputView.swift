import SwiftUI

struct PredictionInputView: View {
    let answer: AnswerItem
    let userId: String
    let userName: String
    let onComplete: () -> Void

    @State private var predictionText = ""
    @State private var showActualAnswer = false
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
                Text(answer.questionText)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // 予想入力または結果表示
                if !showActualAnswer {
                    predictionInputSection
                } else {
                    resultSection
                }

                Spacer()

                // ボタン
                if !showActualAnswer {
                    Button(action: submitPrediction) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("予想する")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(predictionText.isEmpty ? Color.gray : Color.black)
                    .disabled(predictionText.isEmpty || isSubmitting)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                } else {
                    Button(action: {
                        onComplete()
                        dismiss()
                    }) {
                        Text("閉じる")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var predictionInputSection: some View {
        VStack(spacing: 16) {
            Text("\(answer.userName)さんは何と答えた？")
                .font(.system(size: 16))
                .foregroundColor(AppColors.grayText)

            TextField("予想を入力", text: $predictionText, axis: .vertical)
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
        }
    }

    private var resultSection: some View {
        VStack(spacing: 24) {
            // あなたの予想
            VStack(spacing: 8) {
                Text("あなたの予想")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.grayText)

                Text(predictionText)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)

            // 実際の回答
            VStack(spacing: 8) {
                Text("\(answer.userName)さんの回答")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.grayText)

                Text(answer.answer)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.salmon.opacity(0.3))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
        }
    }

    private func submitPrediction() {
        isSubmitting = true

        Task {
            do {
                try await AnswerService.shared.submitPrediction(
                    answerId: answer.id,
                    prediction: predictionText,
                    userId: userId,
                    userName: userName
                )

                await MainActor.run {
                    showActualAnswer = true
                    isSubmitting = false
                }
            } catch {
                print("Failed to submit prediction: \(error)")
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    PredictionInputView(
        answer: AnswerItem(
            documentId: "answer123",
            from: [
                "userName": "太郎",
                "questionText": "今日の晩ごはんは何がいい？",
                "answer": "カレーが食べたいな",
                "userId": "user456"
            ]
        )!,
        userId: "user123",
        userName: "花子",
        onComplete: {}
    )
}
