# KIOG Phase 3: 録音機能 依頼書

## 1. 概要

Phase 2で実装した認証・ユーザー登録に、録音機能を追加する。

### 今回のゴール
- マイクで音声を録音できる
- バックグラウンドでも録音が継続する
- 録音時間をリアルタイム表示（{RecordingTime} / 90:00）
- 85分経過で通知、90分で自動停止
- 録音ファイルをFirebase Storageにアップロード
- アップロード完了後、ローカルファイルを削除

---

## 2. 技術構成

```
【使用するフレームワーク】
├── AVFoundation（AVAudioRecorder）
├── BackgroundTasks（バックグラウンド録音）
└── UserNotifications（ローカル通知）

【使用するFirebaseサービス】
├── Authentication（既存）
├── Firestore Database（既存）
└── Storage（新規）← 音声ファイル保存
```

---

## 3. Firebase Storage セットアップ

### 3.1 Firebaseコンソールで有効化

1. Firebaseコンソール → Storage → 「始める」
2. 「テストモードで開始」を選択
3. ロケーション: `asia-northeast1`（東京）

### 3.2 Swift Package に追加

`project.yml` に FirebaseStorage を追加:

```yaml
packages:
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk
    version: 11.0.0
    products:
      - FirebaseAuth
      - FirebaseFirestore
      - FirebaseStorage  # 追加
```

---

## 4. Info.plist 設定

### 4.1 マイク使用許可

```xml
<key>NSMicrophoneUsageDescription</key>
<string>会話を録音してレポートを生成するために使用します</string>
```

### 4.2 バックグラウンドモード

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

---

## 5. データ構造

### 5.1 Firestore（recordings コレクション追加）

```
firestore/
├── users/（既存）
├── units/（既存）
└── recordings/
    └── {recordingId}/
        ├── oderId: String         // 所属UNIT ID
        ├── recordedBy: String     // 録音したユーザーID
        ├── duration: Int          // 録音時間（秒）
        ├── storageUrl: String     // Firebase Storage URL
        ├── status: String         // "uploading" | "uploaded" | "processing" | "completed"
        ├── createdAt: Timestamp   // 録音開始日時
        └── uploadedAt: Timestamp  // アップロード完了日時
```

### 5.2 Firebase Storage 構造

```
storage/
└── recordings/
    └── {unitId}/
        └── {recordingId}.m4a
```

---

## 6. 実装する機能

### 6.1 録音サービス（RecordingService）

**ファイル: `Services/RecordingService.swift`**

```swift
import AVFoundation
import FirebaseStorage
import FirebaseFirestore

class RecordingService: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0  // 秒
    @Published var recordingId: String?
    
    let maxRecordingTime: TimeInterval = 90 * 60  // 90分
    let warningTime: TimeInterval = 85 * 60       // 85分
    
    // 録音ファイルの一時保存パス
    private var recordingURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("recording.m4a")
    }
    
    // 録音開始
    func startRecording() async throws {
        // マイク許可確認
        let permission = await AVAudioApplication.requestRecordPermission()
        guard permission else {
            throw RecordingError.permissionDenied
        }
        
        // オーディオセッション設定
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true)
        
        // 録音設定
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // 録音開始
        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()
        
        await MainActor.run {
            isRecording = true
            recordingTime = 0
            recordingId = UUID().uuidString
        }
        
        // タイマー開始
        startTimer()
    }
    
    // 録音停止
    func stopRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
    }
    
    // タイマー処理
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.recordingTime += 1
                
                // 85分で通知
                if self.recordingTime == self.warningTime {
                    self.sendWarningNotification()
                }
                
                // 90分で自動停止
                if self.recordingTime >= self.maxRecordingTime {
                    self.stopRecording()
                }
            }
        }
    }
    
    // 85分通知
    private func sendWarningNotification() {
        let content = UNMutableNotificationContent()
        content.title = "録音終了まであと5分"
        content.body = "録音が終了しちゃうから、もう一回録音を付け直してね"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "recording_warning",
            content: content,
            trigger: nil  // 即時通知
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Firebase Storageにアップロード
    func uploadRecording(unitId: String, userId: String) async throws -> String {
        guard let recordingId = recordingId else {
            throw RecordingError.noRecording
        }
        
        // Firestoreにレコード作成（status: uploading）
        let recordingRef = db.collection("recordings").document(recordingId)
        try await recordingRef.setData([
            "unitId": unitId,
            "recordedBy": userId,
            "duration": Int(recordingTime),
            "status": "uploading",
            "createdAt": FieldValue.serverTimestamp()
        ])
        
        // Storageにアップロード
        let storageRef = storage.reference()
            .child("recordings")
            .child(unitId)
            .child("\(recordingId).m4a")
        
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"
        
        _ = try await storageRef.putFileAsync(from: recordingURL, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        // Firestoreを更新（status: uploaded）
        try await recordingRef.updateData([
            "storageUrl": downloadURL.absoluteString,
            "status": "uploaded",
            "uploadedAt": FieldValue.serverTimestamp()
        ])
        
        // ローカルファイル削除
        try? FileManager.default.removeItem(at: recordingURL)
        
        return recordingId
    }
    
    // 録音データを削除（生成せずに終了する場合）
    func discardRecording() {
        stopRecording()
        try? FileManager.default.removeItem(at: recordingURL)
        recordingId = nil
        recordingTime = 0
    }
}

// MARK: - AVAudioRecorderDelegate
extension RecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
}

// MARK: - Error
enum RecordingError: Error {
    case permissionDenied
    case noRecording
    case uploadFailed
}
```

