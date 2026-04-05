import SwiftUI

struct AuthView: View {
    @AppStorage("auth_token") var token = ""
    @AppStorage("user_id") var userId = 0
    @AppStorage("username") var storedUsername = ""
    @AppStorage("onboarding_done") var onboardingDone = false

    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isLogin = true
    @State private var showPassword = false
    @State private var error = ""
    @State private var loading = false
    @State private var appeared = false
    @State private var showForgot = false
    @State private var showPrivacy = false
    @State private var showTerms = false

    // Real-time username availability
    enum FieldStatus { case idle, checking, available, taken, invalid }
    @State private var usernameStatus: FieldStatus = .idle
    @State private var usernameCheckTask: Task<Void, Never>? = nil
    @State private var emailStatus: FieldStatus = .idle
    @State private var emailCheckTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "1a0533"), Color.black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // ── Walking guy — bottom-right corner ───────────────────────
            // Wide frame so bodyX walk offsets don't clip him
            GeometryReader { geo in
                WalkingGuy()
                    .position(x: geo.size.width - 50, y: geo.size.height - 100)
            }
            .ignoresSafeArea()

            // ── Main form ───────────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer().frame(height: 52)

                    // Logo
                    VStack(spacing: 8) {
                        Text("Sonik")
                            .font(.custom("AvenirNext-Heavy", size: 56))
                            .italic()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(hex: "c084fc")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)
                            )
                        Text("Trained on raw sound. Powered by AI.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "b084f5"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 8)

                    // Fields
                    VStack(spacing: 12) {
                        // Email + taken indicator (register only)
                        ZStack(alignment: .trailing) {
                            inputField(placeholder: "Email", text: $email, keyboard: .emailAddress)
                                .onChange(of: email) { _, newVal in
                                    if !isLogin { checkEmail(newVal) }
                                }
                                .padding(.trailing, !isLogin ? 36 : 0)
                            if !isLogin {
                                statusIcon(emailStatus).padding(.trailing, 14)
                            }
                        }

                        if !isLogin {
                            // Username + availability indicator
                            ZStack(alignment: .trailing) {
                                inputField(placeholder: "Username (shown to others)",
                                           text: $username, keyboard: .default)
                                    .onChange(of: username) { _, newVal in
                                        checkUsername(newVal)
                                    }
                                    .padding(.trailing, 36)
                                usernameIndicator
                                    .padding(.trailing, 14)
                            }
                        }

                        // Password + eye toggle
                        ZStack(alignment: .trailing) {
                            Group {
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .autocapitalization(.none)
                                } else {
                                    SecureField("Password", text: $password)
                                }
                            }
                            .padding()
                            .padding(.trailing, 44)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.12)))

                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 14)
                            }
                        }

                        // Password requirements (register only)
                        if !isLogin && !password.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                reqRow("At least 8 characters", met: password.count >= 8)
                                reqRow("Contains a letter", met: password.contains(where: \.isLetter))
                                reqRow("Contains a number", met: password.contains(where: \.isNumber))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .transition(.opacity)
                        }

                        if !error.isEmpty {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button(action: submit) {
                            if loading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isLogin ? "Log In" : "Create Account")
                                    .fontWeight(.bold).foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(LinearGradient(
                            colors: [Color(hex: "7c3aed"), Color(hex: "a855f7")],
                            startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14)
                        .disabled(loading || (!isLogin && (usernameStatus == .taken || emailStatus == .taken)))
                    }
                    .padding(.horizontal, 32)

                    // Footer links
                    VStack(spacing: 10) {
                        if isLogin {
                            Button("Forgot password?") { showForgot = true }
                                .foregroundColor(Color(hex: "b084f5").opacity(0.7))
                                .font(.footnote)
                        }
                        Button(isLogin
                               ? "Don't have an account? Sign up"
                               : "Already have an account? Log in") {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                isLogin.toggle()
                                error = ""
                                usernameStatus = .idle
                                emailStatus = .idle
                            }
                        }
                        .foregroundColor(Color(hex: "b084f5"))
                        .font(.footnote)
                    }

                    // Legal links
                    HStack(spacing: 16) {
                        Button("Privacy Policy") { showPrivacy = true }
                        Text("·").foregroundColor(.gray.opacity(0.4))
                        Button("Terms of Service") { showTerms = true }
                    }
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.5))

                    Spacer().frame(height: 80)
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .onAppear {
                withAnimation(.easeOut(duration: 0.55)) { appeared = true }
            }
        }
        .sheet(isPresented: $showForgot) { ForgotPasswordView() }
        .sheet(isPresented: $showPrivacy) { LegalView(doc: .privacy) }
        .sheet(isPresented: $showTerms)  { LegalView(doc: .terms)   }
    }

    // MARK: - Field status indicator

    @ViewBuilder
    func statusIcon(_ status: FieldStatus) -> some View {
        switch status {
        case .idle: EmptyView()
        case .checking:
            ProgressView().scaleEffect(0.7).tint(.gray)
        case .available:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "a855f7")).font(.system(size: 16))
        case .taken:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red).font(.system(size: 16))
        case .invalid:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange).font(.system(size: 16))
        }
    }

    // Keep the ZStack in the username row pointing to this
    var usernameIndicator: some View { statusIcon(usernameStatus) }

    func checkEmail(_ value: String) {
        emailCheckTask?.cancel()
        let trimmed = value.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { emailStatus = .idle; return }
        emailStatus = .checking
        emailCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
            guard !Task.isCancelled else { return }
            let result = (try? await APIService.shared.checkEmail(trimmed)) ?? "invalid"
            await MainActor.run {
                if result == "available" { emailStatus = .available }
                else if result == "taken" { emailStatus = .taken }
                else { emailStatus = .idle }  // invalid format — don't show error yet
            }
        }
    }

    func checkUsername(_ value: String) {
        usernameCheckTask?.cancel()
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { usernameStatus = .idle; return }
        usernameStatus = .checking
        usernameCheckTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            do {
                let result = try await APIService.shared.checkUsername(trimmed)
                await MainActor.run {
                    if result == "available" { usernameStatus = .available }
                    else if result == "taken" { usernameStatus = .taken }
                    else { usernameStatus = .invalid }
                }
            } catch {
                await MainActor.run { usernameStatus = .idle }
            }
        }
    }

    // MARK: - Helpers

    func inputField(placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField(placeholder, text: text)
            .autocapitalization(.none)
            .keyboardType(keyboard)
            .padding()
            .background(Color.white.opacity(0.08))
            .cornerRadius(14)
            .foregroundColor(.white)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12)))
    }

    func reqRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(met ? Color(hex: "a855f7") : .gray)
            Text(text).font(.caption).foregroundColor(met ? .white : .gray)
        }
    }

    // MARK: - Submit

    func submit() {
        error = ""
        let trimEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimEmail.isEmpty else { error = "Please enter your email."; return }
        guard !password.isEmpty else { error = "Please enter your password."; return }

        if !isLogin {
            let trimUser = username.trimmingCharacters(in: .whitespaces)
            guard !trimUser.isEmpty else { error = "Please choose a username."; return }
            guard emailStatus != .taken else { error = "That email is already registered."; return }
            guard usernameStatus != .taken else { error = "That username is taken."; return }
            guard usernameStatus != .invalid else { error = "Username contains invalid or disallowed words."; return }
            guard password.count >= 8,
                  password.contains(where: \.isLetter),
                  password.contains(where: \.isNumber) else {
                error = "Password needs 8+ chars, a letter and a number."
                return
            }
        }

        loading = true
        Task {
            do {
                let response: AuthResponse
                if isLogin {
                    response = try await APIService.shared.login(
                        email: trimEmail.lowercased(), password: password)
                } else {
                    response = try await APIService.shared.register(
                        username: username.trimmingCharacters(in: .whitespaces),
                        email: trimEmail.lowercased(), password: password)
                }
                await MainActor.run {
                    token = response.token
                    userId = response.user_id
                    storedUsername = response.username
                    if !isLogin { onboardingDone = false }  // new account always sees onboarding
                }
            } catch APIError.server(let code) {
                await MainActor.run {
                    switch code {
                    case 401: error = "Wrong email or password."
                    case 409: error = "Username or email is already taken."
                    case 400: error = "Check your details — email must be valid, username 3-50 chars."
                    case 429: error = "Too many attempts. Wait a minute and try again."
                    default:  error = "Server error (\(code)). Try again shortly."
                    }
                    loading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Can't reach the server — it may be starting up (wait ~30s and retry)."
                    loading = false
                }
            }
        }
    }
}
