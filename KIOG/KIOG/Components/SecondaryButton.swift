import SwiftUI

struct SecondaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isEnabled ? .white : AppColors.grayText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isEnabled ? Color.black : AppColors.gray)
                .cornerRadius(0)
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        SecondaryButton(title: "UNITに入室", isEnabled: false) {}
        SecondaryButton(title: "UNITに入室", isEnabled: true) {}
    }
    .padding()
    .background(AppColors.background)
}
