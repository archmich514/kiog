import Foundation
import FirebaseAuth

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    var userId: String? {
        currentUser?.uid
    }

    private init() {
        currentUser = Auth.auth().currentUser
        isAuthenticated = currentUser != nil

        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }

    func signInAnonymously() async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let result = try await Auth.auth().signInAnonymously()
            await MainActor.run {
                self.currentUser = result.user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
    }
}
