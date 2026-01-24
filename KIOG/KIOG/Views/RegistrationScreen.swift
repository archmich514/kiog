import SwiftUI

struct RegistrationScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var authService = AuthService.shared
    @State private var name: String = ""
    @State private var selectedGender: Gender?
    @State private var showGenderPicker: Bool = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var isFormValid: Bool {
        !name.isEmpty && selectedGender != nil
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 25) {
                Text("START")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.black)
                    .tracking(1.8)
                    .padding(.top, 64)

                Image("RegistrationIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 362, height: 362)

                VStack(spacing: 24) {
                    CustomTextField(
                        placeholder: "お名前を入力してください",
                        text: $name
                    )

                    SelectField(
                        placeholder: "性別を選択してください",
                        selectedValue: selectedGender?.rawValue,
                        action: {
                            showGenderPicker = true
                        }
                    )
                }

                Spacer()

                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        NextButton(isEnabled: isFormValid && !isLoading) {
                            handleNext()
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 16)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showGenderPicker) {
            GenderPickerSheet(selectedGender: $selectedGender)
                .presentationDetents([.height(250)])
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func handleNext() {
        guard let gender = selectedGender, let userId = authService.userId else { return }

        isLoading = true

        Task {
            do {
                try await UserService.shared.saveUser(userId: userId, name: name, gender: gender)

                await MainActor.run {
                    navigationManager.userName = name
                    navigationManager.userGender = gender
                    navigationManager.navigateTo(.unitSelect(gender: gender))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

struct GenderPickerSheet: View {
    @Binding var selectedGender: Gender?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("性別を選択")
                .font(.headline)
                .padding(.top)

            Picker("性別", selection: $selectedGender) {
                Text("選択してください").tag(nil as Gender?)
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(gender.rawValue).tag(gender as Gender?)
                }
            }
            .pickerStyle(.wheel)

            Button("完了") {
                dismiss()
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.black)
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    NavigationStack {
        RegistrationScreen()
            .environmentObject(NavigationManager())
    }
}
