import SwiftUI

struct AnswerCard: View {
    let name: String
    let question: String
    let answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(1.8)

            Text(question)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(1.8)

            Text(answer)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(1.8)
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
    AnswerCard(
        name: "太郎",
        question: "今日の晩ごはんは何がいい?",
        answer: "カレーが食べたいな"
    )
    .padding()
    .background(AppColors.background)
}
