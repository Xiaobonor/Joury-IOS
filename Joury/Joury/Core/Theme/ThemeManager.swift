//
//  ThemeManager.swift
//  Joury
//
//  Theme management system for Joury iOS app
//

import SwiftUI
import Combine

// MARK: - Theme Types

enum ThemeMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .light:
            return NSLocalizedString("theme.light", comment: "Light theme")
        case .dark:
            return NSLocalizedString("theme.dark", comment: "Dark theme")
        case .auto:
            return NSLocalizedString("theme.auto", comment: "Auto theme")
        }
    }
}

// MARK: - Color Scheme

struct JouryColors {
    
    // Primary Colors
    let primary: Color
    let primaryVariant: Color
    let secondary: Color
    let secondaryVariant: Color
    
    // Background Colors
    let background: Color
    let surface: Color
    let cardBackground: Color
    
    // Text Colors
    let onPrimary: Color
    let onSecondary: Color
    let onBackground: Color
    let onSurface: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    
    // Status Colors
    let success: Color
    let warning: Color
    let error: Color
    let info: Color
    
    // Interactive Colors
    let accent: Color
    let shadow: Color
    let divider: Color
    let disabled: Color
    
    // AI Chat Colors
    let aiMessageBackground: Color
    let userMessageBackground: Color
    
    // Habit Colors
    let habitCompleted: Color
    let habitIncomplete: Color
    let habitStreak: Color
    
    // Mood Colors
    let moodVeryHappy: Color
    let moodHappy: Color
    let moodNeutral: Color
    let moodSad: Color
    let moodVerySad: Color
}

// MARK: - Light Theme

extension JouryColors {
    static let light = JouryColors(
        // Primary Colors
        primary: Color(hex: "4ECDC4"),
        primaryVariant: Color(hex: "26A69A"),
        secondary: Color(hex: "FFE66D"),
        secondaryVariant: Color(hex: "FFD54F"),
        
        // Background Colors
        background: Color(hex: "FAFAFA"),
        surface: Color.white,
        cardBackground: Color.white,
        
        // Text Colors
        onPrimary: Color.white,
        onSecondary: Color.black,
        onBackground: Color(hex: "1C1C1E"),
        onSurface: Color(hex: "1C1C1E"),
        textPrimary: Color(hex: "1C1C1E"),
        textSecondary: Color(hex: "3C3C43").opacity(0.6),
        textTertiary: Color(hex: "3C3C43").opacity(0.3),
        
        // Status Colors
        success: Color(hex: "34C759"),
        warning: Color(hex: "FF9500"),
        error: Color(hex: "FF3B30"),
        info: Color(hex: "007AFF"),
        
        // Interactive Colors
        accent: Color(hex: "FF6B6B"),
        shadow: Color.black.opacity(0.05),
        divider: Color(hex: "C6C6C8"),
        disabled: Color(hex: "C6C6C8").opacity(0.5),
        
        // AI Chat Colors
        aiMessageBackground: Color(hex: "F2F2F7"),
        userMessageBackground: Color(hex: "4ECDC4"),
        
        // Habit Colors
        habitCompleted: Color(hex: "34C759"),
        habitIncomplete: Color(hex: "C6C6C8"),
        habitStreak: Color(hex: "FF9500"),
        
        // Mood Colors
        moodVeryHappy: Color(hex: "34C759"),
        moodHappy: Color(hex: "32D74B"),
        moodNeutral: Color(hex: "FFE66D"),
        moodSad: Color(hex: "FF9500"),
        moodVerySad: Color(hex: "FF3B30")
    )
}

// MARK: - Dark Theme

extension JouryColors {
    static let dark = JouryColors(
        // Primary Colors
        primary: Color(hex: "4ECDC4"),
        primaryVariant: Color(hex: "26A69A"),
        secondary: Color(hex: "FFE66D"),
        secondaryVariant: Color(hex: "FFD54F"),
        
        // Background Colors
        background: Color(hex: "000000"),
        surface: Color(hex: "1C1C1E"),
        cardBackground: Color(hex: "2C2C2E"),
        
        // Text Colors
        onPrimary: Color.white,
        onSecondary: Color.black,
        onBackground: Color.white,
        onSurface: Color.white,
        textPrimary: Color.white,
        textSecondary: Color(hex: "EBEBF5").opacity(0.6),
        textTertiary: Color(hex: "EBEBF5").opacity(0.3),
        
        // Status Colors
        success: Color(hex: "30D158"),
        warning: Color(hex: "FF9F0A"),
        error: Color(hex: "FF453A"),
        info: Color(hex: "0A84FF"),
        
        // Interactive Colors
        accent: Color(hex: "FF6B6B"),
        shadow: Color.black.opacity(0.3),
        divider: Color(hex: "38383A"),
        disabled: Color(hex: "38383A").opacity(0.5),
        
        // AI Chat Colors
        aiMessageBackground: Color(hex: "2C2C2E"),
        userMessageBackground: Color(hex: "4ECDC4"),
        
        // Habit Colors
        habitCompleted: Color(hex: "30D158"),
        habitIncomplete: Color(hex: "38383A"),
        habitStreak: Color(hex: "FF9F0A"),
        
        // Mood Colors
        moodVeryHappy: Color(hex: "30D158"),
        moodHappy: Color(hex: "32D74B"),
        moodNeutral: Color(hex: "FFE66D"),
        moodSad: Color(hex: "FF9F0A"),
        moodVerySad: Color(hex: "FF453A")
    )
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @Published var currentTheme: ThemeMode = .auto
    @Published var isDarkMode: Bool = false
    @Published var colors: JouryColors = .light
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadThemePreference()
        setupThemeObservation()
    }
    
    private func loadThemePreference() {
        let savedTheme = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.userTheme) ?? ThemeMode.auto.rawValue
        currentTheme = ThemeMode(rawValue: savedTheme) ?? .auto
        updateColors()
    }
    
    private func setupThemeObservation() {
        // Observe system color scheme changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateColors()
            }
            .store(in: &cancellables)
    }
    
    func setTheme(_ theme: ThemeMode) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: AppConfig.UserDefaultsKeys.userTheme)
        updateColors()
    }
    
    private func updateColors() {
        switch currentTheme {
        case .light:
            isDarkMode = false
            colors = .light
        case .dark:
            isDarkMode = true
            colors = .dark
        case .auto:
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
            colors = isDarkMode ? .dark : .light
        }
    }
    
    // MARK: - Color Utilities
    
    func moodColor(for score: Double) -> Color {
        switch score {
        case 0.0..<2.0:
            return colors.moodVerySad
        case 2.0..<4.0:
            return colors.moodSad
        case 4.0..<6.0:
            return colors.moodNeutral
        case 6.0..<8.0:
            return colors.moodHappy
        case 8.0...10.0:
            return colors.moodVeryHappy
        default:
            return colors.moodNeutral
        }
    }
    
    func habitColor(completed: Bool, streak: Int = 0) -> Color {
        if completed {
            return streak > 7 ? colors.habitStreak : colors.habitCompleted
        } else {
            return colors.habitIncomplete
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Environment Key

struct ThemeKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var theme: ThemeManager {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
} 