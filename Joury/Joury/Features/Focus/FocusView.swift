//
//  FocusView.swift
//  Joury
//
//  Focus mode with Pomodoro timer and virtual focus rooms.
//

import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel = FocusViewModel()
    @State private var selectedTab: FocusTab = .timer
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                focusTabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    PomodoroTimerView(viewModel: viewModel)
                        .tag(FocusTab.timer)
                    
                    FocusRoomsView(viewModel: viewModel)
                        .tag(FocusTab.rooms)
                    
                    FocusStatsView(viewModel: viewModel)
                        .tag(FocusTab.stats)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(themeManager.colors.background)
            .navigationTitle("focus.focus".localized)
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Tab Selector
    private var focusTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(FocusTab.allCases, id: \.self) { tab in
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.title2)
                            .foregroundColor(selectedTab == tab ? themeManager.colors.primary : themeManager.colors.textSecondary)
                        
                        Text(tab.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == tab ? themeManager.colors.primary : themeManager.colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(themeManager.colors.surface)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

// MARK: - Focus Tabs
enum FocusTab: CaseIterable {
    case timer, rooms, stats
    
    var title: String {
        switch self {
        case .timer: return "focus.timer".localized
        case .rooms: return "focus.rooms".localized
        case .stats: return "focus.stats".localized
        }
    }
    
    var icon: String {
        switch self {
        case .timer: return "timer"
        case .rooms: return "person.3.fill"
        case .stats: return "chart.bar.fill"
        }
    }
}

// MARK: - Pomodoro Timer View
struct PomodoroTimerView: View {
    @ObservedObject var viewModel: FocusViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Timer Circle
            ZStack {
                // Background Circle
                Circle()
                    .stroke(themeManager.colors.textSecondary.opacity(0.2), lineWidth: 8)
                    .frame(width: 280, height: 280)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: viewModel.timerProgress)
                    .stroke(
                        viewModel.isRunning ? themeManager.colors.primary : themeManager.colors.textSecondary,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.timerProgress)
                
                // Timer Text
                VStack(spacing: 8) {
                    Text(viewModel.timeString)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    Text(viewModel.currentPhase.title)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.textSecondary)
                }
            }
            
            // Session Info
            VStack(spacing: 12) {
                HStack {
                    Text("focus.session".localized)
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(viewModel.completedSessions)/\(viewModel.targetSessions)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.colors.primary)
                }
                
                ProgressView(value: Double(viewModel.completedSessions), total: Double(viewModel.targetSessions))
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.colors.primary))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Control Buttons
            HStack(spacing: 30) {
                // Reset Button
                Button(action: viewModel.resetTimer) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(themeManager.colors.textSecondary)
                        .frame(width: 60, height: 60)
                        .background(themeManager.colors.surface)
                        .clipShape(Circle())
                }
                .disabled(viewModel.isRunning)
                
                // Play/Pause Button
                Button(action: viewModel.toggleTimer) {
                    Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(themeManager.colors.primary)
                        .clipShape(Circle())
                        .scaleEffect(viewModel.isRunning ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: viewModel.isRunning)
                }
                
                // Skip Button
                Button(action: viewModel.skipPhase) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.colors.textSecondary)
                        .frame(width: 60, height: 60)
                        .background(themeManager.colors.surface)
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Focus Rooms View
struct FocusRoomsView: View {
    @ObservedObject var viewModel: FocusViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingCreateRoom = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("focus.availableRooms".localized)
                    .font(.headline)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
                
                Button(action: { showingCreateRoom = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(themeManager.colors.primary)
                }
            }
            .padding(.horizontal, 20)
            
            // Rooms List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.focusRooms) { room in
                        FocusRoomCardView(
                            room: room,
                            onJoin: { viewModel.joinRoom(room) }
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 10)
            }
            
            if viewModel.focusRooms.isEmpty {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.colors.textSecondary)
                    
                    Text("focus.noRooms".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    Text("focus.createFirstRoom".localized)
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingCreateRoom) {
            CreateRoomView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadFocusRooms()
        }
    }
}

// MARK: - Focus Room Card
struct FocusRoomCardView: View {
    let room: FocusRoom
    let onJoin: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Room Icon
            Circle()
                .fill(themeManager.colors.primary.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "timer")
                        .foregroundColor(themeManager.colors.primary)
                )
            
            // Room Info
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.headline)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Text(room.description)
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textSecondary)
                    
                    Text("\(room.participantCount) active")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Join Button
            Button(action: onJoin) {
                Text("focus.join".localized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(themeManager.colors.primary)
                    .cornerRadius(20)
            }
        }
        .padding(16)
        .background(themeManager.colors.surface)
        .cornerRadius(12)
        .shadow(color: themeManager.colors.textPrimary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Focus Stats View
struct FocusStatsView: View {
    @ObservedObject var viewModel: FocusViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Today's Stats
                VStack(alignment: .leading, spacing: 16) {
                    Text("focus.todayStats".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    HStack(spacing: 20) {
                        StatCardView(
                            title: "focus.sessions".localized,
                            value: "\(viewModel.todayStats.sessions)",
                            icon: "timer.circle.fill",
                            color: themeManager.colors.primary
                        )
                        
                        StatCardView(
                            title: "focus.minutes".localized,
                            value: "\(viewModel.todayStats.minutes)",
                            icon: "clock.fill",
                            color: themeManager.colors.success
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                // Weekly Overview
                VStack(alignment: .leading, spacing: 16) {
                    Text("focus.weeklyOverview".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    WeeklyFocusChartView(data: viewModel.weeklyStats)
                }
                .padding(.horizontal, 20)
                
                // Achievements
                VStack(alignment: .leading, spacing: 16) {
                    Text("focus.achievements".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(viewModel.achievements) { achievement in
                            AchievementCardView(achievement: achievement)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Stat Card View
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.colors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(themeManager.colors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Weekly Focus Chart (Placeholder)
struct WeeklyFocusChartView: View {
    let data: [Int]
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<7) { index in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(themeManager.colors.primary)
                            .frame(width: 30, height: CGFloat(data[index]) * 3)
                            .cornerRadius(4)
                        
                        Text(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][index])
                            .font(.caption2)
                            .foregroundColor(themeManager.colors.textSecondary)
                    }
                }
            }
            .frame(height: 120)
        }
        .padding(16)
        .background(themeManager.colors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Achievement Card
struct AchievementCardView: View {
    let achievement: Achievement
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title)
                .foregroundColor(achievement.isUnlocked ? themeManager.colors.warning : themeManager.colors.textSecondary)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.colors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(themeManager.colors.surface)
        .cornerRadius(12)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Create Room View (Placeholder)
struct CreateRoomView: View {
    @ObservedObject var viewModel: FocusViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var roomName = ""
    @State private var roomDescription = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("focus.roomName".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    TextField("focus.roomNamePlaceholder".localized, text: $roomName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("focus.roomDescription".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    TextField("focus.roomDescriptionPlaceholder".localized, text: $roomDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: createRoom) {
                        Text("focus.createRoom".localized)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeManager.colors.primary)
                            .cornerRadius(12)
                    }
                    .disabled(roomName.isEmpty)
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("common.cancel".localized)
                            .font(.headline)
                            .foregroundColor(themeManager.colors.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(themeManager.colors.background)
            .navigationTitle("focus.createRoom".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func createRoom() {
        // Implementation for creating room
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview
#Preview {
    FocusView()
        .environmentObject(ThemeManager())
} 