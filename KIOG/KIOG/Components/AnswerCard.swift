import SwiftUI

struct AnswerCard: View {
    let name: String
    let question: String
    var answer: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    cardContent
                }
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(1.8)

            Text(question)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(1.8)

            if let answer = answer {
                Text(answer)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(AppColors.salmon)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        AnswerCard(
            name: "太郎",
            question: "今日の晩ごはんは何がいい?",
            answer: "カレーが食べたいな"
        )
        AnswerCard(
            name: "太郎",
            question: "今日の晩ごはんは何がいい?",
            action: {}
        )
    }
    .padding()
    .background(AppColors.background)
}
