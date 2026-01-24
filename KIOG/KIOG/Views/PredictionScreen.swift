import SwiftUI
import UIKit

struct PredictionScreen: View {
    let answer: AnswerItem
    @EnvironmentObject var navigationManager: NavigationManager

    @State private var predictionText = ""
    @State private var showConfirmAlert = false
    @State private var isSubmitting = false

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("ANS")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.black)
                        .tracking(1.8)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)

                // Illustration based on user gender
                illustrationView
                    .padding(.horizontal, 40)

                Spacer()

                // Question text
                Text(answer.questionText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(answer.userName)さんは何と答えた？")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.grayText)
                        .padding(.horizontal, 16)

                    TextField("相手のANSを予想してみて", text: $predictionText, axis: .vertical)
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

                Spacer()

                // Submit Button
                Button(action: submitPrediction) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("送信")
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
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    navigationManager.goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
        }
        .alert("確認", isPresented: $showConfirmAlert) {
            Button("了解") {
                navigationManager.goBack()
            }
        } message: {
            Text("相手の回答は今日のKIOGで確認できるよ")
        }
    }

    private var illustrationView: some View {
        Group {
            // PredictionIllustration_Male/Female が追加されたらそちらを使用
            // 現在は既存のイラストをフォールバックとして使用
            if navigationManager.userGender == .male {
                if UIImage(named: "PredictionIllustration_Male") != nil {
                    Image("PredictionIllustration_Male")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                } else {
                    Image("MaleIllustration")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                }
            } else if navigationManager.userGender == .female {
                if UIImage(named: "PredictionIllustration_Female") != nil {
                    Image("PredictionIllustration_Female")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                } else {
                    Image("FemaleIllustration")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                }
            } else {
                // Fallback: show placeholder icon
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 100)
                    .foregroundColor(AppColors.salmon)
            }
        }
    }

    private func submitPrediction() {
        guard let userId = AuthService.shared.userId else { return }

        // ダミーデータチェック（開発用）
        // FirestoreのドキュメントIDは通常20文字以上のランダム文字列
        // ダミーIDは短いため、これでスキップ判定する
        #if DEBUG
        if answer.id.count < 20 {
            print("[DEBUG] Dummy data detected, skipping Firestore update")
            // NavigationManagerに削除を通知
            navigationManager.pendingAnswerIdToRemove = answer.id
            showConfirmAlert = true
            return
        }
        #endif

        isSubmitting = true

        Task {
            do {
                try await AnswerService.shared.submitPrediction(
                    answerId: answer.id,
                    prediction: predictionText,
                    userId: userId,
                    userName: navigationManager.userName
                )

                await MainActor.run {
                    isSubmitting = false
                    showConfirmAlert = true
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
    NavigationStack {
        PredictionScreen(
            answer: AnswerItem(
                documentId: "answer123",
                from: [
                    "userName": "太郎",
                    "questionText": "今日の晩ごはんは何がいい？",
                    "answer": "カレーが食べたいな",
                    "userId": "user456"
                ]
            )!
        )
        .environmentObject({
            let manager = NavigationManager()
            manager.userName = "花子"
            manager.userGender = .female
            return manager
        }())
    }
}
