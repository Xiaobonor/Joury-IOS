//
//  SettingsView.swift
//  Joury
//
//  A warm, minimalist settings interface for the Joury app
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    // Animation state
    @State private var showContent = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header section with gentle welcome
                    headerSection
                    
                    // Main settings sections
                    settingsContent
                }
                .padding(.horizontal, 20)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
            .background(
                LinearGradient(
                    colors: [
                        themeManager.colors.background,
                        themeManager.colors.surface.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        hapticFeedback(.light)
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text(localizationManager.string(for: "common.back"))
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(themeManager.colors.primary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(localizationManager.string(for: "settings.title"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(themeManager.colors.textPrimary)
                }
            }
        }
        .onAppear {
            viewModel.loadSettings()
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Gentle greeting
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.string(for: "settings.welcome"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(themeManager.colors.textPrimary)
                    
                    Text(localizationManager.string(for: "settings.subtitle"))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(themeManager.colors.textSecondary)
                }
                
                Spacer()
                
                // Decorative icon
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.colors.primary, themeManager.colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "gear")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: themeManager.colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Settings Content
    
    private var settingsContent: some View {
        LazyVStack(spacing: 24) {
            // Appearance Section
            SettingsSection(
                title: localizationManager.string(for: "settings.appearance"),
                icon: "paintbrush.pointed.fill",
                iconColor: themeManager.colors.primary
            ) {
                VStack(spacing: 0) {
                    // Theme Selection
                    ThemeSelectionRow(currentTheme: themeManager.currentTheme) { theme in
                        hapticFeedback(.medium)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            themeManager.setTheme(theme)
                        }
                    }
                    
                    Divider()
                        .background(themeManager.colors.divider.opacity(0.5))
                        .padding(.leading, 16)
                    
                    // Color Accent Preview
                    ColorAccentRow()
                }
            }
            
            // Language Section
            SettingsSection(
                title: localizationManager.string(for: "settings.language"),
                icon: "globe",
                iconColor: themeManager.colors.secondary
            ) {
                VStack(spacing: 0) {
                    LanguageOptionRow(
                        language: .english,
                        isSelected: localizationManager.currentLanguage == .english
                    ) {
                        hapticFeedback(.light)
                        localizationManager.setLanguage(.english)
                    }
                    
                    Divider()
                        .background(themeManager.colors.divider.opacity(0.5))
                        .padding(.leading, 16)
                    
                    LanguageOptionRow(
                        language: .traditionalChinese,
                        isSelected: localizationManager.currentLanguage == .traditionalChinese
                    ) {
                        hapticFeedback(.light)
                        localizationManager.setLanguage(.traditionalChinese)
                    }
                }
            }
            
            // Notifications Section
            SettingsSection(
                title: localizationManager.string(for: "settings.notifications"),
                icon: "bell.fill",
                iconColor: themeManager.colors.warning
            ) {
                VStack(spacing: 0) {
                    NotificationToggleRow(
                        title: localizationManager.string(for: "settings.enable_notifications"),
                        subtitle: localizationManager.string(for: "settings.daily_reminders"),
                        icon: "bell.fill",
                        isOn: $viewModel.notificationsEnabled
                    )
                    
                    if viewModel.notificationsEnabled {
                        VStack(spacing: 0) {
                            Divider()
                                .background(themeManager.colors.divider.opacity(0.5))
                                .padding(.leading, 16)
                            
                            NotificationToggleRow(
                                title: localizationManager.string(for: "settings.morning_reminders"),
                                subtitle: localizationManager.string(for: "settings.start_day_reflection"),
                                icon: "sunrise.fill",
                                isOn: $viewModel.morningReminders
                            )
                            
                            Divider()
                                .background(themeManager.colors.divider.opacity(0.5))
                                .padding(.leading, 16)
                            
                            NotificationToggleRow(
                                title: localizationManager.string(for: "settings.evening_reminders"),
                                subtitle: localizationManager.string(for: "settings.end_day_reflection"),
                                icon: "moon.stars.fill",
                                isOn: $viewModel.eveningReminders
                            )
                        }
                        .animation(.easeInOut(duration: 0.3), value: viewModel.notificationsEnabled)
                    }
                }
            }
            
            // Privacy & Security Section
            SettingsSection(
                title: localizationManager.string(for: "settings.privacy_security"),
                icon: "lock.shield.fill",
                iconColor: themeManager.colors.error
            ) {
                VStack(spacing: 0) {
                    ActionRow(
                        title: localizationManager.string(for: "settings.app_lock"),
                        subtitle: localizationManager.string(for: "settings.require_authentication"),
                        icon: "faceid",
                        iconColor: themeManager.colors.primary
                    ) {
                        hapticFeedback(.light)
                        viewModel.biometricAuthEnabled.toggle()
                    }
                    
                    Divider()
                        .background(themeManager.colors.divider.opacity(0.5))
                        .padding(.leading, 16)
                    
                    ActionRow(
                        title: localizationManager.string(for: "settings.privacy_policy"),
                        subtitle: localizationManager.string(for: "settings.how_we_protect"),
                        icon: "doc.text.fill",
                        iconColor: themeManager.colors.secondary
                    ) {
                        hapticFeedback(.light)
                        // TODO: Implement privacy policy navigation
                    }
                }
            }
            
            // Data Management Section
            SettingsSection(
                title: localizationManager.string(for: "settings.data_management"),
                icon: "externaldrive.fill",
                iconColor: themeManager.colors.success
            ) {
                VStack(spacing: 0) {
                    ActionRow(
                        title: localizationManager.string(for: "settings.export_data"),
                        subtitle: localizationManager.string(for: "settings.download_journal"),
                        icon: "square.and.arrow.up.fill",
                        iconColor: themeManager.colors.primary
                    ) {
                        hapticFeedback(.light)
                        // TODO: Implement data export
                    }
                    
                    Divider()
                        .background(themeManager.colors.divider.opacity(0.5))
                        .padding(.leading, 16)
                    
                    ActionRow(
                        title: localizationManager.string(for: "settings.clear_cache"),
                        subtitle: localizationManager.string(for: "settings.free_storage"),
                        icon: "trash.fill",
                        iconColor: themeManager.colors.warning
                    ) {
                        hapticFeedback(.medium)
                        // TODO: Implement cache clearing
                    }
                }
            }
            
            // About Section
            SettingsSection(
                title: localizationManager.string(for: "settings.about"),
                icon: "info.circle.fill",
                iconColor: themeManager.colors.accent
            ) {
                VStack(spacing: 0) {
                    InfoRow(
                        title: localizationManager.string(for: "settings.version"),
                        value: viewModel.appVersion
                    )
                    
                    Divider()
                        .background(themeManager.colors.divider.opacity(0.5))
                        .padding(.leading, 16)
                    
                    ActionRow(
                        title: localizationManager.string(for: "settings.feedback"),
                        subtitle: localizationManager.string(for: "settings.help_improve"),
                        icon: "heart.fill",
                        iconColor: themeManager.colors.error
                    ) {
                        hapticFeedback(.light)
                        // TODO: Implement feedback sending
                    }
                    
                    Divider()
                        .background(themeManager.colors.divider.opacity(0.5))
                        .padding(.leading, 16)
                    
                    ActionRow(
                        title: localizationManager.string(for: "settings.terms_of_service"),
                        subtitle: localizationManager.string(for: "settings.legal_information"),
                        icon: "doc.text.fill",
                        iconColor: themeManager.colors.secondary
                    ) {
                        hapticFeedback(.light)
                        // TODO: Implement terms of service navigation
                    }
                }
            }
            
            // Bottom padding for comfortable scrolling
            Spacer()
                .frame(height: 40)
        }
    }
}

// MARK: - Custom Components

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(iconColor)
                    )
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(themeManager.colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Section content
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.colors.surface)
                    .shadow(
                        color: themeManager.colors.shadow.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
    }
}

