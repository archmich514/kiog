import SwiftUI

struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 44, height: 44)
        }
    }
}

#Preview {
    BackButton {}
        .background(AppColors.background)
}
