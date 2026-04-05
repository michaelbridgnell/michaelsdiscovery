import SwiftUI

struct ContentView: View {
    @AppStorage("auth_token") var token = ""
    @AppStorage("onboarding_done") var onboardingDone = false
    @State private var isReady = false
    @State private var showLoading = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isReady {
                if showLoading {
                    LoadingView()
                        .transition(.opacity)
                } else if token.isEmpty {
                    AuthView()
                        .transition(.opacity)
                } else if !onboardingDone {
                    OnboardingView()
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeOut(duration: 0.25), value: isReady)
        .animation(.easeOut(duration: 0.35), value: showLoading)
        .animation(.easeOut(duration: 0.35), value: token)
        .onAppear {
            DispatchQueue.main.async { isReady = true }
        }
        // Watch for a token being written (login/register success)
        .onChange(of: token) { oldVal, newVal in
            // Token just appeared — show loading screen briefly
            if oldVal.isEmpty && !newVal.isEmpty {
                showLoading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation { showLoading = false }
                }
            }
        }
    }
}
