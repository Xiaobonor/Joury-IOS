//
//  JournalHubView.swift
//  Joury
//
//  Simple and clean journal hub interface for quick access to writing.
//

import SwiftUI

struct JournalHubView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var viewModel = JournalViewModel()
    
    @State private var showingWritingView = false
    @State private var selectedMode: JournalMode = .interactive
    @State private var animateEntrance = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with greeting
                    headerSection
                    
                    // Today's status card
                    todayStatusSection
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    
                    // Quick mode selection
                    modeSelectionSection
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    
                    Spacer()
                    
                    // Recent entries preview
                    recentEntriesSection
                        .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .opacity(animateEntrance ? 1 : 0)
                .offset(y: animateEntrance ? 0 : 20)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showingWritingView) {
            JournalView(initialMode: selectedMode)
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
        }
        .onAppear {
            Task {
                await viewModel.loadTodayJournal()
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateEntrance = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(greeting)
                .font(.largeTitle)
                .fontWeight(.medium)
                .foregroundColor(themeManager.colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(todayDate)
                .font(.subheadline)
                .foregroundColor(themeManager.colors.textSecondary)
        }
        .padding(.top, 20)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Today Status Section
    private var todayStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(themeManager.colors.primary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizationManager.string(for: "journal.today.status"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    Text(todayStatusText)
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textSecondary)
                }
                
                Spacer()
                
                if hasWrittenToday {
                    Button(action: {
                        selectedMode = viewModel.messages.isEmpty ? .traditional : .interactive
                        showingWritingView = true
                    }) {
                        Text(localizationManager.string(for: "journal.continue"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.colors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(themeManager.colors.primary.opacity(0.1))
                            )
                    }
                }
            }
            
            // Mood indicator if available
            if let mood = viewModel.currentMoodScore {
                HStack {
                    Text(localizationManager.string(for: "journal.mood.today"))
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textSecondary)
                    
                    Spacer()
                    
                    MoodIndicator(score: mood)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.surface)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Mode Selection Section
    private var modeSelectionSection: some View {
        HStack(spacing: 16) {
            QuickModeButton(
                title: localizationManager.string(for: "journal.quick.traditional"),
                subtitle: localizationManager.string(for: "journal.quick.traditional.subtitle"),
                icon: "square.and.pencil",
                color: themeManager.colors.primary
            ) {
                selectedMode = .traditional
                showingWritingView = true
            }
            
            QuickModeButton(
                title: localizationManager.string(for: "journal.quick.interactive"),
                subtitle: localizationManager.string(for: "journal.quick.interactive.subtitle"),
                icon: "bubble.left.and.bubble.right",
                color: themeManager.colors.secondary
            ) {
                selectedMode = .interactive
                showingWritingView = true
            }
        }
    }
    
    // MARK: - Recent Entries Section
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(localizationManager.string(for: "journal.recent.entries"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: PastJournalsView()) {
                    Text(localizationManager.string(for: "journal.view.all"))
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.primary)
                }
            }
            
            if !hasWrittenToday {
                EmptyStateView()
            } else {
                // Show recent entries preview
                VStack(spacing: 8) {
                    RecentEntryPreview(
                        date: Date(),
                        preview: (viewModel.todayJournalText?.isEmpty ?? true) ? 
                            localizationManager.string(for: "journal.interactive.welcome") : 
                            String(viewModel.todayJournalText?.prefix(100) ?? ""),
                        moodScore: viewModel.currentMoodScore
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return localizationManager.string(for: "journal.greeting.morning")
        case 12..<17:
            return localizationManager.string(for: "journal.greeting.afternoon")
        case 17..<22:
            return localizationManager.string(for: "journal.greeting.evening")
        default:
            return localizationManager.string(for: "journal.greeting.night")
        }
    }
    
    private var todayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: localizationManager.currentLanguage == .traditionalChinese ? "zh-TW" : "en-US")
        return formatter.string(from: Date())
    }
    
    private var todayStatusText: String {
        if hasWrittenToday {
            return localizationManager.string(for: "journal.today.written")
        } else {
            return localizationManager.string(for: "journal.today.not_written")
        }
    }
    
    private var hasWrittenToday: Bool {
        return !(viewModel.todayJournalText?.isEmpty ?? true) || !viewModel.messages.isEmpty
    }
}

// MARK: - Supporting Views

struct MoodIndicator: View {
    let score: Double
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= Int(score / 2) ? "star.fill" : "star")
                    .foregroundColor(themeManager.colors.secondary)
                    .font(.caption)
            }
        }
    }
}

struct EmptyStateView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(themeManager.colors.textSecondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(localizationManager.string(for: "journal.empty.title"))
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Text(localizationManager.string(for: "journal.empty.subtitle"))
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 32)
    }
}

struct QuickModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct RecentEntryPreview: View {
    let date: Date
    let preview: String
    let moodScore: Double?
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
                
                Text(preview)
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.textPrimary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if let mood = moodScore {
                MoodIndicator(score: mood)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.colors.surface)
        )
    }
}

struct PastJournalsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        VStack {
                            Text(localizationManager.string(for: "journal.past_journals"))
                .font(.title)
                .padding()
            
            Text("Coming Soon...")
                .foregroundColor(themeManager.colors.textSecondary)
            
            Spacer()
        }
        .navigationTitle(localizationManager.string(for: "journal.history"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    JournalHubView()
        .environmentObject(ThemeManager())
        .environmentObject(LocalizationManager())
} 