import SwiftUI

struct ContentView: View {
    @StateObject private var navigationManager = NavigationManager()

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            SplashScreen()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .registration:
                        RegistrationScreen()
                    case .unitSelect(let gender):
                        UnitSelectScreen(selectedGender: gender)
                    case .living:
                        LivingScreen()
                    case .kiogList:
                        KiogListScreen()
                    case .reportDetail(let report):
                        ReportDetailScreen(report: report)
                    case .recording:
                        RecordingScreen()
                    case .prediction(let answer):
                        PredictionScreen(answer: answer)
                    }
                }
        }
        .environmentObject(navigationManager)
    }
}

#Preview {
    ContentView()
}
