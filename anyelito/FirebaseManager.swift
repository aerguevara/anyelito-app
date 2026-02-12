import Foundation
import FirebaseCore
import FirebaseAuth
import Combine

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private init() {
        // Initialization is handled by FirebaseApp.configure() in the App struct
    }
    
    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        DispatchQueue.main.async {
            self.currentUser = result.user
            self.isAuthenticated = true
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
}
