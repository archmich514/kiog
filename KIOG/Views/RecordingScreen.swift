import SwiftUI

struct RecordingScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var recordingService = RecordingService()
    @State private var showBackConfirmation = false
    @State private var showGenerateConfirmation = false
    @State private var showPermissionAlert = false
    @State private var showUploadError = false
    @State private var isUploading = false

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                headerSection

                timerSection

                generateButtonSection

                Spacer()
            }

            if isUploading {
                uploadingOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            do {
                try await recordingService.startRecording()
            } catch RecordingError.permissionDenied {
                showPermissionAlert = true
            } catch {
                print("Recording start error: \(error)")
            }
        }
        .onDisappear {
            if recordingService.isRecording {
                recordingService.stopRecording()
            }
        }
        .onChange(of: recordingService.permissionDenied) { _, denied in
            if denied {
                showPermissionAlert = true
            }
        }
        .alert("生成完了", isPresented: $showGenerateConfirmation) {
            Button("完了") {
                handleGenerate()
            }
        } message: {
            Text("生成までに時間がかかります。生成が完了したら通知を送ります")
        }
        .confirmationDialog(
            "レコーディングを終了してKIOGを生成しますか？",
            isPresented: $showBackConfirmation,
            titleVisibility: .visible
        ) {
            Button("終了しKIOGを生成") {
                handleGenerate()
            }
            Button("KIOGを生成せずに終了", role: .destructive) {
                handleDiscard()
            }
            Button("キャンセル", role: .cancel) {}
        }
        .alert("マイクの使用が許可されていません", isPresented: $showPermissionAlert) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("キャンセル", role: .cancel) {
                navigationManager.goToLiving()
            }
        } message: {
            Text("設定アプリからマイクの使用を許可してください")
        }
        .alert("アップロードに失敗しました", isPresented: $showUploadError) {
            Button("再試行") {
                handleGenerate()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("ネットワーク接続を確認してください")
        }
    }

    private var headerSection: some View {
        HStack(spacing: 0) {
            BackButton {
                showBackConfirmation = true
            }

            Text("REC")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.black)
                .tracking(1.8)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private var timerSection: some View {
        VStack(alignment: .leading) {
            Text(formatTime(recordingService.recordingTime) + " / 90:00")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.black)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 32)
    }

    private var generateButtonSection: some View {
        Button(action: {
            showGenerateConfirmation = true
        }) {
            Text("KIOGを生成")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isUploading ? Color.gray : Color.black)
        }
        .disabled(isUploading)
        .padding(.horizontal, 16)
    }

    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("アップロード中...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(40)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func handleGenerate() {
        guard !isUploading else { return }
        isUploading = true
        recordingService.stopRecording()

        Task {
            do {
                _ = try await recordingService.uploadRecording(
                    unitId: navigationManager.unitId,
                    userId: AuthService.shared.userId ?? ""
                )
                await MainActor.run {
                    isUploading = false
                    navigationManager.goToLiving()
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                    showUploadError = true
                }
                print("Upload failed: \(error)")
            }
        }
    }

    private func handleDiscard() {
        recordingService.discardRecording()
        navigationManager.goToLiving()
    }
}

#Preview {
    NavigationStack {
        RecordingScreen()
            .environmentObject({
                let manager = NavigationManager()
                manager.unitId = "ABC12345"
                return manager
            }())
    }
}
