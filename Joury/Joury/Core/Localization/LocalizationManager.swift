//
//  LocalizationManager.swift
//  Joury
//
//  Localization management system for Joury iOS app
//

import Foundation
import SwiftUI
import Combine

// MARK: - App Reloader

class AppReloader: ObservableObject {
    static let shared = AppReloader()
    @Published var reloadTrigger = UUID()
    
    private init() {}
    
    func reload() {
        DispatchQueue.main.async {
            self.reloadTrigger = UUID()
        }
    }
}

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
        let localizationManager = LocalizationManager()
        switch self {
        case .traditionalChinese:
            return localizationManager.string(for: "language.zh_tw")
        case .english:
            return localizationManager.string(for: "language.en")
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

// MARK: - Type Aliases
typealias SupportedLanguage = Language

// MARK: - Localization Manager

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: Language = .system
    
    private var bundle: Bundle = Bundle.main
    private let appReloader = AppReloader.shared
    
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
        guard currentLanguage != language else { return }
        
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: AppConfig.UserDefaultsKeys.preferredLanguage)
        updateBundle()
        
        // Set the app language in UserDefaults for the system to pick up
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Force immediate UI update for the current language change
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        // Trigger app reload for complete language change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.appReloader.reload()
        }
    }
    
    private func updateBundle() {
        // Find the bundle for the selected language
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to main bundle if language bundle not found
            self.bundle = Bundle.main
            return
        }
        
        self.bundle = bundle
    }
    
    func string(for key: String, comment: String = "") -> String {
        // Use the language-specific bundle to load localized strings
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: comment)
        
        // If the localized string is the same as the key, it means translation wasn't found
        // Fall back to main bundle (typically English)
        if localizedString == key {
            return NSLocalizedString(key, bundle: Bundle.main, comment: comment)
        }
        
        return localizedString
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
        static let welcomeSubtitle = "auth.welcome_subtitle"
        static let privacyNotice = "auth.privacy_notice"
        static let signInRequired = "auth.sign_in_required"
        static let signInRequiredMessage = "auth.sign_in_required_message"
        static let guest = "auth.guest"
        static let guestEmail = "auth.guest_email"
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
        static let quickActionDayQuestion = "journal.quick_action_day_question"
        static let quickActionGratitude = "journal.quick_action_gratitude"
        static let quickActionMind = "journal.quick_action_mind"
        static let quickActionGoals = "journal.quick_action_goals"
        static let quickActionDayResponse = "journal.quick_action_day_response"
        static let quickActionGratitudeResponse = "journal.quick_action_gratitude_response"
        static let quickActionMindResponse = "journal.quick_action_mind_response"
        static let quickActionGoalsResponse = "journal.quick_action_goals_response"
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
        static let overview = "analytics.overview"
        static let journalEntries = "analytics.journal_entries"
        static let avgMood = "analytics.avg_mood"
        static let habitsCompleted = "analytics.habits_completed"
        static let focusMinutes = "analytics.focus_minutes"
        static let moodTrends = "analytics.mood_trends"
        static let seeDetails = "analytics.see_details"
        static let habitsPerformance = "analytics.habits_performance"
        static let journalInsights = "analytics.journal_insights"
        static let topKeywords = "analytics.top_keywords"
        static let emotionalInsights = "analytics.emotional_insights"
        static let week = "analytics.week"
        static let month = "analytics.month"
        static let quarter = "analytics.quarter"
    }
    
    // MARK: - Profile
    struct Profile {
        static let profile = "profile.profile"
        static let myProfile = "profile.my_profile"
        static let settings = "profile.settings"
        static let about = "profile.about"
        static let journalEntries = "profile.journal_entries"
        static let currentStreak = "profile.current_streak"
        static let completedHabits = "profile.completed_habits"
        static let rateApp = "profile.rate_app"
        static let rateAppSubtitle = "profile.rate_app_subtitle"
        static let feedback = "profile.feedback"
        static let feedbackSubtitle = "profile.feedback_subtitle"
        static let privacyPolicy = "profile.privacy_policy"
        static let termsOfService = "profile.terms_of_service"
        static let editProfile = "profile.edit_profile"
        static let name = "profile.name"
        static let email = "profile.email"
        static let avatar = "profile.avatar"
        static let preferences = "profile.preferences"
        static let notifications = "profile.notifications"
        static let privacy = "profile.privacy"
        static let version = "profile.version"
        static let support = "profile.support"
    }
    
    // MARK: - Settings
    struct Settings {
        static let settings = "settings.settings"
        static let title = "settings.title"
        static let welcome = "settings.welcome"
        static let subtitle = "settings.subtitle"
        static let appearance = "settings.appearance"
        static let theme = "settings.theme"
        static let accentColor = "settings.accent_color"
        static let language = "settings.language"
        static let notifications = "settings.notifications"
        static let enableNotifications = "settings.enable_notifications"
        static let dailyReminders = "settings.daily_reminders"
        static let morningReminders = "settings.morning_reminders"
        static let startDayReflection = "settings.start_day_reflection"
        static let eveningReminders = "settings.evening_reminders"
        static let endDayReflection = "settings.end_day_reflection"
        static let privacySecurity = "settings.privacy_security"
        static let appLock = "settings.app_lock"
        static let requireAuthentication = "settings.require_authentication"
        static let privacyPolicy = "settings.privacy_policy"
        static let howWeProtect = "settings.how_we_protect"
        static let dataManagement = "settings.data_management"
        static let exportData = "settings.export_data"
        static let downloadJournal = "settings.download_journal"
        static let clearCache = "settings.clear_cache"
        static let freeStorage = "settings.free_storage"
        static let about = "settings.about"
        static let version = "settings.version"
        static let feedback = "settings.feedback"
        static let helpImprove = "settings.help_improve"
        static let termsOfService = "settings.terms_of_service"
        static let legalInformation = "settings.legal_information"
        static let privacy = "settings.privacy"
        static let security = "settings.security"
        static let dataExport = "settings.data_export"
        static let deleteAccount = "settings.delete_account"
        static let restartRequired = "settings.restart_required"
        static let restartMessage = "settings.restart_message"
        static let languageChanged = "settings.language_changed"
        static let languageChangeMessage = "settings.language_change_message"
    }
    
    // MARK: - Common
    struct Common {
        static let back = "common.back"
        static let ok = "common.ok"
        static let cancel = "common.cancel"
        static let save = "common.save"
        static let delete = "common.delete"
        static let edit = "common.edit"
        static let done = "common.done"
        static let next = "common.next"
        static let skip = "common.skip"
        static let retry = "common.retry"
        static let loading = "common.loading"
        static let error = "common.error"
        static let success = "common.success"
        static let warning = "common.warning"
        static let info = "common.info"
        static let signIn = "common.sign_in"
        static let signOut = "common.sign_out"
    }
    
    // MARK: - Theme
    struct Theme {
        static let light = "theme.light"
        static let dark = "theme.dark"
        static let auto = "theme.auto"
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
        static let googleAuthFailed = "errors.google_auth_failed"
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
        let localizationManager = LocalizationManager()
        return localizationManager.string(for: self)
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