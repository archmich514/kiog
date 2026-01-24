import FirebaseMessaging
import FirebaseFirestore

class FCMService: NSObject, MessagingDelegate {
    static let shared = FCMService()

    private let db = Firestore.firestore()

    private override init() {
        super.init()
    }

    func setup() {
        Messaging.messaging().delegate = self
    }

    // FCMトークンを取得してFirestoreに保存
    func updateToken() {
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("FCM token error: \(error)")
                return
            }

            guard let token = token else { return }
            self?.saveTokenToFirestore(token)
        }
    }

    // MessagingDelegate: トークンが更新された時
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("FCM token received: \(token)")
        saveTokenToFirestore(token)
    }

    private func saveTokenToFirestore(_ token: String) {
        guard let userId = AuthService.shared.userId else {
            print("No user ID, cannot save FCM token")
            return
        }

        Task {
            do {
                try await db.collection("users").document(userId).updateData([
                    "fcmToken": token
                ])
                print("FCM token saved to Firestore")
            } catch {
                print("Failed to save FCM token: \(error)")
            }
        }
    }
}
