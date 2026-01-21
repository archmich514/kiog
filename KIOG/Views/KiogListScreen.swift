import SwiftUI
import FirebaseFirestore

struct KiogListScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var reports: [Report] = []
    @State private var isLoading = true

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if reports.isEmpty {
                    Spacer()
                    Text("KIOGはありません")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.grayText)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(reports) { report in
                                ReportCard(dateText: report.dateText) {
                                    navigationManager.navigateTo(.reportDetail(report: report))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await fetchReports()
        }
    }

    private var headerSection: some View {
        HStack(spacing: 0) {
            BackButton {
                navigationManager.goBack()
            }

            Text("KIOG")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.black)
                .tracking(1.8)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private func fetchReports() async {
        do {
            let snapshot = try await db.collection("reports")
                .whereField("unitId", isEqualTo: navigationManager.unitId)
                .order(by: "createdAt", descending: true)
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
}

#Preview {
    NavigationStack {
        KiogListScreen()
            .environmentObject({
                let manager = NavigationManager()
                manager.unitId = "ABC12345"
                return manager
            }())
    }
}
