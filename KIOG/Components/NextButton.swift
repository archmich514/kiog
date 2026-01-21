import SwiftUI

struct NextButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isEnabled ? Color.black : AppColors.gray)
                    .frame(width: 80, height: 80)

                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isEnabled ? .white : AppColors.grayText)
            }
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    HStack(spacing: 20) {
        NextButton(isEnabled: false) {}
        NextButton(isEnabled: true) {}
    }
    .padding()
    .background(AppColors.background)
}
