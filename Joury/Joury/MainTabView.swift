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
    @State private var selectedTab: TabItem = .journal
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Journal Tab
            JournalView()
                .tabItem {
                    Image(systemName: selectedTab == .journal ? "book.fill" : "book")
                    Text("journal.journal".localized)
                }
                .tag(TabItem.journal)
            
            // Habits Tab
            HabitsView()
                .tabItem {
                    Image(systemName: selectedTab == .habits ? "checkmark.circle.fill" : "checkmark.circle")
                    Text("habits.habits".localized)
                }
                .tag(TabItem.habits)
            
            // Focus Tab
            FocusView()
                .tabItem {
                    Image(systemName: selectedTab == .focus ? "timer.circle.fill" : "timer.circle")
                    Text("focus.focus".localized)
                }
                .tag(TabItem.focus)
            
            // Analytics Tab
            AnalyticsView()
                .tabItem {
                    Image(systemName: selectedTab == .analytics ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.uptrend.xyaxis.circle")
                    Text("analytics.analytics".localized)
                }
                .tag(TabItem.analytics)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == .profile ? "person.circle.fill" : "person.circle")
                    Text("profile.profile".localized)
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
    
    var title: String {
        switch self {
        case .journal: return "journal.journal".localized
        case .habits: return "habits.habits".localized
        case .focus: return "focus.focus".localized
        case .analytics: return "analytics.analytics".localized
        case .profile: return "profile.profile".localized
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

// HabitsView is now in its own file

// FocusView is now in its own file

// AnalyticsView is now in its own file

struct ProfileView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authManager: AuthenticationManager
    
    private var isAuthenticated: Bool {
        if case .authenticated = authManager.authState {
            return true
        }
        return false
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // User Info Section
                VStack(spacing: 12) {
                    // Profile Picture
                    Circle()
                        .fill(themeManager.colors.surface)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(themeManager.colors.textSecondary)
                        )
                    
                    // User Name
                    Text(authManager.currentUser?.name ?? "Guest User")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    // User Email
                    if let email = authManager.currentUser?.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(themeManager.colors.textSecondary)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Settings Options
                VStack(spacing: 0) {
                    ProfileMenuRow(
                        title: "Settings",
                        icon: "gear",
                        action: { /* TODO: Navigate to settings */ }
                    )
                    
                    ProfileMenuRow(
                        title: "Privacy Policy",
                        icon: "shield",
                        action: { /* TODO: Show privacy policy */ }
                    )
                    
                    ProfileMenuRow(
                        title: "About",
                        icon: "info.circle",
                        action: { /* TODO: Show about */ }
                    )
                    
                    ProfileMenuRow(
                        title: isAuthenticated ? "Sign Out" : "Sign In",
                        icon: isAuthenticated ? "rectangle.portrait.and.arrow.right" : "rectangle.portrait.and.arrow.right",
                        action: {
                            if isAuthenticated {
                                Task { await authManager.signOut() }
                            } else {
                                // TODO: Navigate to sign in
                            }
                        },
                        showChevron: false
                    )
                }
                .background(themeManager.colors.surface)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeManager.colors.background)
            .navigationTitle("profile.profile".localized)
        }
    }
}

struct ProfileMenuRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    let showChevron: Bool
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(title: String, icon: String, action: @escaping () -> Void, showChevron: Bool = true) {
        self.title = title
        self.icon = icon
        self.action = action
        self.showChevron = showChevron
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(themeManager.colors.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainTabView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthenticationManager())
} 