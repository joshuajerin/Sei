import Foundation
import Supabase

class SessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false

    init() {
        print("SessionManager initialized")
        Task {
            await checkSession()
        }
    }

    func checkSession() async {
        print("Checking session...")
        do {
            let authSession = try await SupabaseManager.shared.client.auth.session
            print("Session found: \(authSession.user.email ?? "no email")")
            DispatchQueue.main.async {
                self.isLoggedIn = true
                print("Updated isLoggedIn to true")
            }
        } catch {
            print("No valid session found: \(error)")
            DispatchQueue.main.async {
                self.isLoggedIn = false
                print("Updated isLoggedIn to false")
            }
        }
    }

    func signOut() async {
        print("Signing out...")
        do {
            try await SupabaseManager.shared.client.auth.signOut()
            print("Sign out successful")
            await checkSession()
        } catch {
            print("Sign out error: \(error)")
        }
    }
} 