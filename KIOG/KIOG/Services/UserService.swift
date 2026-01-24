import Foundation
import FirebaseFirestore

struct UserData: Codable {
    let name: String
    let gender: String
    var unitId: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case name
        case gender
        case unitId
        case createdAt
    }
}

class UserService: ObservableObject {
    static let shared = UserService()

    private let db = Firestore.firestore()
    private let collectionName = "users"

    @Published var currentUserData: UserData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    func saveUser(userId: String, name: String, gender: Gender) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        let userData = UserData(
            name: name,
            gender: gender.rawValue,
            unitId: nil,
            createdAt: Date()
        )

        do {
            try await db.collection(collectionName).document(userId).setData([
                "name": userData.name,
                "gender": userData.gender,
                "unitId": userData.unitId as Any,
                "createdAt": Timestamp(date: userData.createdAt)
            ])

            await MainActor.run {
                self.currentUserData = userData
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

    func updateUnitId(userId: String, unitId: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            try await db.collection(collectionName).document(userId).updateData([
                "unitId": unitId
            ])

            await MainActor.run {
                if var userData = self.currentUserData {
                    userData.unitId = unitId
                    self.currentUserData = userData
                }
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

    func fetchUser(userId: String) async throws -> UserData? {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let document = try await db.collection(collectionName).document(userId).getDocument()

            guard document.exists, let data = document.data() else {
                await MainActor.run {
                    self.isLoading = false
                }
                return nil
            }

            let createdAtTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())

            let userData = UserData(
                name: data["name"] as? String ?? "",
                gender: data["gender"] as? String ?? "",
                unitId: data["unitId"] as? String,
                createdAt: createdAtTimestamp.dateValue()
            )

            await MainActor.run {
                self.currentUserData = userData
                self.isLoading = false
            }

            return userData
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
}
