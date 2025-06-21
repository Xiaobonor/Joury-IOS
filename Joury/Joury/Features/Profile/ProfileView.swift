//
//  ProfileView.swift
//  Joury
//
//  Profile and settings view for Joury iOS app
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    profileHeaderSection
                    
                    statisticsSection
                    
                    settingsSection
                    
                    aboutSection
                    
                    signOutSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
            }
            .background(themeManager.colors.background)
            .navigationTitle("profile.profile".localized)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showingSettings) {
                SettingsView()
            }
            .alert("profile.sign_out_confirmation".localized, isPresented: $viewModel.showingSignOutAlert) {
                Button("common.cancel".localized, role: .cancel) { }
                Button("common.sign_out".localized, role: .destructive) {
                    Task {
                        await viewModel.signOut()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadProfileData()
        }
    }
    
    // MARK: - Profile Header Section
    
    private var profileHeaderSection: some View {
        VStack(spacing: 20) {
            // Profile Picture
            Button(action: { viewModel.showingImagePicker = true }) {
                Group {
                    if let profileImage = viewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [themeManager.colors.primary.opacity(0.3), themeManager.colors.secondary.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(themeManager.colors.primary)
                            )
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(themeManager.colors.primary.opacity(0.2), lineWidth: 3)
                )
                .shadow(color: themeManager.colors.shadow, radius: 10, x: 0, y: 5)
            }
            .buttonStyle(PlainButtonStyle())
            
            // User Info
            VStack(spacing: 8) {
                Text(viewModel.userName.isEmpty ? "common.guest".localized : viewModel.userName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Text(viewModel.userEmail.isEmpty ? "common.guest_email".localized : viewModel.userEmail)
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.textSecondary)
            }
        }
        .padding(.top, 30)
        .padding(.bottom, 40)
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("profile.statistics".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "profile.journal_entries".localized,
                    value: "\(viewModel.journalCount)",
                    icon: "book.fill",
                    color: themeManager.colors.primary
                )
                
                StatCard(
                    title: "profile.current_streak".localized,
                    value: "\(viewModel.currentStreak)",
                    icon: "flame.fill",
                    color: themeManager.colors.warning
                )
                
                StatCard(
                    title: "profile.completed_habits".localized,
                    value: "\(viewModel.habitsCompleted)",
                    icon: "checkmark.circle.fill",
                    color: themeManager.colors.success
                )
            }
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "profile.settings".localized)
            
            VStack(spacing: 0) {
                ProfileMenuRow(
                    title: "settings.settings".localized,
                    subtitle: "settings.appearance_language_notifications".localized,
                    icon: "gear",
                    iconColor: themeManager.colors.primary,
                    action: { viewModel.showingSettings = true }
                )
                
                Divider()
                    .background(themeManager.colors.divider)
                    .padding(.leading, 52)
            }
            .background(themeManager.colors.surface)
            .cornerRadius(12)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "profile.about".localized)
            
            VStack(spacing: 0) {
                ProfileMenuRow(
                    title: "profile.rate_app".localized,
                    subtitle: "profile.rate_app_subtitle".localized,
                    icon: "star",
                    iconColor: themeManager.colors.warning,
                    action: { viewModel.rateApp() }
                )
                
                Divider()
                    .background(themeManager.colors.divider)
                    .padding(.leading, 52)
                
                ProfileMenuRow(
                    title: "profile.feedback".localized,
                    subtitle: "profile.feedback_subtitle".localized,
                    icon: "envelope",
                    iconColor: themeManager.colors.info,
                    action: { viewModel.sendFeedback() }
                )
                
                Divider()
                    .background(themeManager.colors.divider)
                    .padding(.leading, 52)
                
                ProfileMenuRow(
                    title: "profile.privacy_policy".localized,
                    subtitle: "profile.privacy_policy_subtitle".localized,
                    icon: "shield",
                    iconColor: themeManager.colors.secondary,
                    action: { viewModel.showPrivacyPolicy() }
                )
                
                Divider()
                    .background(themeManager.colors.divider)
                    .padding(.leading, 52)
                
                ProfileMenuRow(
                    title: "profile.terms_of_service".localized,
                    subtitle: "profile.terms_of_service_subtitle".localized,
                    icon: "doc.text",
                    iconColor: themeManager.colors.accent,
                    action: { viewModel.showTermsOfService() },
                    showChevron: false
                )
            }
            .background(themeManager.colors.surface)
            .cornerRadius(12)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Sign Out Section
    
    private var signOutSection: some View {
        VStack(spacing: 0) {
            if case .authenticated = authManager.authState {
                ProfileMenuRow(
                    title: "common.sign_out".localized,
                    subtitle: "profile.sign_out_subtitle".localized,
                    icon: "rectangle.portrait.and.arrow.right",
                    iconColor: themeManager.colors.error,
                    action: { viewModel.showingSignOutAlert = true },
                    showChevron: false,
                    isDestructive: true
                )
                .background(themeManager.colors.surface)
                .cornerRadius(12)
            } else {
                ProfileMenuRow(
                    title: "common.sign_in".localized,
                    subtitle: "profile.sign_in_subtitle".localized,
                    icon: "person.circle",
                    iconColor: themeManager.colors.primary,
                    action: { /* TODO: Navigate to sign in */ },
                    showChevron: false
                )
                .background(themeManager.colors.surface)  
                .cornerRadius(12)
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.colors.textPrimary)
            
            Spacer()
        }
        .padding(.bottom, 12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.colors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.colors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(themeManager.colors.surface)
        .cornerRadius(16)
        .shadow(color: themeManager.colors.shadow, radius: 8, x: 0, y: 4)
    }
}

struct ProfileMenuRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let action: () -> Void
    let showChevron: Bool
    let isDestructive: Bool
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color,
        action: @escaping () -> Void,
        showChevron: Bool = true,
        isDestructive: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.action = action
        self.showChevron = showChevron
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? themeManager.colors.error : themeManager.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(themeManager.colors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthenticationManager())
} 