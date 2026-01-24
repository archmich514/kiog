import SwiftUI

struct SplashScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var authService = AuthService.shared
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 64) {
                Spacer()

                Image("LogoImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 357, height: 357)

                Spacer()

                Button(action: {
                    handleStart()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.black)
                    } else {
                        Text("START")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.black)
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            checkExistingUser()
        }
    }

    private func handleStart() {
        isLoading = true

        Task {
            do {
                if !authService.isAuthenticated {
                    try await authService.signInAnonymously()
                }

                if let userId = authService.userId {
                    let userData = try await UserService.shared.fetchUser(userId: userId)
                    if let userData = userData, let unitId = userData.unitId, !unitId.isEmpty {
                        await MainActor.run {
                            navigationManager.userName = userData.name
                            navigationManager.userGender = Gender(rawValue: userData.gender)
                            navigationManager.unitId = unitId
                            navigationManager.goToLiving()
                            isLoading = false
                        }
                        return
                    }
                }

                await MainActor.run {
                    navigationManager.navigateTo(.registration)
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

    private func checkExistingUser() {
        if authService.isAuthenticated, let userId = authService.userId {
            Task {
                do {
                    let userData = try await UserService.shared.fetchUser(userId: userId)
                    if let userData = userData, let unitId = userData.unitId, !unitId.isEmpty {
                        await MainActor.run {
                            navigationManager.userName = userData.name
                            navigationManager.userGender = Gender(rawValue: userData.gender)
                            navigationManager.unitId = unitId
                            navigationManager.goToLiving()
                        }
                    }
                } catch {
                    // Ignore errors on auto-check
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SplashScreen()
            .environmentObject(NavigationManager())
    }
}
