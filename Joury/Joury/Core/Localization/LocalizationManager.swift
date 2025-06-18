//
//  LocalizationManager.swift
//  Joury
//
//  Localization management system for Joury iOS app
//

import Foundation
import SwiftUI
import Combine

// MARK: - Supported Languages

enum Language: String, CaseIterable {
    case traditionalChinese = "zh-TW"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .traditionalChinese:
            return "繁體中文"
        case .english:
            return "English"
        }
    }
    
    var localizedDisplayName: String {
        switch self {
        case .traditionalChinese:
            return NSLocalizedString("language.zh_tw", comment: "Traditional Chinese")
        case .english:
            return NSLocalizedString("language.en", comment: "English")
        }
    }
    
    var code: String {
        return self.rawValue
    }
    
    static var system: Language {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        if preferredLanguage.hasPrefix("zh-TW") || preferredLanguage.hasPrefix("zh-HK") {
            return .traditionalChinese
        }
        return .english
    }
}

// MARK: - Localization Manager

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: Language = .system
    
    private var bundle: Bundle = Bundle.main
    
    init() {
        loadLanguagePreference()
        updateBundle()
    }
    
    private func loadLanguagePreference() {
        if let savedLanguage = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.preferredLanguage),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            currentLanguage = Language.system
        }
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: AppConfig.UserDefaultsKeys.preferredLanguage)
        updateBundle()
    }
    
    private func updateBundle() {
        // String Catalogs automatically handle bundle resolution
        // No need for manual bundle switching with String Catalogs
        self.bundle = Bundle.main
    }
    
    func string(for key: String, comment: String = "") -> String {
        // With String Catalogs, use the main bundle directly
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
    
    func string(for key: String, arguments: CVarArg...) -> String {
        let format = string(for: key)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - Localization Keys

struct LocalizationKeys {
    
    // MARK: - General
    struct General {
        static let appName = "general.app_name"
        static let ok = "general.ok"
        static let cancel = "general.cancel"
        static let save = "general.save"
        static let delete = "general.delete"
        static let edit = "general.edit"
        static let done = "general.done"
        static let back = "general.back"
        static let next = "general.next"
        static let skip = "general.skip"
        static let retry = "general.retry"
        static let loading = "general.loading"
        static let error = "general.error"
        static let success = "general.success"
        static let warning = "general.warning"
        static let info = "general.info"
    }
    
    // MARK: - Authentication
    struct Auth {
        static let signIn = "auth.sign_in"
        static let signOut = "auth.sign_out"
        static let signInWithGoogle = "auth.sign_in_with_google"
        static let continueAsGuest = "auth.continue_as_guest"
        static let welcome = "auth.welcome"
        static let welcomeMessage = "auth.welcome_message"
        static let signInRequired = "auth.sign_in_required"
        static let signInRequiredMessage = "auth.sign_in_required_message"
    }
    
    // MARK: - Journal
    struct Journal {
        static let journal = "journal.journal"
        static let todayJournal = "journal.today"
        static let writeJournal = "journal.write"
        static let aiGreeting = "journal.ai_greeting"
        static let aiQuestion = "journal.ai_question"
        static let yourThoughts = "journal.your_thoughts"
        static let addPhoto = "journal.add_photo"
        static let addVoice = "journal.add_voice"
        static let moodToday = "journal.mood_today"
        static let reflectionPrompt = "journal.reflection_prompt"
        static let entryCreated = "journal.entry_created"
        static let entryUpdated = "journal.entry_updated"
        static let entryDeleted = "journal.entry_deleted"
    }
    
    // MARK: - Habits
    struct Habits {
        static let habits = "habits.habits"
        static let myHabits = "habits.my_habits"
        static let addHabit = "habits.add_habit"
        static let editHabit = "habits.edit_habit"
        static let habitName = "habits.habit_name"
        static let habitDescription = "habits.habit_description"
        static let habitFrequency = "habits.habit_frequency"
        static let habitTarget = "habits.habit_target"
        static let daily = "habits.daily"
        static let weekly = "habits.weekly"
        static let monthly = "habits.monthly"
        static let completed = "habits.completed"
        static let incomplete = "habits.incomplete"
        static let streak = "habits.streak"
        static let habitCompleted = "habits.habit_completed"
        static let aiSuggestion = "habits.ai_suggestion"
    }
    
    // MARK: - Focus
    struct Focus {
        static let focus = "focus.focus"
        static let focusMode = "focus.focus_mode"
        static let pomodoroTimer = "focus.pomodoro_timer"
        static let startFocus = "focus.start_focus"
        static let stopFocus = "focus.stop_focus"
        static let pauseFocus = "focus.pause_focus"
        static let resumeFocus = "focus.resume_focus"
        static let focusComplete = "focus.focus_complete"
        static let breakTime = "focus.break_time"
        static let joinRoom = "focus.join_room"
        static let createRoom = "focus.create_room"
        static let roomName = "focus.room_name"
        static let participants = "focus.participants"
        static let focusStats = "focus.focus_stats"
    }
    
    // MARK: - Analytics
    struct Analytics {
        static let analytics = "analytics.analytics"
        static let weeklyReport = "analytics.weekly_report"
        static let monthlyReport = "analytics.monthly_report"
        static let moodTrend = "analytics.mood_trend"
        static let habitProgress = "analytics.habit_progress"
        static let focusTime = "analytics.focus_time"
        static let insights = "analytics.insights"
        static let exportReport = "analytics.export_report"
        static let shareReport = "analytics.share_report"
    }
    
    // MARK: - Profile
    struct Profile {
        static let profile = "profile.profile"
        static let myProfile = "profile.my_profile"
        static let editProfile = "profile.edit_profile"
        static let name = "profile.name"
        static let email = "profile.email"
        static let avatar = "profile.avatar"
        static let preferences = "profile.preferences"
        static let notifications = "profile.notifications"
        static let privacy = "profile.privacy"
        static let about = "profile.about"
        static let version = "profile.version"
        static let support = "profile.support"
        static let feedback = "profile.feedback"
    }
    
    // MARK: - Settings
    struct Settings {
        static let settings = "settings.settings"
        static let language = "settings.language"
        static let theme = "settings.theme"
        static let notifications = "settings.notifications"
        static let privacy = "settings.privacy"
        static let security = "settings.security"
        static let dataExport = "settings.data_export"
        static let deleteAccount = "settings.delete_account"
    }
    
    // MARK: - Errors
    struct Errors {
        static let networkError = "errors.network_error"
        static let serverError = "errors.server_error"
        static let validationError = "errors.validation_error"
        static let unknownError = "errors.unknown_error"
        static let permissionDenied = "errors.permission_denied"
        static let fileNotFound = "errors.file_not_found"
        static let authenticationFailed = "errors.authentication_failed"
    }
    
    // MARK: - Notifications
    struct Notifications {
        static let dailyReflection = "notifications.daily_reflection"
        static let habitReminder = "notifications.habit_reminder"
        static let focusSession = "notifications.focus_session"
        static let weeklyReport = "notifications.weekly_report"
        static let notificationPermission = "notifications.permission"
        static let notificationSettings = "notifications.settings"
    }
}

// MARK: - String Extension for Localization

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    func localized(bundle: Bundle) -> String {
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}

// MARK: - Environment Key

struct LocalizationKey: EnvironmentKey {
    static let defaultValue = LocalizationManager()
}

extension EnvironmentValues {
    var localization: LocalizationManager {
        get { self[LocalizationKey.self] }
        set { self[LocalizationKey.self] = newValue }
    }
} 