import SwiftUI

struct ContentView: View {
    @AppStorage("auth_token") var token = ""
    @AppStorage("onboarding_done") var onboardingDone = false
    // One async tick lets @AppStorage fully read UserDefaults before any
    // view renders, preventing the one-frame flash of the wrong screen.
    @State private var isReady = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isReady {
                Group {
                    if token.isEmpty {
                        AuthView()
                    } else if !onboardingDone {
                        OnboardingView()
                    } else {
                        MainTabView()
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: isReady)
        .onAppear {
            DispatchQueue.main.async { isReady = true }
        }
    }
}
