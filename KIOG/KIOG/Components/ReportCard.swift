import SwiftUI

struct ReportCard: View {
    let dateText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(dateText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1.8)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 21)
            .frame(height: 64)
            .background(AppColors.orange)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ReportCard(dateText: "1/15") {}
        ReportCard(dateText: "1/14") {}
    }
    .padding()
    .background(AppColors.background)
}
