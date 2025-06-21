//
//  JournalView.swift
//  Joury
//
//  Redesigned immersive journal view with quick access to writing and history.
//

import SwiftUI
import Combine

struct JournalView: View {
    let initialMode: JournalMode
    
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedMode: JournalMode
    @State private var animateEntrance = false
    @State private var traditionalText = ""
    
    init(initialMode: JournalMode = .interactive) {
        self.initialMode = initialMode
        self._selectedMode = State(initialValue: initialMode)
    }
    
    var body: some View {
        ZStack {
            // Background
            themeManager.colors.background
                .ignoresSafeArea()
            
            // Writing Interface
            writingInterface
                .opacity(animateEntrance ? 1 : 0)
                .scaleEffect(animateEntrance ? 1 : 0.95)
        }
        .onAppear {
            Task {
                await viewModel.loadTodayJournal()
                traditionalText = viewModel.todayJournalText ?? ""
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateEntrance = true
            }
        }
    }
    

    
    // MARK: - Writing Interface
    private var writingInterface: some View {
        ZStack {
            if selectedMode == .traditional {
                TraditionalWritingView(
                    text: $traditionalText,
                    onSave: { content in
                        Task {
                            await viewModel.saveTraditionalEntry(content)
                            presentationMode.wrappedValue.dismiss()
                        }
                    },
                    onCancel: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            } else {
                InteractiveWritingView(
                    messages: viewModel.messages,
                    isLoading: viewModel.isLoading,
                    onSendMessage: { message in
                        Task {
                            await viewModel.sendMessage(message)
                        }
                    },
                    onCancel: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }

}

// MARK: - Supporting Views

struct MessageBubbleView: View {
    let message: JournalMessage
    let isFromUser: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromUser {
                Spacer(minLength: 50)
            } else {
                // AI avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.colors.primary, themeManager.colors.primary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .shadow(color: themeManager.colors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isFromUser ? .white : themeManager.colors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                isFromUser ?
                                LinearGradient(
                                    colors: [themeManager.colors.primary, themeManager.colors.primary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [themeManager.colors.surface, themeManager.colors.surface],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(themeManager.colors.textSecondary)
                    .padding(.horizontal, 4)
            }
            
            if !isFromUser {
                Spacer(minLength: 50)
            }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // AI avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [themeManager.colors.primary, themeManager.colors.primary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(color: themeManager.colors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
            
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(themeManager.colors.textSecondary)
                        .frame(width: 8, height: 8)
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
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(themeManager.colors.surface)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            
            Spacer(minLength: 50)
        }
        .onAppear {
            animationOffset = -4
        }
    }
}

// MARK: - Writing Views

struct TraditionalWritingView: View {
    @Binding var text: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(localizationManager.string(for: "common.cancel"), action: onCancel)
                    .foregroundColor(themeManager.colors.textSecondary)
                
                Spacer()
                
                Text(localizationManager.string(for: "journal.traditional.title"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
                
                Button(localizationManager.string(for: "common.save")) {
                    onSave(text)
                }
                .foregroundColor(themeManager.colors.primary)
                .fontWeight(.semibold)
            }
            .padding()
            .background(themeManager.colors.surface)
            
            // Writing Area
            TextEditor(text: $text)
                .focused($isTextFieldFocused)
                .font(.body)
                .padding()
                .background(themeManager.colors.background)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

struct InteractiveWritingView: View {
    let messages: [JournalMessage]
    let isLoading: Bool
    let onSendMessage: (String) -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(localizationManager.string(for: "common.cancel"), action: onCancel)
                    .foregroundColor(themeManager.colors.textSecondary)
                
                Spacer()
                
                Text(localizationManager.string(for: "journal.interactive.title"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
                
                Button(localizationManager.string(for: "common.done"), action: onCancel)
                    .foregroundColor(themeManager.colors.primary)
                    .fontWeight(.semibold)
            }
            .padding()
            .background(themeManager.colors.surface)
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message, isFromUser: message.isFromUser)
                    }
                    
                    if isLoading {
                        TypingIndicatorView()
                    }
                }
                .padding()
            }
            
            // Input
            HStack(spacing: 12) {
                TextField(localizationManager.string(for: "journal.interactive.placeholder"), text: $inputText)
                    .focused($isInputFocused)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(inputText.isEmpty ? themeManager.colors.textSecondary : themeManager.colors.primary)
                }
                .disabled(inputText.isEmpty)
            }
            .padding()
            .background(themeManager.colors.surface)
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onSendMessage(inputText)
        inputText = ""
    }
}



// MARK: - Preview

#Preview {
    JournalView()
        .environmentObject(ThemeManager())
        .environmentObject(LocalizationManager())
} 