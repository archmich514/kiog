import SwiftUI
import FirebaseFirestore

struct LivingScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var reports: [Report] = []
    @State private var isLoading = true
    @State private var isDebugLoading = false
    @State private var showDebugAlert = false
    @State private var showDebugError = false
    @State private var debugErrorMessage = ""

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        headerSection
                        kiogSection
                    }
                }

                footerSection
            }

            if isDebugLoading {
                debugLoadingOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await fetchReports()
        }
        .alert("デバッグ実行", isPresented: $showDebugAlert) {
            Button("実行") {
                Task { await triggerDebugReport() }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("レポートを即時生成しますか？\n（録音データが必要です）")
        }
        .alert("エラー", isPresented: $showDebugError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(debugErrorMessage)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("LIVING")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.black)
                    .tracking(1.8)

                Spacer()

                // DEBUGボタン
                Button(action: {
                    showDebugAlert = true
                }) {
                    Text("DEBUG")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(4)
                }
            }

            Text("#\(navigationManager.unitId)")
                .font(.system(size: 24))
                .foregroundColor(.black)
                .tracking(1.8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private var kiogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("KIOG")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .tracking(1.8)

                Spacer()

                if !reports.isEmpty {
                    Button(action: {
                        navigationManager.navigateTo(.kiogList)
                    }) {
                        Text("ALL →")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                            .tracking(1.8)
                    }
                }
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else if reports.isEmpty {
                Text("KIOGはありません")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.grayText)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 16) {
                    ForEach(reports.prefix(3)) { report in
                        ReportCard(dateText: report.dateText) {
                            navigationManager.navigateTo(.reportDetail(report: report))
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var footerSection: some View {
        VStack {
            Button(action: {
                navigationManager.navigateTo(.recording)
            }) {
                Text("RECをはじめる")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.black)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 32)
        .background(AppColors.background)
    }

    private var debugLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("レポート生成中...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(40)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
        }
    }

    private func fetchReports() async {
        do {
            let snapshot = try await db.collection("reports")
                .whereField("unitId", isEqualTo: navigationManager.unitId)
                .order(by: "createdAt", descending: true)
                .limit(to: 10)
                .getDocuments()

            let fetchedReports = snapshot.documents.compactMap { doc -> Report? in
                let data = doc.data()
                guard let date = data["date"] as? String,
                      let content = data["content"] as? String else { return nil }

                let components = date.split(separator: "-")
                guard components.count == 3,
                      let month = Int(components[1]),
                      let day = Int(components[2]) else { return nil }

                return Report(month: month, day: day, content: content)
            }

            await MainActor.run {
                self.reports = fetchedReports
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch reports: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    private func triggerDebugReport() async {
        await MainActor.run {
            isDebugLoading = true
        }

        do {
            try await DebugService.shared.triggerReportGeneration(unitId: navigationManager.unitId)
            await fetchReports()
        } catch {
            print("Debug report generation failed: \(error)")
            await MainActor.run {
                debugErrorMessage = "レポート生成に失敗しました。\n録音データがあるか確認してください。"
                showDebugError = true
            }
        }

        await MainActor.run {
            isDebugLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        LivingScreen()
            .environmentObject({
                let manager = NavigationManager()
                manager.unitId = "ABC12345"
                return manager
            }())
    }
}
