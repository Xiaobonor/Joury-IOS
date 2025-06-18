//
//  ContentView.swift
//  Joury
//
//  Main content view for Joury iOS app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    private var isAuthenticated: Bool {
        if case .authenticated = authManager.authState {
            return true
        }
        return false
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Header
                VStack(spacing: 10) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.colors.primary)
                    
                    Text(LocalizationKeys.General.appName.localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    Text("AI-powered personal growth & journaling")
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Status Section
                VStack(spacing: 20) {
                    StatusCard(
                        title: "Network Status",
                        value: networkManager.isOnline ? "Online" : "Offline",
                        color: networkManager.isOnline ? themeManager.colors.success : themeManager.colors.error
                    )
                    
                    StatusCard(
                        title: "Authentication",
                        value: isAuthenticated ? "Signed In" : "Guest Mode",
                        color: isAuthenticated ? themeManager.colors.success : themeManager.colors.warning
                    )
                    
                    StatusCard(
                        title: "Theme",
                        value: themeManager.currentTheme.displayName,
                        color: themeManager.colors.info
                    )
                    
                    StatusCard(
                        title: "Language",
                        value: localizationManager.currentLanguage.displayName,
                        color: themeManager.colors.secondary
                    )
                }
                
                Spacer()
                
                // Quick Actions
                VStack(spacing: 15) {
                    ConfigActionButton(
                        title: "Change Theme",
                        icon: "paintbrush.fill",
                        action: { cycleTheme() }
                    )
                    
                    ConfigActionButton(
                        title: "Toggle Language",
                        icon: "globe",
                        action: { toggleLanguage() }
                    )
                    
                    ConfigActionButton(
                        title: "Test Network",
                        icon: "network",
                        action: { testNetwork() }
                    )
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .background(themeManager.colors.background)
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Actions
    
    private func cycleTheme() {
        let themes: [ThemeMode] = [.light, .dark, .auto]
        let currentIndex = themes.firstIndex(of: themeManager.currentTheme) ?? 0
        let nextIndex = (currentIndex + 1) % themes.count
        themeManager.setTheme(themes[nextIndex])
    }
    
    private func toggleLanguage() {
        let newLanguage: Language = localizationManager.currentLanguage == .english ? .traditionalChinese : .english
        localizationManager.setLanguage(newLanguage)
    }
    
    private func testNetwork() {
        // Simple network test - in real app this would test API connectivity
        print("Testing network connectivity...")
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let title: String
    let value: String
    let color: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(color)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(themeManager.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: themeManager.colors.shadow, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Config Action Button

struct ConfigActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(themeManager.colors.primary)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
            }
            .padding()
            .background(themeManager.colors.cardBackground)
            .cornerRadius(12)
            .shadow(color: themeManager.colors.shadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environmentObject(LocalizationManager())
        .environmentObject(NetworkManager.shared)
        .environmentObject(AuthenticationManager.shared)
}
