//
//  SettingsComponents.swift
//  Joury
//
//  Reusable components for Settings interface
//

import SwiftUI

// MARK: - NotificationToggleRow

struct NotificationToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(themeManager.colors.warning.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeManager.colors.warning)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(themeManager.colors.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(themeManager.colors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(themeManager.colors.primary)
        }
        .padding(16)
    }
}

// MARK: - ActionRow

struct ActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(iconColor)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeManager.colors.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(themeManager.colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(themeManager.colors.textSecondary)
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - InfoRow

struct InfoRow: View {
    let title: String
    let value: String
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(themeManager.colors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(themeManager.colors.textSecondary)
        }
        .padding(16)
    }
}

// MARK: - Language Extensions

extension Language {
    var flag: String {
        switch self {
        case .english:
            return "🇺🇸"
        case .traditionalChinese:
            return "🇹🇼"
        }
    }
    
    func nativeName(using localizationManager: LocalizationManager) -> String {
        switch self {
        case .english:
            return localizationManager.string(for: "language.en")
        case .traditionalChinese:
            return localizationManager.string(for: "language.zh_tw")
        }
    }
}

// MARK: - ThemeMode Extensions

extension ThemeMode {
    var icon: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .auto:
            return "circle.lefthalf.filled"
        }
    }
    
    func settingsDisplayName(using localizationManager: LocalizationManager) -> String {
        switch self {
        case .light:
            return localizationManager.string(for: "theme.light")
        case .dark:
            return localizationManager.string(for: "theme.dark")
        case .auto:
            return localizationManager.string(for: "theme.auto")
        }
    }
}

// MARK: - Haptic Feedback Helper

func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let impactFeedback = UIImpactFeedbackGenerator(style: style)
    impactFeedback.impactOccurred()
} 