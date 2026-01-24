# KIOG Phase 2: 認証・ユーザー登録 依頼書

## 1. 概要

Phase 1で作成した静的UIに、Firebase連携を追加してユーザー認証とデータ保存を実装する。

### 今回のゴール
- アプリ起動時に匿名認証でユーザーIDを取得
- 名前・性別をFirestoreに保存
- UNIT（グループ）の作成・参加機能
- 実際にデータが保存され、アプリを再起動しても維持される状態

---

## 2. 技術構成

```
【使用するFirebaseサービス】
├── Authentication（匿名認証）
├── Firestore Database（データ保存）
└── （Storage、Cloud Functionsは Phase 3以降）

【追加するSwiftパッケージ】
└── firebase-ios-sdk
```

---

## 3. セットアップ手順

### 3.1 GoogleService-Info.plist の配置

1. プロジェクトの `KIOG/KIOG/` フォルダに `GoogleService-Info.plist` を配置
2. Xcodeでプロジェクトに追加（ドラッグ＆ドロップ）
3. 「Copy items if needed」にチェック
4. ターゲット「KIOG」にチェックが入っていることを確認

### 3.2 Firebase SDK の追加

**Swift Package Manager を使用：**

1. Xcode → File → Add Package Dependencies
2. URL入力: `https://github.com/firebase/firebase-ios-sdk`
3. 以下のライブラリを選択:
   - FirebaseAuth
   - FirebaseFirestore

### 3.3 Firebase 初期化

**KIOGApp.swift に追加：**

```swift
import SwiftUI
import FirebaseCore

@main
struct KIOGApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## 4. データ構造（Firestore）

### 4.1 コレクション設計

```
firestore/
├── users/
│   └── {userId}/
│       ├── name: String          // ユーザー名
│       ├── gender: String        // "男性" or "女性"
│       ├── unitId: String?       // 所属UNIT ID（未参加ならnull）
│       └── createdAt: Timestamp  // 作成日時
│
└── units/
    └── {unitId}/                 // 6桁の招待コード
        ├── createdBy: String     // 作成者のuserId
        ├── members: [String]     // メンバーのuserId配列
        └── createdAt: Timestamp  // 作成日時
```

### 4.2 例

```
users/
  └── abc123/
        ├── name: "Akira"
        ├── gender: "男性"
        ├── unitId: "482910"
        └── createdAt: 2025-01-18 10:00:00

units/
  └── 482910/
        ├── createdBy: "abc123"
        ├── members: ["abc123", "xyz789"]
        └── createdAt: 2025-01-18 10:00:00
```

---

## 5. 実装する機能

### 5.1 認証サービス（AuthService）

**ファイル: `Services/AuthService.swift`**

```swift
import FirebaseAuth

class AuthService: ObservableObject {
    @Published var userId: String?
    @Published var isAuthenticated = false
    
    init() {
        // 既存のログイン状態を確認
        if let user = Auth.auth().currentUser {
            self.userId = user.uid
            self.isAuthenticated = true
        }
    }
    
    // 匿名認証
    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        await MainActor.run {
            self.userId = result.user.uid
            self.isAuthenticated = true
        }
    }
}
```

### 5.2 ユーザーサービス（UserService）

**ファイル: `Services/UserService.swift`**

```swift
import FirebaseFirestore

class UserService: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var currentUser: UserModel?
    
    // ユーザー情報を保存
    func saveUser(userId: String, name: String, gender: String) async throws {
        let userData: [String: Any] = [
            "name": name,
            "gender": gender,
            "unitId": NSNull(),
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("users").document(userId).setData(userData)
    }
    
    // ユーザー情報を取得
    func fetchUser(userId: String) async throws -> UserModel? {
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let data = doc.data() else { return nil }
        return UserModel(
            id: userId,
            name: data["name"] as? String ?? "",
            gender: data["gender"] as? String ?? "",
            unitId: data["unitId"] as? String
        )
    }
    
    // ユーザーのunitIdを更新
    func updateUnitId(userId: String, unitId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "unitId": unitId
        ])
    }
}
```

### 5.3 UNITサービス（UnitService）

**ファイル: `Services/UnitService.swift`**

```swift
import FirebaseFirestore

