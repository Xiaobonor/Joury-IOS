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
    @StateObject private var authenticationManager = AuthenticationManager.shared
    @StateObject private var appReloader = AppReloader.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
                .environmentObject(networkManager)
                .environmentObject(authenticationManager)
                .environment(\.theme, themeManager)
                .environment(\.localization, localizationManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .id(appReloader.reloadTrigger) // This will force a complete reload when the trigger changes
        }
    }
}
