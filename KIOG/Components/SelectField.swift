import SwiftUI

struct SelectField: View {
    let placeholder: String
    let selectedValue: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(selectedValue ?? placeholder)
                    .font(.system(size: 16))
                    .foregroundColor(selectedValue == nil ? AppColors.placeholder : .black)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(AppColors.grayText)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(5)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SelectField(placeholder: "性別を選択してください", selectedValue: nil) {}
        SelectField(placeholder: "性別を選択してください", selectedValue: "男性") {}
    }
    .padding()
    .background(AppColors.background)
}
