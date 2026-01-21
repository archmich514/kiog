import Foundation
import FirebaseFirestore

struct UnitData: Codable {
    let createdBy: String
    var members: [String]
    let createdAt: Date
}

enum UnitError: LocalizedError {
    case unitNotFound
    case alreadyMember
    case invalidUnitId

    var errorDescription: String? {
        switch self {
        case .unitNotFound:
            return "UNITが見つかりません"
        case .alreadyMember:
            return "既にこのUNITのメンバーです"
        case .invalidUnitId:
            return "無効なUNIT IDです"
        }
    }
}

class UnitService: ObservableObject {
    static let shared = UnitService()

    private let db = Firestore.firestore()
    private let collectionName = "units"

    @Published var currentUnit: UnitData?
    @Published var currentUnitId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    func createUnit(userId: String) async throws -> String {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        let unitId = generateUnitId()

        let unitData = UnitData(
            createdBy: userId,
            members: [userId],
            createdAt: Date()
        )

        do {
            try await db.collection(collectionName).document(unitId).setData([
                "createdBy": unitData.createdBy,
                "members": unitData.members,
                "createdAt": Timestamp(date: unitData.createdAt)
            ])

            await MainActor.run {
                self.currentUnit = unitData
                self.currentUnitId = unitId
                self.isLoading = false
            }

            return unitId
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }

    func joinUnit(userId: String, unitId: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        let trimmedUnitId = unitId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard !trimmedUnitId.isEmpty else {
            await MainActor.run {
                self.errorMessage = UnitError.invalidUnitId.localizedDescription
                self.isLoading = false
            }
            throw UnitError.invalidUnitId
        }

        do {
            let document = try await db.collection(collectionName).document(trimmedUnitId).getDocument()

            guard document.exists else {
                await MainActor.run {
                    self.errorMessage = UnitError.unitNotFound.localizedDescription
                    self.isLoading = false
                }
                throw UnitError.unitNotFound
            }

            guard let data = document.data() else {
                await MainActor.run {
                    self.errorMessage = UnitError.unitNotFound.localizedDescription
                    self.isLoading = false
                }
                throw UnitError.unitNotFound
            }

            var members = data["members"] as? [String] ?? []

            if members.contains(userId) {
                await MainActor.run {
                    self.errorMessage = UnitError.alreadyMember.localizedDescription
                    self.isLoading = false
                }
                throw UnitError.alreadyMember
            }

            members.append(userId)

            try await db.collection(collectionName).document(trimmedUnitId).updateData([
                "members": members
            ])

            let createdAtTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
            let unitData = UnitData(
                createdBy: data["createdBy"] as? String ?? "",
                members: members,
                createdAt: createdAtTimestamp.dateValue()
            )

            await MainActor.run {
                self.currentUnit = unitData
                self.currentUnitId = trimmedUnitId
                self.isLoading = false
            }
        } catch let error as UnitError {
            throw error
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }

    func fetchUnit(unitId: String) async throws -> UnitData? {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let document = try await db.collection(collectionName).document(unitId).getDocument()

            guard document.exists, let data = document.data() else {
                await MainActor.run {
                    self.isLoading = false
                }
                return nil
            }

            let createdAtTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
            let unitData = UnitData(
                createdBy: data["createdBy"] as? String ?? "",
                members: data["members"] as? [String] ?? [],
                createdAt: createdAtTimestamp.dateValue()
            )

            await MainActor.run {
                self.currentUnit = unitData
                self.currentUnitId = unitId
                self.isLoading = false
            }

            return unitData
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }

    private func generateUnitId() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}
