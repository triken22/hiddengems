import Foundation
import Security

/// Service for managing anonymous user identity
actor UserService {
    static let shared = UserService()
    
    private let keychainKey = "com.hiddengems.deviceId"
    private let userIdKey = "com.hiddengems.userId"
    
    private var cachedDeviceId: String?
    private var cachedUserId: String?
    
    private init() {}
    
    /// Get or create device ID (stored in Keychain for persistence across app deletions)
    func getDeviceId() -> String {
        if let cached = cachedDeviceId {
            return cached
        }
        
        // Try to get from Keychain
        if let existing = getFromKeychain(key: keychainKey) {
            cachedDeviceId = existing
            return existing
        }
        
        // Generate new device ID
        let newDeviceId = UUID().uuidString
        saveToKeychain(key: keychainKey, value: newDeviceId)
        cachedDeviceId = newDeviceId
        return newDeviceId
    }
    
    /// Get user ID (requires registration with backend)
    func getUserId() async -> String? {
        if let cached = cachedUserId {
            return cached
        }
        
        // Try to get from UserDefaults
        if let existing = UserDefaults.standard.string(forKey: userIdKey) {
            cachedUserId = existing
            return existing
        }
        
        return nil
    }
    
    /// Register user with backend and store user ID
    func registerUser(baseURL: String, syncToken: String) async throws -> String {
        let deviceId = getDeviceId()
        
        // Check if already registered
        if let existingUserId = await getUserId() {
            return existingUserId
        }
        
        // Register with backend
        guard let url = URL(string: "\(baseURL)/api/users/register") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(syncToken)", forHTTPHeaderField: "Authorization")
        
        let body = ["deviceId": deviceId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        struct UserResponse: Codable {
            let userId: String
            let deviceId: String
            let createdAt: String
        }
        
        let userResponse = try JSONDecoder().decode(UserResponse.self, from: data)
        
        // Store user ID
        UserDefaults.standard.set(userResponse.userId, forKey: userIdKey)
        cachedUserId = userResponse.userId
        
        return userResponse.userId
    }
    
    /// Clear user data (for testing or logout)
    func clearUserData() {
        // Remove from cache
        cachedUserId = nil
        
        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: userIdKey)
        
        // Note: We don't remove deviceId from Keychain as it should persist
    }
    
    // MARK: - Keychain Helpers
    
    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
}

