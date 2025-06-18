//
//  AppConfig.swift
//  Joury
//
//  Core configuration for Joury iOS app
//

import Foundation

struct AppConfig {
    // MARK: - API Configuration
    
    #if DEBUG
    static let baseURL = "http://localhost:8000"
    static let apiVersion = "v1"
    #else
    static let baseURL = "https://api.joury.app"
    static let apiVersion = "v1"
    #endif
    
    static let apiBaseURL = "\(baseURL)/api/\(apiVersion)"
    
    // MARK: - Authentication
    
    static let googleClientId = "your-google-client-id" // Replace with actual client ID
    static let authRedirectURI = "com.joury.app://auth/callback"
    
    // MARK: - App Information
    
    static let appName = "Joury"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Feature Flags
    
    struct FeatureFlags {
        static let enableAIChat = true
        static let enableFocusRooms = true
        static let enableAnalytics = true
        static let enableGuestMode = true
        static let enableDarkMode = true
        static let enableCustomThemes = false // Will be enabled in later phases
    }
    
    // MARK: - Networking
    
    struct Network {
        static let requestTimeout: TimeInterval = 30.0
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 1.0
        static let cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData
    }
    
    // MARK: - User Defaults Keys
    
    struct UserDefaultsKeys {
        static let isFirstLaunch = "isFirstLaunch"
        static let userTheme = "userTheme"
        static let preferredLanguage = "preferredLanguage"
        static let lastSyncTimestamp = "lastSyncTimestamp"
        static let guestToken = "guestToken"
        static let authToken = "authToken"
        static let refreshToken = "refreshToken"
        static let userId = "userId"
        static let userEmail = "userEmail"
        static let userName = "userName"
        static let notificationSettings = "notificationSettings"
    }
    
    // MARK: - Keychain Keys
    
    struct KeychainKeys {
        static let authToken = "joury.auth.token"
        static let refreshToken = "joury.auth.refresh"
        static let guestToken = "joury.guest.token"
        static let biometricEnabled = "joury.biometric.enabled"
    }
    
    // MARK: - Notification Identifiers
    
    struct NotificationIdentifiers {
        static let dailyReflection = "daily_reflection"
        static let habitReminder = "habit_reminder"
        static let focusSession = "focus_session"
        static let weeklyReport = "weekly_report"
    }
    
    // MARK: - Debug Settings
    
    #if DEBUG
    struct Debug {
        static let enableNetworkLogging = true
        static let enableUITesting = true
        static let enableMockData = false
        static let skipOnboarding = false
    }
    #endif
} 