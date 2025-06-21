//
//  MainTabView.swift
//  Joury
//
//  Main navigation structure for Joury app.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var selectedTab: TabItem = .journal
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Journal Tab
            JournalHubView()
                .tabItem {
                    Image(systemName: selectedTab == .journal ? "book.fill" : "book")
                    Text(localizationManager.string(for: "journal.journal"))
                }
                .tag(TabItem.journal)
            
            // Habits Tab
            HabitsView()
                .tabItem {
                    Image(systemName: selectedTab == .habits ? "checkmark.circle.fill" : "checkmark.circle")
                    Text(localizationManager.string(for: "habits.habits"))
                }
                .tag(TabItem.habits)
            
            // Focus Tab
            FocusView()
                .tabItem {
                    Image(systemName: selectedTab == .focus ? "timer.circle.fill" : "timer.circle")
                    Text(localizationManager.string(for: "focus.focus"))
                }
                .tag(TabItem.focus)
            
            // Analytics Tab
            AnalyticsView()
                .tabItem {
                    Image(systemName: selectedTab == .analytics ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.uptrend.xyaxis.circle")
                    Text(localizationManager.string(for: "analytics.analytics"))
                }
                .tag(TabItem.analytics)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == .profile ? "person.circle.fill" : "person.circle")
                    Text(localizationManager.string(for: "profile.profile"))
                }
                .tag(TabItem.profile)
        }
        .accentColor(themeManager.colors.primary)
        .background(themeManager.colors.background)
    }
}

// MARK: - Tab Items
enum TabItem: String, CaseIterable {
    case journal = "journal"
    case habits = "habits"
    case focus = "focus"
    case analytics = "analytics"
    case profile = "profile"
    
    func title(using localizationManager: LocalizationManager) -> String {
        switch self {
        case .journal: return localizationManager.string(for: "journal.journal")
        case .habits: return localizationManager.string(for: "habits.habits")
        case .focus: return localizationManager.string(for: "focus.focus")
        case .analytics: return localizationManager.string(for: "analytics.analytics")
        case .profile: return localizationManager.string(for: "profile.profile")
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

// HabitsView is now in its own file

// FocusView is now in its own file

// AnalyticsView is now in its own file

// ProfileView is now in its own file

#Preview {
    MainTabView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthenticationManager())
} 