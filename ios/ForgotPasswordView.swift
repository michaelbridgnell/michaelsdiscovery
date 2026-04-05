import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss

    @State private var step = 0          // 0 = enter email, 1 = enter code + new pw
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var showPassword = false
    @State private var loading = false
    @State private var message = ""
    @State private var isError = false
    @State private var done = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "1a0533"), Color.black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gray)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)

                Spacer()

                if done {
                    // ── Success ─────────────────────────────────────────
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(Color(hex: "a855f7"))
                        Text("Password updated!")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("You can now log in with your new password.")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button("Back to Login") { dismiss() }
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "7c3aed"))
                            .cornerRadius(14)
                            .padding(.horizontal, 32)
                    }
                } else if step == 0 {
                    // ── Step 1: Enter email ──────────────────────────────
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Forgot Password")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text("Enter the email on your account.\nWe'll send you a 6-digit reset code.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                        }

                        TextField("Email address", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.12)))
                            .padding(.horizontal, 32)

                        if !message.isEmpty {
                            Text(message)
                                .foregroundColor(isError ? .red : Color(hex: "a855f7"))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: sendCode) {
                            if loading { ProgressView().tint(.white) }
                            else { Text("Send Code").fontWeight(.bold).foregroundColor(.white) }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(LinearGradient(
                            colors: [Color(hex: "7c3aed"), Color(hex: "a855f7")],
                            startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14).padding(.horizontal, 32)
                        .disabled(loading || email.isEmpty)
                    }

                } else {
                    // ── Step 2: Enter code + new password ───────────────
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Enter Reset Code")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text("Check your email for the 6-digit code.\nIt expires in 15 minutes.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                        }

                        // 6-digit code field
                        TextField("6-digit code", text: $code)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "a855f7").opacity(0.4)))
                            .padding(.horizontal, 48)
                            .onChange(of: code) { _, v in if v.count > 6 { code = String(v.prefix(6)) } }

                        // New password
                        ZStack(alignment: .trailing) {
                            if showPassword {
                                TextField("New password", text: $newPassword)
                                    .autocapitalization(.none)
                                    .padding().padding(.trailing, 44)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(14).foregroundColor(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.12)))
                            } else {
                                SecureField("New password", text: $newPassword)
                                    .padding().padding(.trailing, 44)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(14).foregroundColor(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.12)))
                            }
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray).padding(.trailing, 14)
                            }
                        }
                        .padding(.horizontal, 32)

                        // Requirements
                        if !newPassword.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                reqRow("At least 8 characters", met: newPassword.count >= 8)
                                reqRow("Contains a letter", met: newPassword.contains(where: \.isLetter))
                                reqRow("Contains a number", met: newPassword.contains(where: \.isNumber))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 36)
                        }

                        if !message.isEmpty {
                            Text(message)
                                .foregroundColor(isError ? .red : Color(hex: "a855f7"))
                                .font(.caption).multilineTextAlignment(.center)
                        }

                        Button(action: resetPassword) {
                            if loading { ProgressView().tint(.white) }
                            else { Text("Reset Password").fontWeight(.bold).foregroundColor(.white) }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(LinearGradient(
                            colors: [Color(hex: "7c3aed"), Color(hex: "a855f7")],
                            startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14).padding(.horizontal, 32)
                        .disabled(loading || code.count != 6 || newPassword.count < 8)

                        Button("Resend code") { step = 0; message = ""; code = "" }
                            .foregroundColor(.gray).font(.footnote)
                    }
                }

                Spacer()
            }
        }
    }

    func reqRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(met ? Color(hex: "a855f7") : .gray)
            Text(text).font(.caption).foregroundColor(met ? .white : .gray)
        }
    }

    func sendCode() {
        let trimmed = email.trimmingCharacters(in: .whitespaces).lowercased()
        let emailOK = trimmed.contains("@") && trimmed.contains(".") && trimmed.count > 5
        guard emailOK else {
            message = "Please enter a valid email address."; isError = true; return
        }
        loading = true; message = ""
        Task {
            do {
                try await APIService.shared.forgotPassword(email: email.trimmingCharacters(in: .whitespaces).lowercased())
                await MainActor.run {
                    // Always show same message to prevent user enumeration
                    message = "If that email is registered, a code has been sent."
                    isError = false
                    loading = false
                    step = 1
                }
            } catch {
                await MainActor.run {
                    message = "Couldn't send. Check your internet and try again."
                    isError = true
                    loading = false
                }
            }
        }
    }

    func resetPassword() {
        guard newPassword.count >= 8,
              newPassword.contains(where: \.isLetter),
              newPassword.contains(where: \.isNumber) else {
            message = "Password must be 8+ characters with a letter and a number."
            isError = true
            return
        }
        loading = true; message = ""
        Task {
            do {
                try await APIService.shared.resetPassword(
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    code: code, newPassword: newPassword)
                await MainActor.run { loading = false; done = true }
            } catch APIError.server(400) {
                await MainActor.run {
                    message = "Invalid or expired code. Request a new one."
                    isError = true; loading = false
                }
            } catch {
                await MainActor.run {
                    message = "Couldn't connect. Try again."
                    isError = true; loading = false
                }
            }
        }
    }
}
