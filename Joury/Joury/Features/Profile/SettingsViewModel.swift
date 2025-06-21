//
//  SettingsViewModel.swift
//  Joury
//
//  ViewModel for Settings view
//

import SwiftUI
import Combine
import UserNotifications
import LocalAuthentication

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Notification Settings
    @Published var notificationsEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notifications_enabled")
            if notificationsEnabled {
                requestNotificationPermission()
            }
        }
    }
    
    @Published var morningReminders: Bool = false {
        didSet {
            UserDefaults.standard.set(morningReminders, forKey: "morning_reminders")
            scheduleMorningReminders()
        }
    }
    
    @Published var eveningReminders: Bool = false {
        didSet {
            UserDefaults.standard.set(eveningReminders, forKey: "evening_reminders")
            scheduleEveningReminders()
        }
    }
    
    @Published var habitReminders: Bool = false {
        didSet {
            UserDefaults.standard.set(habitReminders, forKey: "habit_reminders")
            scheduleHabitReminders()
        }
    }
    
    // MARK: - Privacy Settings
    @Published var biometricAuthEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(biometricAuthEnabled, forKey: "biometric_auth_enabled")
            if biometricAuthEnabled {
                setupBiometricAuth()
            }
        }
    }
    
    @Published var aiAnalysisEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(aiAnalysisEnabled, forKey: "ai_analysis_enabled")
        }
    }
    
    // MARK: - Data Settings
    @Published var cloudSyncEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(cloudSyncEnabled, forKey: "cloud_sync_enabled")
            if cloudSyncEnabled {
                setupCloudSync()
            }
        }
    }
    
    // MARK: - Alert States
    @Published var showingDeleteAlert: Bool = false
    
    // MARK: - App Information
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadSettings()
    }
    
    // MARK: - Settings Management
    func loadSettings() {
        // Load notification settings
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
        morningReminders = UserDefaults.standard.bool(forKey: "morning_reminders")
        eveningReminders = UserDefaults.standard.bool(forKey: "evening_reminders")
        habitReminders = UserDefaults.standard.bool(forKey: "habit_reminders")
        
        // Load privacy settings
        biometricAuthEnabled = UserDefaults.standard.bool(forKey: "biometric_auth_enabled")
        aiAnalysisEnabled = UserDefaults.standard.object(forKey: "ai_analysis_enabled") as? Bool ?? true
        
        // Load data settings
        cloudSyncEnabled = UserDefaults.standard.bool(forKey: "cloud_sync_enabled")
        
        // Check current notification authorization status
        checkNotificationStatus()
    }
    
    // MARK: - Notification Management
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self.notificationsEnabled = true
                case .denied, .notDetermined:
                    self.notificationsEnabled = false
                @unknown default:
                    self.notificationsEnabled = false
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error)")
                    self.notificationsEnabled = false
                } else {
                    self.notificationsEnabled = granted
                }
            }
        }
    }
    
    private func scheduleMorningReminders() {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing morning reminders
        center.removePendingNotificationRequests(withIdentifiers: ["morning_reminder"])
        
        guard morningReminders && notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "早安！新的一天開始了"
        content.body = "花幾分鐘時間設定今天的意圖，讓這一天更有意義。"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling morning reminder: \(error)")
            }
        }
    }
    
    private func scheduleEveningReminders() {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing evening reminders
        center.removePendingNotificationRequests(withIdentifiers: ["evening_reminder"])
        
        guard eveningReminders && notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "反思時間"
        content.body = "今天過得如何？記錄下您的想法和感受。"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "evening_reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling evening reminder: \(error)")
            }
        }
    }
    
    private func scheduleHabitReminders() {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing habit reminders
        center.removePendingNotificationRequests(withIdentifiers: ["habit_reminder"])
        
        guard habitReminders && notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "習慣提醒"
        content.body = "別忘了完成今天的習慣目標！"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "habit_reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling habit reminder: \(error)")
            }
        }
    }
    
    // MARK: - Biometric Authentication
    private func setupBiometricAuth() {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            biometricAuthEnabled = false
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: NSLocalizedString("settings.biometric_auth_reason", comment: "")) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Biometric authentication error: \(error)")
                    self.biometricAuthEnabled = false
                } else {
                    self.biometricAuthEnabled = success
                }
            }
        }
    }
    
    // MARK: - Cloud Sync
    private func setupCloudSync() {
        // TODO: Implement iCloud sync setup
        // This would typically involve:
        // 1. Checking iCloud availability
        // 2. Setting up CloudKit containers
        // 3. Syncing local data to cloud
        print("Setting up cloud sync...")
    }
    
    // MARK: - Data Management
    func exportData() {
        // TODO: Implement data export functionality
        // This would typically:
        // 1. Gather all user data (journal entries, habits, settings)
        // 2. Create a JSON or CSV file
        // 3. Present a share sheet
        print("Exporting user data...")
        
        // For now, create a simple mock export
        let exportData = [
            "user": [
                "journal_entries": 42,
                "habits": 12,
                "export_date": Date().ISO8601Format()
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            
            // Create temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("joury_export.json")
            try jsonData.write(to: tempURL)
            
            // Present share sheet
            let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
               let rootViewController = keyWindow.rootViewController {
                rootViewController.present(activityViewController, animated: true)
            }
        } catch {
            print("Error exporting data: \(error)")
        }
    }
    
    func deleteAllData() {
        // Clear all UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // Clear notification schedules
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // TODO: Clear Core Data or other persistent storage
        // TODO: Clear Keychain entries if any
        
        print("All user data deleted")
        
        // Reload settings to reflect the cleared state
        loadSettings()
    }
}