struct ThemeSelectionRow: View {
    let currentTheme: ThemeMode
    let onThemeChanged: (ThemeMode) -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "paintbrush.pointed.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(themeManager.colors.primary)
                
                Text(localizationManager.string(for: "settings.theme"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(themeManager.colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Theme options
            HStack(spacing: 12) {
                ForEach([ThemeMode.light, ThemeMode.dark, ThemeMode.auto], id: \.self) { theme in
                    ThemeModeButton(
                        theme: theme,
                        isSelected: currentTheme == theme,
                        action: { onThemeChanged(theme) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

struct ThemeModeButton: View {
    let theme: ThemeMode
    let isSelected: Bool
    let action: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(
                        isSelected
                        ? themeManager.colors.primary
                        : themeManager.colors.surface
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: theme.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(
                                isSelected
                                ? .white
                                : themeManager.colors.textSecondary
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected
                                ? themeManager.colors.primary
                                : themeManager.colors.divider,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                
                Text(theme.settingsDisplayName(using: localizationManager))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(
                        isSelected
                        ? themeManager.colors.primary
                        : themeManager.colors.textSecondary
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ColorAccentRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        HStack {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(themeManager.colors.accent)
            
                            Text(localizationManager.string(for: "settings.accent_color"))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(themeManager.colors.textPrimary)
            
            Spacer()
            
            // Current accent color preview
            Circle()
                .fill(themeManager.colors.primary)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(themeManager.colors.divider, lineWidth: 1)
                )
        }
        .padding(16)
    }
}

struct LanguageOptionRow: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(language.flag)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.nativeName(using: localizationManager))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeManager.colors.textPrimary)
                    
                    Text(language.localizedDisplayName)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(themeManager.colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(themeManager.colors.primary)
                }
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
        .environmentObject(LocalizationManager())
} 