import SwiftUI

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @EnvironmentObject var session: SessionManager

    var body: some View {
        VStack(spacing: 24) {
            Text(isSignUp ? "Sign Up" : "Login")
                .font(.largeTitle)
                .bold()
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            Button(isSignUp ? "Sign Up" : "Login") {
                isLoading = true
                errorMessage = nil
                Task {
                    do {
                        if isSignUp {
                            let signUpResult = try await SupabaseManager.shared.client.auth.signUp(email: email, password: password)
                            print("Sign up result: \(signUpResult)")
                        } else {
                            let signInResult = try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)
                            print("Sign in result: \(signInResult)")
                        }
                        // Explicitly check session after auth action
                        await session.checkSession()
                        print("Session checked after auth. Is logged in: \(session.isLoggedIn)")
                    } catch {
                        errorMessage = error.localizedDescription
                        print("Auth error: \(error)")
                    }
                    isLoading = false
                }
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            .buttonStyle(.borderedProminent)
            
            if isLoading {
                ProgressView()
            }
            
            Button(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up") {
                isSignUp.toggle()
                errorMessage = nil
            }
            .font(.footnote)
        }
        .padding()
    }
} 