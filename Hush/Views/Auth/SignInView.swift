import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthService.self) private var authService
    @State private var showEmailSignIn = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // App logo/branding
                VStack(spacing: 16) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.sleep)

                    Text("Hush")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Simple baby tracking\nfor exhausted parents")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Sign in buttons
                VStack(spacing: 16) {
                    // Sign in with Apple (primary)
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                Task {
                                    await authService.handleSignInWithApple(authorization: authorization)
                                }
                            case .failure(let error):
                                if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                                    authService.errorMessage = error.localizedDescription
                                }
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)

                    // Email sign in (secondary)
                    Button(action: { showEmailSignIn = true }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Sign in with Email")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 32)

                // Loading indicator
                if authService.isLoading {
                    ProgressView()
                        .padding()
                }

                Spacer()
                    .frame(height: 50)
            }
            .sheet(isPresented: $showEmailSignIn) {
                EmailSignInView()
            }
            .alert("Error", isPresented: .init(
                get: { authService.errorMessage != nil },
                set: { if !$0 { authService.errorMessage = nil } }
            )) {
                Button("OK") { authService.errorMessage = nil }
            } message: {
                if let error = authService.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

// MARK: - Email Sign In

struct EmailSignInView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var isCreatingAccount = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            Form {
                if isCreatingAccount {
                    Section("Your Name") {
                        TextField("Display name", text: $displayName)
                            .textContentType(.name)
                            .autocapitalization(.words)
                    }
                }

                Section("Credentials") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textContentType(isCreatingAccount ? .newPassword : .password)
                }

                Section {
                    Button(action: submit) {
                        if authService.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(isCreatingAccount ? "Create Account" : "Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isValid || authService.isLoading)
                }

                Section {
                    Button(action: { isCreatingAccount.toggle() }) {
                        Text(isCreatingAccount ? "Already have an account? Sign In" : "Don't have an account? Create one")
                            .font(.footnote)
                            .frame(maxWidth: .infinity)
                    }

                    if !isCreatingAccount {
                        Button(action: { showForgotPassword = true }) {
                            Text("Forgot password?")
                                .font(.footnote)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(isCreatingAccount ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView(email: email)
            }
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    dismiss()
                }
            }
        }
    }

    private var isValid: Bool {
        !email.isEmpty && !password.isEmpty && (!isCreatingAccount || !displayName.isEmpty)
    }

    private func submit() {
        Task {
            if isCreatingAccount {
                await authService.createAccount(
                    email: email,
                    password: password,
                    displayName: displayName
                )
            } else {
                await authService.signIn(email: email, password: password)
            }
        }
    }
}

// MARK: - Forgot Password

struct ForgotPasswordView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State var email: String
    @State private var emailSent = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                } footer: {
                    Text("We'll send you a link to reset your password.")
                }

                Section {
                    Button(action: resetPassword) {
                        if authService.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Send Reset Link")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(email.isEmpty || authService.isLoading)
                }

                if emailSent {
                    Section {
                        Label("Check your email for the reset link", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func resetPassword() {
        Task {
            await authService.resetPassword(email: email)
            if authService.errorMessage == nil {
                emailSent = true
            }
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthService())
}
