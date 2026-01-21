import Foundation
import FirebaseFirestore

struct RecordingModel: Identifiable, Codable {
    @DocumentID var id: String?
    var unitId: String
    var recordedBy: String
    var duration: Int
    var storageUrl: String?
    var status: RecordingStatus
    var createdAt: Timestamp?
    var uploadedAt: Timestamp?

    enum RecordingStatus: String, Codable {
        case uploading
        case uploaded
        case processing
        case completed
    }
}