### 6.2 通知サービス（NotificationService）

**ファイル: `Services/NotificationService.swift`**

```swift
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    // 通知許可をリクエスト
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }
    
    // 通知を送信
    func sendNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
```

---

## 7. 画面の更新

### 7.1 RecordingScreen の更新

**変更点：**

```swift
struct RecordingScreen: View {
    @StateObject private var recordingService = RecordingService()
    @State private var showGenerateAlert = false
    @State private var showBackAlert = false
    @State private var isUploading = false
    
    let unitId: String
    let userId: String
    let onComplete: () -> Void
    
    var body: some View {
        VStack {
            // Header
            Header(...)
            
            // Timer Display
            Text(formatTime(recordingService.recordingTime) + " / 90:00")
                .font(.system(size: 36, weight: .bold))
            
            Spacer()
            
            // Generate Button
            PrimaryButton(title: "KIOGを生成") {
                showGenerateAlert = true
            }
            .disabled(isUploading)
        }
        .task {
            // 録音開始
            try? await recordingService.startRecording()
        }
        .alert("KIOGを生成", isPresented: $showGenerateAlert) {
            Button("完了") {
                handleGenerate()
            }
        } message: {
            Text("生成までに時間がかかります。生成が完了したら通知を送ります")
        }
        .alert("レコーディングを終了しますか？", isPresented: $showBackAlert) {
            Button("終了しKIOGを生成") {
                handleGenerate()
            }
            Button("KIOGを生成せずに終了", role: .destructive) {
                handleDiscard()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }
    
    // 時間フォーマット（秒 → MM:SS）
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    // KIOGを生成
    private func handleGenerate() {
        isUploading = true
        Task {
            do {
                recordingService.stopRecording()
                _ = try await recordingService.uploadRecording(unitId: unitId, userId: userId)
                await MainActor.run {
                    onComplete()
                }
            } catch {
                print("Upload failed: \(error)")
            }
        }
    }
    
    // 生成せずに終了
    private func handleDiscard() {
        recordingService.discardRecording()
        onComplete()
    }
}
```

### 7.2 LivingScreen からの遷移

```swift
// LivingScreen.swift
NavigationLink(destination: RecordingScreen(
    unitId: unitId,
    userId: userId,
    onComplete: { /* LivingScreenに戻る */ }
)) {
    PrimaryButton(title: "RECをはじめる") {}
}
```

---

## 8. バックグラウンド録音の設定

### 8.1 project.yml に追加

```yaml
targets:
  KIOG:
    info:
      properties:
        UIBackgroundModes:
          - audio
        NSMicrophoneUsageDescription: 会話を録音してレポートを生成するために使用します
```

### 8.2 オーディオセッションの設定

RecordingServiceの `startRecording()` 内で設定済み：

```swift
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
try session.setActive(true)
```

---

## 9. 通知許可のリクエスト

### 9.1 アプリ起動時に許可リクエスト

**KIOGApp.swift または初回起動時：**

```swift
.task {
    await NotificationService.shared.requestPermission()
}
```

