import Foundation
import UIKit
import Combine
import GoogleSignIn
import Security

// MARK: - Empty Response


// MARK: - Authentication Models
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let avatarUrl: String?
    let authProvider: String
    let isGuest: Bool
    let preferences: UserPreferences?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case avatarUrl = "avatar_url"
        case authProvider = "auth_provider"
        case isGuest = "is_guest"
        case preferences
        case createdAt = "created_at"
    }
}

struct UserPreferences: Codable {
    let language: String?
    let theme: String?
    let notificationSettings: NotificationSettings?
    
    enum CodingKeys: String, CodingKey {
        case language
        case theme
        case notificationSettings = "notification_settings"
    }
}

struct NotificationSettings: Codable {
    let dailyReminder: Bool?
    let weeklyReport: Bool?
    let habitReminders: Bool?
    
    enum CodingKeys: String, CodingKey {
        case dailyReminder = "daily_reminder"
        case weeklyReport = "weekly_report"
        case habitReminders = "habit_reminders"
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case user
    }
}

// MARK: - Authentication Errors
enum AuthenticationError: LocalizedError {
    case invalidCredentials
    case networkError
    case tokenExpired
    case googleAuthFailed
    case keychainError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return NSLocalizedString("errors.invalid_credentials", comment: "")
        case .networkError:
            return NSLocalizedString("errors.network_error", comment: "")
        case .tokenExpired:
            return NSLocalizedString("errors.token_expired", comment: "")
        case .googleAuthFailed:
            return NSLocalizedString("errors.google_auth_failed", comment: "")
        case .keychainError:
            return NSLocalizedString("errors.keychain_error", comment: "")
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Authentication State
enum AuthenticationState {
    case loading
    case authenticated(User)
    case unauthenticated
    case error(AuthenticationError)
}

// MARK: - Authentication Manager
@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var authState: AuthenticationState = .loading
    @Published var currentUser: User?
    
    private let networkManager: NetworkManager
    private let keychainService: KeychainService
    private var cancellables = Set<AnyCancellable>()
    
    // Keychain keys
    private let accessTokenKey = "joury_access_token"
    private let refreshTokenKey = "joury_refresh_token"
    private let userDataKey = "joury_user_data"
    
    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
        self.keychainService = KeychainService()
        
        // Configure Google Sign-In
        configureGoogleSignIn()
        
