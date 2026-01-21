import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.black)
                .cornerRadius(0)
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    PrimaryButton(title: "START") {}
        .background(AppColors.background)
}
