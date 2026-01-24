import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(AppColors.placeholder))
            .font(.system(size: 16))
            .foregroundColor(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(5)
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextField(placeholder: "お名前を入力してください", text: .constant(""))
        CustomTextField(placeholder: "お名前を入力してください", text: .constant("田中太郎"))
    }
    .padding()
    .background(AppColors.background)
}
