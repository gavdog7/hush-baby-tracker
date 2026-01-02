import Foundation
import AuthenticationServices
import FirebaseAuth
import FirebaseCore

/// Manages user authentication state and flows
@MainActor
@Observable
final class AuthService: NSObject {
    // MARK: - State

    /// The currently authenticated user
    private(set) var currentUser: User?

    /// Whether the user is authenticated
    var isAuthenticated: Bool {
        currentUser != nil
    }

    /// Whether authentication is in progress
    private(set) var isLoading = false

    /// Error message from last operation
    var errorMessage: String?

    /// Firebase Auth instance
    private let auth = Auth.auth()

    /// User repository for persistence
    private let userRepository: UserRepository

    // MARK: - Initialization

    override init() {
        self.userRepository = UserRepository()
        super.init()

        // Listen for auth state changes
        auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                await self?.handleAuthStateChange(firebaseUser)
            }
        }
    }

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        super.init()

        auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                await self?.handleAuthStateChange(firebaseUser)
            }
        }
    }

    // MARK: - Auth State

    private func handleAuthStateChange(_ firebaseUser: FirebaseAuth.User?) async {
        if let firebaseUser = firebaseUser {
            // User is signed in
            let user = User(
                firebaseUID: firebaseUser.uid,
                email: firebaseUser.email,
                displayName: firebaseUser.displayName
            )

            do {
                currentUser = try userRepository.createOrUpdate(user)
                userRepository.setCurrentUser(currentUser)
            } catch {
                errorMessage = "Failed to save user: \(error.localizedDescription)"
            }
        } else {
            // User is signed out
            currentUser = nil
            userRepository.setCurrentUser(nil)
        }
    }

    // MARK: - Sign in with Apple

    /// Handles Sign in with Apple authorization
    func handleSignInWithApple(authorization: ASAuthorization) async {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            errorMessage = "Failed to get Apple ID credential"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let credential = OAuthProvider.appleCredential(
                withIDToken: tokenString,
                rawNonce: nil,
                fullName: appleIDCredential.fullName
            )

            let result = try await auth.signIn(with: credential)

            // Update display name if provided
            if let fullName = appleIDCredential.fullName {
                let displayName = PersonNameComponentsFormatter.localizedString(
                    from: fullName,
                    style: .default
                )
                if !displayName.isEmpty {
                    let changeRequest = result.user.createProfileChangeRequest()
                    changeRequest.displayName = displayName
                    try await changeRequest.commitChanges()
                }
            }
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }

    /// Creates the Sign in with Apple request
    func createAppleSignInRequest() -> ASAuthorizationAppleIDRequest {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        return request
    }

    // MARK: - Email/Password Auth

    /// Signs in with email and password
    func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.signIn(withEmail: email, password: password)
        } catch {
            errorMessage = mapAuthError(error)
        }
    }

    /// Creates a new account with email and password
    func createAccount(email: String, password: String, displayName: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await auth.createUser(withEmail: email, password: password)

            // Set display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
        } catch {
            errorMessage = mapAuthError(error)
        }
    }

    /// Sends a password reset email
    func resetPassword(email: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = mapAuthError(error)
        }
    }

    // MARK: - Sign Out

    /// Signs out the current user
    func signOut() {
        do {
            try auth.signOut()
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete Account

    /// Deletes the current user's account
    func deleteAccount() async {
        isLoading = true
        defer { isLoading = false }

        guard let firebaseUser = auth.currentUser else {
            errorMessage = "No user signed in"
            return
        }

        do {
            // Delete user data first
            if let user = currentUser {
                try userRepository.delete(user)
            }

            // Delete Firebase account
            try await firebaseUser.delete()
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
        }
    }

    // MARK: - Error Mapping

    private func mapAuthError(_ error: Error) -> String {
        let nsError = error as NSError

        switch nsError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address"
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Email already in use"
        case AuthErrorCode.weakPassword.rawValue:
            return "Password is too weak"
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password"
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email"
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Check your connection."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Try again later."
        default:
            return error.localizedDescription
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            await handleSignInWithApple(authorization: authorization)
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Sign in with Apple failed: \(error.localizedDescription)"
            }
        }
    }
}
