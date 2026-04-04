import SwiftUI

struct ContentView: View {
    @AppStorage("auth_token") var token = ""
    @AppStorage("onboarding_done") var onboardingDone = false

    var body: some View {
        if token.isEmpty {
            AuthView()
        } else if !onboardingDone {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}
