import SwiftUI

struct ReportDetailScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    let report: Report

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                headerSection

                reportContentSection

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var headerSection: some View {
        HStack(spacing: 0) {
            BackButton {
                navigationManager.goBack()
            }

            Text(report.dateText)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.black)
                .tracking(1.8)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private var reportContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(report.dateText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            Text(report.content)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        ReportDetailScreen(
            report: Report(
                month: 1,
                day: 15,
                content: "今日は二人でカフェに行った。新しいメニューを試してみて、とても美味しかった。帰りに公園を散歩して、とても楽しい一日だった。"
            )
        )
        .environmentObject(NavigationManager())
    }
}