---

## 10. エラーハンドリング

### 10.1 マイク許可がない場合

```swift
// RecordingScreenで
.alert("マイクの使用が許可されていません", isPresented: $showPermissionAlert) {
    Button("設定を開く") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    Button("キャンセル", role: .cancel) {}
} message: {
    Text("設定アプリからマイクの使用を許可してください")
}
```

### 10.2 アップロード失敗

```swift
.alert("アップロードに失敗しました", isPresented: $showUploadError) {
    Button("再試行") {
        handleGenerate()
    }
    Button("キャンセル", role: .cancel) {}
} message: {
    Text("ネットワーク接続を確認してください")
}
```

---

## 11. テスト確認項目

### 11.1 録音

- [ ] 「RECをはじめる」押下で録音が開始する
- [ ] 録音時間がリアルタイムで更新される（00:00 → 00:01 → ...）
- [ ] マイク許可ダイアログが表示される（初回）

### 11.2 バックグラウンド

- [ ] ホームボタンを押してもタイマーが進む
- [ ] 他のアプリを開いても録音が継続する

### 11.3 停止・アップロード

- [ ] 「KIOGを生成」押下で録音が停止する
- [ ] モーダルが表示される
- [ ] Firebase Storageにファイルがアップロードされる
- [ ] Firestoreのrecordingsコレクションにデータが保存される
- [ ] LivingScreenに戻る

### 11.4 戻るボタン

- [ ] BackButton押下で確認モーダルが表示される
- [ ] 「終了しKIOGを生成」で生成処理が実行される
- [ ] 「KIOGを生成せずに終了」で録音データが削除される
- [ ] 「キャンセル」でモーダルが閉じる

### 11.5 自動停止（※長時間テスト）

- [ ] 85分で通知が届く
- [ ] 90分で自動停止する

---

## 12. ファイル構成（Phase 3完了後）

```
KIOG/
├── KIOGApp.swift
├── ContentView.swift
├── Views/
│   ├── SplashScreen.swift
│   ├── RegistrationScreen.swift
│   ├── UnitSelectScreen.swift
│   ├── LivingScreen.swift
│   ├── KiogListScreen.swift
│   ├── ReportDetailScreen.swift
│   └── RecordingScreen.swift（大幅更新）
├── Components/
│   └── （既存）
├── Models/
│   ├── UserModel.swift
│   ├── UnitModel.swift
│   └── RecordingModel.swift（新規）
├── Services/
│   ├── AuthService.swift
│   ├── UserService.swift
│   ├── UnitService.swift
│   ├── RecordingService.swift（新規）
│   └── NotificationService.swift（新規）
└── Resources/
    ├── Assets.xcassets
    └── GoogleService-Info.plist
```

---

## 13. 注意事項

### 13.1 シミュレータでのテスト制限

- シミュレータはマイクをサポートしていない
- **実機（iPhone）でテストが必要**
- 無料Apple IDで自分のiPhoneにインストール可能（7日間有効）

### 13.2 ローカルファイル削除

録音データがユーザーの端末に残り続けないよう、以下のタイミングで削除：

1. **アップロード成功後** → `uploadRecording()` 内で削除
2. **生成せずに終了** → `discardRecording()` で削除

### 13.3 Firebase Storage セキュリティルール

テストモードでは誰でもアクセス可能。本番前に以下のようなルールに変更：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /recordings/{unitId}/{recordingId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 14. 依頼内容まとめ

### 事前準備（自分でやること）

1. Firebaseコンソール → Storage → 「始める」→ テストモードで作成

### 実装してほしいこと

1. Firebase Storage SDK の追加
2. Info.plist にマイク許可とバックグラウンドモード追加
3. RecordingService の実装
4. NotificationService の実装
5. RecordingScreen の更新（実際の録音機能）
6. LivingScreen からの遷移連携

### 成果物

- 録音機能が動作するXcodeプロジェクト
- シミュレータではマイク不可のため、実機テスト推奨
- Firebase Storageに録音ファイルがアップロードされる状態

---

## 15. Firebase Storage 有効化手順（事前に実施）

1. Firebaseコンソール → 左サイドバー「構築」→「Storage」
2. 「始める」をクリック
3. 「テストモードで開始」を選択
4. ロケーション: `asia-northeast1`（東京）を選択
5. 「完了」をクリック
