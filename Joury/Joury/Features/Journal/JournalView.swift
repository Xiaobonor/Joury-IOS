//
//  JournalView.swift
//  Joury
//
//  Main view for interactive AI journaling.
//

import SwiftUI
import Combine

struct JournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var messageText = ""
    @State private var isTyping = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Messages List
                messagesScrollView
                
                // Input Bar
                inputBar
            }
            .background(themeManager.colors.background)
            .navigationTitle("journal.journal".localized)
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadTodayJournal()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
                
                // Mood Indicator
                if let currentMood = viewModel.currentMoodScore {
                    HStack(spacing: 4) {
                        Image(systemName: moodIcon(for: currentMood))
                            .foregroundColor(moodColor(for: currentMood))
                        Text(String(format: "%.1f", currentMood))
                            .font(.caption)
                            .foregroundColor(themeManager.colors.textSecondary)
                    }
                }
            }
            .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 8)
        .background(themeManager.colors.surface)
    }
    
    // MARK: - Messages Scroll View
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages, id: \.id) { message in
                        MessageBubbleView(
                            message: message,
                            isFromUser: message.isFromUser
                        )
                        .id(message.id)
                    }
                    
                    // AI typing indicator
                    if isTyping {
                        TypingIndicatorView()
                            .id("typing")
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isTyping) { typing in
                if typing {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        VStack(spacing: 8) {
            // Quick Action Buttons
            if viewModel.messages.isEmpty {
                quickActionButtons
            }
            
            // Text Input
            HStack(spacing: 12) {
                HStack {
                    TextField("journal.your_thoughts".localized, text: $messageText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .lineLimit(1...4)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .background(themeManager.colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                       themeManager.colors.textSecondary : themeManager.colors.primary)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(themeManager.colors.background)
    }
    
    // MARK: - Quick Action Buttons
    private var quickActionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "How was your day?",
                    icon: "sun.max"
                ) {
                    messageText = "How was your day?"
                    sendMessage()
                }
                
                QuickActionButton(
                    title: "What am I grateful for?",
                    icon: "heart"
                ) {
                    messageText = "What am I grateful for today?"
                    sendMessage()
                }
                
                QuickActionButton(
                    title: "What's on my mind?",
                    icon: "brain.head.profile"
                ) {
                    messageText = "What's on my mind right now?"
                    sendMessage()
                }
                
                QuickActionButton(
                    title: "Goals for tomorrow",
                    icon: "target"
                ) {
                    messageText = "What are my goals for tomorrow?"
                    sendMessage()
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Functions
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        isTyping = true
        
        Task {
            await viewModel.sendMessage(text)
            await MainActor.run {
                isTyping = false
            }
        }
    }
    
    private func moodIcon(for score: Double) -> String {
        switch score {
        case 0..<3: return "cloud.rain"
        case 3..<5: return "cloud"
        case 5..<7: return "cloud.sun"
        case 7..<9: return "sun.max"
        default: return "sun.max.fill"
        }
    }
    
    private func moodColor(for score: Double) -> Color {
        switch score {
        case 0..<3: return .blue
        case 3..<5: return .gray
        case 5..<7: return .orange
        case 7..<9: return .yellow
        default: return .green
        }
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: JournalMessage
    let isFromUser: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            if isFromUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isFromUser ? .white : themeManager.colors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isFromUser ? themeManager.colors.primary : themeManager.colors.surface)
                    )
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(themeManager.colors.textSecondary)
            }
            
            if !isFromUser {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(themeManager.colors.surface)
            .foregroundColor(themeManager.colors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(themeManager.colors.textSecondary)
                        .frame(width: 6, height: 6)
                        .offset(y: animationOffset)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(themeManager.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Spacer(minLength: 60)
        }
        .onAppear {
            animationOffset = -4
        }
    }
}

#Preview {
    JournalView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthenticationManager())
} 