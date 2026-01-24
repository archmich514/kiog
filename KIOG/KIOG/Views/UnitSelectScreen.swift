import SwiftUI

struct UnitSelectScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var authService = AuthService.shared
    let selectedGender: Gender
    @State private var unitId: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var canJoinUnit: Bool {
        !unitId.isEmpty && !isLoading
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 25) {
                Text("UNIT")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.black)
                    .tracking(1.8)
                    .padding(.top, 64)

                Image(selectedGender == .male ? "MaleIllustration" : "FemaleIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 362, height: 362)

                CustomTextField(
                    placeholder: "UNIT IDを入力してください",
                    text: $unitId
                )

                VStack(spacing: 24) {
                    SecondaryButton(title: "UNITに入室", isEnabled: canJoinUnit) {
                        handleJoinUnit()
                    }

                    Button(action: {
                        handleCreateUnit()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.black)
                        } else {
                            Text("UNITを作成")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.black)
                        }
                    }
                    .disabled(isLoading)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .navigationBarBackButtonHidden(true)
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func handleCreateUnit() {
        guard let userId = authService.userId else { return }

        isLoading = true

        Task {
            do {
                let newUnitId = try await UnitService.shared.createUnit(userId: userId)
                try await UserService.shared.updateUnitId(userId: userId, unitId: newUnitId)

                await MainActor.run {
                    navigationManager.unitId = newUnitId
                    navigationManager.goToLiving()
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

    private func handleJoinUnit() {
        guard let userId = authService.userId else { return }

        isLoading = true

        Task {
            do {
                try await UnitService.shared.joinUnit(userId: userId, unitId: unitId)
                let trimmedUnitId = unitId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                try await UserService.shared.updateUnitId(userId: userId, unitId: trimmedUnitId)

                await MainActor.run {
                    navigationManager.unitId = trimmedUnitId
                    navigationManager.goToLiving()
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

#Preview {
    NavigationStack {
        UnitSelectScreen(selectedGender: .male)
            .environmentObject(NavigationManager())
    }
}