class UnitService: ObservableObject {
    private let db = Firestore.firestore()
    
    // 6桁のランダムなUNIT IDを生成
    private func generateUnitId() -> String {
        let digits = "0123456789"
        return String((0..<6).map { _ in digits.randomElement()! })
    }
    
    // UNITを作成
    func createUnit(createdBy userId: String) async throws -> String {
        var unitId = generateUnitId()
        
        // 重複チェック（既存のIDがあれば再生成）
        while try await unitExists(unitId: unitId) {
            unitId = generateUnitId()
        }
        
        let unitData: [String: Any] = [
            "createdBy": userId,
            "members": [userId],
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("units").document(unitId).setData(unitData)
        return unitId
    }
    
    // UNITが存在するか確認
    func unitExists(unitId: String) async throws -> Bool {
        let doc = try await db.collection("units").document(unitId).getDocument()
        return doc.exists
    }
    
    // UNITに参加
    func joinUnit(unitId: String, userId: String) async throws {
        let unitRef = db.collection("units").document(unitId)
        try await unitRef.updateData([
            "members": FieldValue.arrayUnion([userId])
        ])
    }
    
    // UNIT情報を取得
    func fetchUnit(unitId: String) async throws -> UnitModel? {
        let doc = try await db.collection("units").document(unitId).getDocument()
        guard let data = doc.data() else { return nil }
        return UnitModel(
            id: unitId,
            createdBy: data["createdBy"] as? String ?? "",
            members: data["members"] as? [String] ?? []
        )
    }
}
```

---

## 6. モデル

### 6.1 UserModel

**ファイル: `Models/UserModel.swift`**

```swift
import Foundation

struct UserModel: Identifiable {
    let id: String
    let name: String
    let gender: String
    let unitId: String?
}
```

### 6.2 UnitModel

**ファイル: `Models/UnitModel.swift`**

```swift
import Foundation

struct UnitModel: Identifiable {
    let id: String
    let createdBy: String
    let members: [String]
}
```

---

## 7. 画面の更新

### 7.1 アプリ起動時の認証フロー

**ContentView.swift を更新：**

```swift
struct ContentView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var userService = UserService()
    @State private var isLoading = true
    @State private var hasCompletedRegistration = false
    
    var body: some View {
        Group {
            if isLoading {
                // ローディング画面
                ProgressView()
            } else if !authService.isAuthenticated {
                // 未認証 → スプラッシュ画面
                SplashScreen(onStart: handleStart)
            } else if !hasCompletedRegistration {
                // 認証済みだが未登録 → 登録画面
                RegistrationScreen(
                    authService: authService,
                    userService: userService,
                    onComplete: { handleRegistrationComplete() }
                )
            } else if userService.currentUser?.unitId == nil {
                // 登録済みだがUNIT未参加 → UNIT選択画面
                UnitSelectScreen(...)
            } else {
                // 全て完了 → メイン画面
                LivingScreen(...)
            }
        }
        .task {
            await checkAuthState()
        }
    }
    
    private func handleStart() {
        Task {
            try await authService.signInAnonymously()
        }
    }
    
    private func checkAuthState() async {
        // 既存ユーザーの確認ロジック
        isLoading = false
    }
}
```

### 7.2 RegistrationScreen の更新

**変更点：**
- 名前入力 → `@State var name: String`
- 性別選択 → `@State var gender: String`
- NextButton押下時 → `UserService.saveUser()` を呼び出し
- 保存成功 → UnitSelectScreenに遷移

### 7.3 UnitSelectScreen の更新

**変更点：**
- 「UNITを作成」押下時:
  1. `UnitService.createUnit()` でUNIT作成
  2. `UserService.updateUnitId()` でユーザーにunitIdを紐付け
  3. LivingScreenに遷移

- 「UNITに入室」押下時:
  1. 入力されたUNIT IDの存在確認
  2. `UnitService.joinUnit()` でメンバー追加
  3. `UserService.updateUnitId()` でユーザーにunitIdを紐付け
  4. LivingScreenに遷移

- 存在しないUNIT ID入力時:
  - エラーメッセージ表示「このUNIT IDは存在しません」

### 7.4 LivingScreen の更新

**変更点：**
- UNIT IDを表示（`#{unitId}`）
- ユーザー情報をFirestoreから取得して表示

