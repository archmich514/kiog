import SwiftUI

struct KiogListScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager

    private let sampleReports = [
        Report(month: 1, day: 15, content: "今日は二人でカフェに行った。新しいメニューを試してみて、とても美味しかった。"),
        Report(month: 1, day: 14, content: "映画を観に行った。久しぶりのデートで楽しかった。"),
        Report(month: 1, day: 13, content: "一緒に料理を作った。ハンバーグを作って大成功!"),
        Report(month: 1, day: 12, content: "公園を散歩した。天気が良くて気持ちよかった。"),
        Report(month: 1, day: 11, content: "ゲームを一緒にプレイした。すごく盛り上がった!"),
        Report(month: 1, day: 10, content: "誕生日のお祝いをした。サプライズ大成功!")
    ]

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(sampleReports) { report in
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
        .navigationBarBackButtonHidden(true)
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
}

#Preview {
    NavigationStack {
        KiogListScreen()
            .environmentObject(NavigationManager())
    }
}
