import AVFoundation
import FirebaseStorage
import FirebaseFirestore

class RecordingService: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private let storage = Storage.storage()
    private let db = Firestore.firestore()

    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var recordingId: String?
    @Published var permissionDenied = false
    @Published var uploadError: Error?

    let maxRecordingTime: TimeInterval = 90 * 60
    let warningTime: TimeInterval = 85 * 60

    private var recordingURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("recording.m4a")
    }

    override init() {
        super.init()
        setupInterruptionObserver()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() throws {
        let session = AVAudioSession.sharedInstance()

        // バックグラウンド録音に最適な設定
        // .playAndRecord カテゴリ: バックグラウンド録音に必要
        // .spokenAudio モード: 音声録音に最適化
        try session.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [.defaultToSpeaker, .allowBluetooth]
        )

        // オーディオセッションをアクティブ化
        // .notifyOthersOnDeactivation: 非アクティブ時に他のアプリに通知
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Interruption Handling

    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // 割り込み開始（電話着信など）
            // 録音は自動的に一時停止される
            print("Recording interrupted")

        case .ended:
            // 割り込み終了
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

            if options.contains(.shouldResume) {
                // 録音を再開
                Task { @MainActor in
                    do {
                        try self.setupAudioSession()
                        self.audioRecorder?.record()
                        print("Recording resumed")
                    } catch {
                        print("Failed to resume recording: \(error)")
                    }
                }
            }

        @unknown default:
            break
        }
    }

    // MARK: - Recording Control

    func startRecording() async throws {
        let permission = await AVAudioApplication.requestRecordPermission()
        guard permission else {
            await MainActor.run {
                self.permissionDenied = true
            }
            throw RecordingError.permissionDenied
        }

        // オーディオセッション設定
        try setupAudioSession()

        // 録音設定
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,  // モノラルに変更（ファイルサイズ削減）
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000  // 128kbps
        ]

        // 既存の録音ファイルを削除
        try? FileManager.default.removeItem(at: recordingURL)

        // 録音開始
        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true

        let success = audioRecorder?.record() ?? false
        guard success else {
            throw RecordingError.recordingFailed
        }

        await MainActor.run {
            isRecording = true
            recordingTime = 0
            recordingId = UUID().uuidString
        }

        await MainActor.run {
            startTimer()
        }

        print("Recording started successfully")
    }

    func stopRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false

        // オーディオセッションを非アクティブ化
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        print("Recording stopped")
    }

    // MARK: - Timer

    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                self.recordingTime += 1

                if self.recordingTime == self.warningTime {
                    NotificationService.shared.sendRecordingWarningNotification()
                }

                if self.recordingTime >= self.maxRecordingTime {
                    self.stopRecording()
                }
            }
        }

        // バックグラウンドでもタイマーが動作するようRunLoopに追加
        RunLoop.current.add(recordingTimer!, forMode: .common)
    }

    // MARK: - Upload

    func uploadRecording(unitId: String, userId: String) async throws -> String {
        guard let recordingId = recordingId else {
            throw RecordingError.noRecording
        }

        // ファイルが存在するか確認
        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
            throw RecordingError.noRecording
        }

        let recordingRef = db.collection("recordings").document(recordingId)
        try await recordingRef.setData([
            "unitId": unitId,
            "recordedBy": userId,
            "duration": Int(recordingTime),
            "status": "uploading",
            "createdAt": FieldValue.serverTimestamp()
        ])

        let storageRef = storage.reference()
            .child("recordings")
            .child(unitId)
            .child("\(recordingId).m4a")

        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"

        _ = try await storageRef.putFileAsync(from: recordingURL, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()

        try await recordingRef.updateData([
            "storageUrl": downloadURL.absoluteString,
            "status": "uploaded",
            "uploadedAt": FieldValue.serverTimestamp()
        ])

        // ローカルファイル削除
        try? FileManager.default.removeItem(at: recordingURL)

        return recordingId
    }

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
        if flag {
            print("Recording finished successfully")
        } else {
            print("Recording failed")
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording encode error: \(error)")
        }
    }
}

// MARK: - Error

enum RecordingError: Error, LocalizedError {
    case permissionDenied
    case noRecording
    case uploadFailed
    case recordingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "マイクの使用が許可されていません"
        case .noRecording:
            return "録音データがありません"
        case .uploadFailed:
            return "アップロードに失敗しました"
        case .recordingFailed:
            return "録音の開始に失敗しました"
        }
    }
}