---

## 8. エラーハンドリング

### 8.1 ネットワークエラー

```swift
do {
    try await userService.saveUser(...)
} catch {
    // エラーアラート表示
    showError = true
    errorMessage = "保存に失敗しました。ネットワーク接続を確認してください。"
}
```

### 8.2 UNIT参加エラー

```swift
// 存在しないUNIT IDの場合
if !(try await unitService.unitExists(unitId: inputUnitId)) {
    showError = true
    errorMessage = "このUNIT IDは存在しません"
    return
}
```

---

## 9. テスト確認項目

### 9.1 認証

- [ ] アプリ起動時に匿名認証が成功する
- [ ] 認証後、userIdが取得できる
- [ ] アプリを再起動しても認証状態が維持される

### 9.2 ユーザー登録

- [ ] 名前・性別を入力して保存できる
- [ ] Firestoreにユーザーデータが保存される
- [ ] アプリ再起動後もユーザー情報が取得できる

### 9.3 UNIT作成

- [ ] 「UNITを作成」で6桁のIDが生成される
- [ ] FirestoreにUNITデータが保存される
- [ ] ユーザーのunitIdが更新される
- [ ] LivingScreenにUNIT IDが表示される

### 9.4 UNIT参加

- [ ] 既存のUNIT IDを入力して参加できる
- [ ] メンバー配列にユーザーが追加される
- [ ] 存在しないUNIT IDでエラーが表示される

---

## 10. ファイル構成（Phase 2完了後）

```
KIOG/
├── KIOGApp.swift（Firebase初期化追加）
├── ContentView.swift（認証フロー追加）
├── Views/
│   ├── SplashScreen.swift
│   ├── RegistrationScreen.swift（Firebase連携追加）
│   ├── UnitSelectScreen.swift（Firebase連携追加）
│   ├── LivingScreen.swift（実データ表示）
│   ├── KiogListScreen.swift
│   ├── ReportDetailScreen.swift
│   └── RecordingScreen.swift
├── Components/
│   └── （Phase 1で作成済み）
├── Models/
│   ├── UserModel.swift（新規）
│   └── UnitModel.swift（新規）
├── Services/
│   ├── AuthService.swift（新規）
│   ├── UserService.swift（新規）
│   └── UnitService.swift（新規）
└── Resources/
    ├── Assets.xcassets
    └── GoogleService-Info.plist（新規配置）
```

---

## 11. 注意事項

### 11.1 Firestoreセキュリティルール

現在「テストモード」で誰でも読み書き可能。本番前に以下のようなルールに変更が必要：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /units/{unitId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

→ Phase 2ではテストモードのままでOK

### 11.2 GoogleService-Info.plist

- **Gitにコミットしない**（.gitignoreに追加）
- APIキーなどの機密情報が含まれる

---

## 12. 依頼内容まとめ

### 実装してほしいこと

1. Firebase SDK の追加と初期化
2. GoogleService-Info.plist の配置確認
3. AuthService, UserService, UnitService の実装
4. UserModel, UnitModel の実装
5. ContentView の認証フロー実装
6. RegistrationScreen のFirebase連携
7. UnitSelectScreen のFirebase連携
8. LivingScreen でのUNIT ID表示

### 成果物

- Firebase連携が完了したXcodeプロジェクト
- シミュレータで以下が確認できる状態：
  - 名前・性別登録 → Firestoreに保存
  - UNIT作成 → 6桁ID発行、LivingScreenに遷移
  - UNIT参加 → 既存UNITに参加、LivingScreenに遷移

---

## 13. 提供ファイル

- GoogleService-Info.plist（Firebaseからダウンロード済み）
