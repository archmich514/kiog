import SwiftUI

struct QuestionCard: View {
    let questionText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(questionText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1.8)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 21)
            .frame(height: 64)
            .background(AppColors.green)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        QuestionCard(questionText: "今日の晩ごはんは何がいい?") {}
        QuestionCard(questionText: "週末どこに行きたい?") {}
    }
    .padding()
    .background(AppColors.background)
}
