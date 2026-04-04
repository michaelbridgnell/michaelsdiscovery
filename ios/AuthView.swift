import SwiftUI

struct AuthView: View {
    @AppStorage("auth_token") var token = ""
    @AppStorage("user_id") var userId = 0
    @AppStorage("username") var storedUsername = ""

    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isLogin = true
    @State private var showPassword = false
    @State private var error = ""
    @State private var loading = false
    @State private var appeared = false
    @State private var showForgotAlert = false

    // Dancing emoji animation states
    @State private var danceAngle: Double = -18
    @State private var danceScale: CGFloat = 0.9
    @State private var noteOffset: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "1a0533"), Color.black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // ── Comically out-of-place corner animation ─────────────────────
            GeometryReader { geo in
                VStack(spacing: 2) {
                    Text("🕺")
                        .font(.system(size: 30))
                        .rotationEffect(.degrees(danceAngle))
                        .scaleEffect(danceScale)
                    Text("♪")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "a855f7").opacity(0.6))
                        .offset(y: noteOffset)
                }
                .position(x: geo.size.width - 36, y: geo.size.height - 100)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.38).repeatForever(autoreverses: true)) {
                        danceAngle = 18
                    }
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        danceScale = 1.12
                    }
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        noteOffset = -8
                    }
                }
            }
            .ignoresSafeArea()

            // ── Main form ───────────────────────────────────────────────────
            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 48)

                    // Logo
                    VStack(spacing: 8) {
                        Text("Recomendo")
                            .font(.custom("AvenirNext-Heavy", size: 50))
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
                        inputField(
                            placeholder: "Email",
                            text: $email,
                            keyboard: .emailAddress
                        )

                        if !isLogin {
                            inputField(
                                placeholder: "Username (shown to others)",
                                text: $username,
                                keyboard: .default
                            )
                        }

                        // Password field with eye toggle
                        ZStack(alignment: .trailing) {
                            if showPassword {
                                TextField("Password", text: $password)
                                    .autocapitalization(.none)
                                    .padding()
                                    .padding(.trailing, 44)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(14)
                                    .foregroundColor(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.12)))
                            } else {
                                SecureField("Password", text: $password)
                                    .padding()
                                    .padding(.trailing, 44)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(14)
                                    .foregroundColor(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.12)))
                            }
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 14)
                            }
                        }

                        // Password requirements (register only)
                        if !isLogin && !password.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                requirementRow("At least 8 characters", met: password.count >= 8)
                                requirementRow("Contains a letter", met: password.contains(where: \.isLetter))
                                requirementRow("Contains a number", met: password.contains(where: \.isNumber))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .transition(.opacity)
                        }

                        // Error
                        if !error.isEmpty {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Submit
                        Button(action: submit) {
                            if loading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isLogin ? "Log In" : "Create Account")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [Color(hex: "7c3aed"), Color(hex: "a855f7")],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .disabled(loading)
                        .animation(.none, value: loading)
                    }
                    .padding(.horizontal, 32)

                    // Forgot / Switch
                    VStack(spacing: 10) {
                        if isLogin {
                            Button("Forgot password?") {
                                showForgotAlert = true
                            }
                            .foregroundColor(Color(hex: "b084f5").opacity(0.7))
                            .font(.footnote)
                        }

                        Button(isLogin
                               ? "Don't have an account? Sign up"
                               : "Already have an account? Log in") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLogin.toggle()
                                error = ""
                                // Keep email/password — don't clear on switch
                            }
                        }
                        .foregroundColor(Color(hex: "b084f5"))
                        .font(.footnote)
                    }

                    Spacer().frame(height: 80)
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .onAppear {
                withAnimation(.easeOut(duration: 0.55)) { appeared = true }
            }
        }
        .alert("Reset Password", isPresented: $showForgotAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Email support@recomendo.app from your registered address and we'll send a reset link.")
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

    func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(met ? Color(hex: "a855f7") : .gray)
            Text(text)
                .font(.caption)
                .foregroundColor(met ? .white : .gray)
        }
    }

    // MARK: - Submit

    func submit() {
        error = ""
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please enter your email."
            return
        }
        guard !password.isEmpty else {
            error = "Please enter your password."
            return
        }
        if !isLogin {
            guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
                error = "Please choose a username."
                return
            }
            guard password.count >= 8 else {
                error = "Password must be at least 8 characters."
                return
            }
            guard password.contains(where: \.isLetter),
                  password.contains(where: \.isNumber) else {
                error = "Password must contain a letter and a number."
                return
            }
        }

        loading = true
        Task {
            do {
                let response: AuthResponse
                if isLogin {
                    response = try await APIService.shared.login(
                        email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                        password: password
                    )
                } else {
                    response = try await APIService.shared.register(
                        username: username.trimmingCharacters(in: .whitespaces),
                        email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                        password: password
                    )
                }
                await MainActor.run {
                    token = response.token
                    userId = response.user_id
                    storedUsername = response.username
                }
            } catch APIError.server(let code) {
                await MainActor.run {
                    switch code {
                    case 401:
                        error = "Wrong email or password."
                    case 409:
                        error = "Username or email is already taken."
                    case 400:
                        error = "Check your details — email must be valid, username 3-50 chars."
                    case 429:
                        error = "Too many attempts. Wait a minute and try again."
                    default:
                        error = "Server error (\(code)). Try again shortly."
                    }
                    loading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Can't reach the server. Check your internet or wait 30s — the AI is starting up."
                    loading = false
                }
            }
        }
    }
}
