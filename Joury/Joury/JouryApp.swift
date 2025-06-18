//
//  JouryApp.swift
//  Joury
//
//  Main application entry point for Joury iOS app
//

import SwiftUI

@main
struct JouryApp: App {
    // Core managers
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var localizationManager = LocalizationManager()
    @StateObject private var networkManager = NetworkManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
                .environmentObject(networkManager)
                .environmentObject(authManager)
                .environment(\.theme, themeManager)
                .environment(\.localization, localizationManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}
