import SwiftUI

struct AuthView: View {
    @AppStorage("auth_token") var token = ""
    @AppStorage("user_id") var userId = 0
    @AppStorage("username") var storedUsername = ""

    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isLogin = true
    @State private var error = ""
    @State private var loading = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "1a0533"), Color.black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 6) {
                    Text("Recomendo")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Music that knows you.")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "b084f5"))
                }

                VStack(spacing: 14) {
                    inputField(placeholder: "Email", text: $email, keyboard: .emailAddress)

                    if !isLogin {
                        inputField(placeholder: "Username (visible to others)", text: $username, keyboard: .default)
                    }

                    secureField(placeholder: "Password", text: $password)

                    if !error.isEmpty {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

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
                }
                .padding(.horizontal, 32)

                Button(isLogin ? "Don't have an account? Sign up" : "Already have an account? Log in") {
                    isLogin.toggle()
                    email = ""
                    username = ""
                    password = ""
                    error = ""
                }
                .foregroundColor(Color(hex: "b084f5"))
                .font(.footnote)

                Spacer()
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            }
        }
    }

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

    func secureField(placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .padding()
            .background(Color.white.opacity(0.08))
            .cornerRadius(14)
            .foregroundColor(.white)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12)))
    }

    func submit() {
        error = ""
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please fill in all fields."
            return
        }
        if !isLogin && username.isEmpty {
            error = "Please choose a username."
            return
        }
        loading = true
        Task {
            do {
                let response: AuthResponse
                if isLogin {
                    response = try await APIService.shared.login(email: email, password: password)
                } else {
                    response = try await APIService.shared.register(username: username, email: email, password: password)
                }
                await MainActor.run {
                    token = response.token
                    userId = response.user_id
                    storedUsername = response.username
                }
            } catch APIError.server(409) {
                await MainActor.run {
                    error = isLogin ? "Invalid email or password." : "Username or email already taken."
                    loading = false
                }
            } catch APIError.server(400) {
                await MainActor.run {
                    error = isLogin ? "Invalid email or password." : "Check your details and try again."
                    loading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Couldn't connect. Check your internet and try again."
                    loading = false
                }
            }
        }
    }
}