        // Check for existing authentication
        Task {
            await checkExistingAuthentication()
        }
    }
    
    // MARK: - Public Methods
    
    func signInWithGoogle() async throws {
        do {
            authState = .loading
            
            guard let presentingViewController = await getRootViewController() else {
                throw AuthenticationError.googleAuthFailed
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthenticationError.googleAuthFailed
            }
            
            let authResponse = try await authenticateWithBackend(
                idToken: idToken,
                name: result.user.profile?.name,
                email: result.user.profile?.email,
                avatarUrl: result.user.profile?.imageURL(withDimension: 200)?.absoluteString
            )
            
            try await saveAuthenticationData(authResponse)
            
            currentUser = authResponse.user
            authState = .authenticated(authResponse.user)
            
        } catch {
            authState = .error(error as? AuthenticationError ?? .unknown(error.localizedDescription))
            throw error
        }
    }
    
    func signInAsGuest() async throws {
        do {
            authState = .loading
            
            let deviceId = await getDeviceIdentifier()
            let authResponse = try await authenticateAsGuest(deviceId: deviceId)
            
            try await saveAuthenticationData(authResponse)
            
            currentUser = authResponse.user
            authState = .authenticated(authResponse.user)
            
        } catch {
            authState = .error(error as? AuthenticationError ?? .unknown(error.localizedDescription))
            throw error
        }
    }
    
    func signOut() async {
        do {
            // Sign out from Google
            GIDSignIn.sharedInstance.signOut()
            
            // Call backend logout if we have a token
            if let accessTokenData = try? keychainService.get(accessTokenKey),
               let accessToken = String(data: accessTokenData, encoding: .utf8) {
                try? await logoutFromBackend(accessToken: accessToken)
            }
            
            // Clear stored data
            try keychainService.delete(accessTokenKey)
            try keychainService.delete(refreshTokenKey)
            try keychainService.delete(userDataKey)
            
            currentUser = nil
            authState = .unauthenticated
            
        } catch {
            // Even if there's an error, clear local state
            currentUser = nil
            authState = .unauthenticated
        }
    }
    
    func refreshTokenIfNeeded() async throws {
        guard let refreshTokenData = try? keychainService.get(refreshTokenKey),
              let refreshToken = String(data: refreshTokenData, encoding: .utf8) else {
            throw AuthenticationError.tokenExpired
        }
        
        do {
            let authResponse = try await refreshAuthToken(refreshToken: refreshToken)
            try await saveAuthenticationData(authResponse)
            
            currentUser = authResponse.user
            authState = .authenticated(authResponse.user)
            
        } catch {
            // If refresh fails, sign out
            await signOut()
            throw AuthenticationError.tokenExpired
        }
    }
    
    nonisolated func getCurrentAccessToken() -> String? {
        guard let accessTokenData = try? keychainService.get(accessTokenKey),
              let accessToken = String(data: accessTokenData, encoding: .utf8) else {
            return nil
        }
        return accessToken
    }
    
    // MARK: - Private Methods
    
    private func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("Warning: Could not find Google configuration")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
    
    private func checkExistingAuthentication() async {
        do {
            guard let accessTokenData = try? keychainService.get(accessTokenKey),
                  let accessToken = String(data: accessTokenData, encoding: .utf8),
                  let userData = try? keychainService.get(userDataKey),
                  let user = try? JSONDecoder().decode(User.self, from: userData) else {
                authState = .unauthenticated
                return
            }
            
            // Verify token with backend
            if try await verifyToken(accessToken: accessToken) {
                currentUser = user
                authState = .authenticated(user)
            } else {
                // Try to refresh token
                try await refreshTokenIfNeeded()
            }
            
        } catch {
            authState = .unauthenticated
        }
    }
    
    private func authenticateWithBackend(
        idToken: String,
        name: String?,
        email: String?,
        avatarUrl: String?
    ) async throws -> AuthResponse {
        struct RequestBody: Encodable {
            let idToken: String
            let name: String?
            let email: String?
            let avatarUrl: String?

            enum CodingKeys: String, CodingKey {
                case idToken = "id_token"
                case name
                case email
                case avatarUrl = "avatar_url"
            }
        }
        
        let body = RequestBody(idToken: idToken, name: name, email: email, avatarUrl: avatarUrl)
        
        return try await withCheckedThrowingContinuation { continuation in
            let cancellable = networkManager.post(
                endpoint: "/auth/google/login",
                body: body,
                responseType: AuthResponse.self
            )
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        continuation.resume(throwing: AuthenticationError.networkError)
                    case .finished:
                        break
                    }
                },
                receiveValue: { response in
                    continuation.resume(returning: response)
                }
            )
            self.cancellables.insert(cancellable)
        }
    }
    
    private func authenticateAsGuest(deviceId: String) async throws -> AuthResponse {
        struct RequestBody: Encodable {
            let deviceId: String
            let name: String
            
            enum CodingKeys: String, CodingKey {
                case deviceId = "device_id"
                case name
            }
        }
        
        let body = RequestBody(deviceId: deviceId, name: "Guest User")
        
        return try await withCheckedThrowingContinuation { continuation in
            let cancellable = networkManager.post(
                endpoint: "/auth/guest/login",
                body: body,
                responseType: AuthResponse.self
            )
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        continuation.resume(throwing: AuthenticationError.networkError)
                    case .finished:
                        break
                    }
                },
                receiveValue: { response in
                    continuation.resume(returning: response)
                }
            )
            self.cancellables.insert(cancellable)
        }
    }
    
    private func refreshAuthToken(refreshToken: String) async throws -> AuthResponse {
        struct RequestBody: Encodable {
            let refreshToken: String
            
            enum CodingKeys: String, CodingKey {
                case refreshToken = "refresh_token"
            }
        }
        
        let body = RequestBody(refreshToken: refreshToken)
        
        return try await withCheckedThrowingContinuation { continuation in
            let cancellable = networkManager.post(
                endpoint: "/auth/refresh",
                body: body,
                responseType: AuthResponse.self
            )
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        continuation.resume(throwing: AuthenticationError.networkError)
                    case .finished:
                        break
                    }
                },
                receiveValue: { response in
                    continuation.resume(returning: response)
                }
            )
            self.cancellables.insert(cancellable)
        }
    }
    
    private func verifyToken(accessToken: String) async throws -> Bool {
        struct Parameters: Encodable {
            // No parameters needed here
        }
        
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let cancellable = networkManager.get(
                    endpoint: "/auth/me",
                    responseType: EmptyResponse.self
                )
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error):
                            continuation.resume(returning: false)
                        case .finished:
                            break
                        }
                    },
                    receiveValue: { _ in
                        continuation.resume(returning: true)
                    }
                )
                self.cancellables.insert(cancellable)
            }
        } catch {
            return false
        }
    }
    
    private func logoutFromBackend(accessToken: String) async throws {
        struct Headers: Encodable {
            let authorization: String
            
            enum CodingKeys: String, CodingKey {
                case authorization = "Authorization"
            }
        }
        // Since headers are removed, assume networkManager.delete internally adds auth using token or other means.
        // But per instructions, remove headers entirely, so just call .delete with responseType.

        // If authorization header is required, it should be handled inside networkManager using stored tokens.
        // So just call delete without headers.
        
        try await withCheckedThrowingContinuation { continuation in
            let cancellable = networkManager.delete(
                endpoint: "/auth/logout",
                responseType: EmptyResponse.self
            )
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        continuation.resume(throwing: AuthenticationError.networkError)
                    case .finished:
                        continuation.resume(returning: ())
                    }
                },
                receiveValue: { _ in
                    continuation.resume(returning: ())
                }
            )
            self.cancellables.insert(cancellable)
        }
    }
    
    private func saveAuthenticationData(_ authResponse: AuthResponse) async throws {
        try keychainService.set(authResponse.accessToken, forKey: accessTokenKey)
        try keychainService.set(authResponse.refreshToken, forKey: refreshTokenKey)
        
        let userData = try JSONEncoder().encode(authResponse.user)
        try keychainService.set(userData, forKey: userDataKey)
    }
    
    private func getRootViewController() async -> UIViewController? {
        return await UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first?.rootViewController
    }
    
    private func getDeviceIdentifier() async -> String {
        // Use device identifier or create a UUID
        if let deviceIdData = try? keychainService.get("device_id"),
           let deviceId = String(data: deviceIdData, encoding: .utf8) {
            return deviceId
        } else {
            let deviceId = UUID().uuidString
            try? keychainService.set(deviceId, forKey: "device_id")
            return deviceId
        }
    }
}

// MARK: - Keychain Service
class KeychainService {
    func set(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthenticationError.keychainError
        }
    }
    
    func set(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw AuthenticationError.keychainError
        }
        try set(data, forKey: key)
    }
    
    func get(_ key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            throw AuthenticationError.keychainError
        }
        
        return data
    }
    
    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthenticationError.keychainError
        }
    }
}
