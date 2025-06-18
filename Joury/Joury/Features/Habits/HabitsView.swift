//
//  HabitsView.swift
//  Joury
//
//  Habits tracking view with AI-powered habit coaching.
//

import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel = HabitsViewModel()
    @State private var showingAddHabit = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                    
                    // Content
                    if viewModel.habits.isEmpty {
                        emptyStateView
                    } else {
                        habitsList
                    }
                }
            }
            .navigationTitle("habits.habits".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadHabits()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Today's Progress
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("habits.todayProgress".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    Text("\(viewModel.completedTodayCount)/\(viewModel.totalHabitsCount) completed")
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.textSecondary)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: viewModel.todayProgress,
                    color: themeManager.colors.primary
                )
                .frame(width: 60, height: 60)
            }
            .padding(.horizontal, 20)
            
            // Weekly Summary
            WeeklySummaryView(weekData: viewModel.weeklyData)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(themeManager.colors.surface)
    }
    
    // MARK: - Habits List
    private var habitsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.habits) { habit in
                    HabitCardView(
                        habit: habit,
                        onToggle: { viewModel.toggleHabit(habit) },
                        onEdit: { viewModel.editHabit(habit) }
                    )
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.badge.xmark")
                .font(.system(size: 80))
                .foregroundColor(themeManager.colors.textSecondary)
            
            VStack(spacing: 8) {
                Text("habits.emptyTitle".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Text("habits.emptyMessage".localized)
                    .font(.body)
                    .foregroundColor(themeManager.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: { showingAddHabit = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("habits.createFirst".localized)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(themeManager.colors.primary)
                .cornerRadius(25)
            }
            
            Spacer()
        }
    }
}

// MARK: - Habit Card View
struct HabitCardView: View {
    let habit: Habit
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    if !habit.description.isEmpty {
                        Text(habit.description)
                            .font(.caption)
                            .foregroundColor(themeManager.colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: onToggle) {
                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(habit.isCompletedToday ? themeManager.colors.success : themeManager.colors.textSecondary)
                }
            }
            
            // Progress Bar
            ProgressView(value: habit.weeklyProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: themeManager.colors.primary))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Stats
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(themeManager.colors.warning)
                    Text("\(habit.streakCount)")
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Text("\(Int(habit.weeklyProgress * 100))% this week")
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(themeManager.colors.textSecondary)
                }
            }
            .font(.caption)
        }
        .padding(16)
        .background(themeManager.colors.surface)
        .cornerRadius(12)
        .shadow(color: themeManager.colors.textPrimary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Weekly Summary View
struct WeeklySummaryView: View {
    let weekData: [DayData]
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("habits.weeklyProgress".localized)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.colors.textPrimary)
            
            HStack(spacing: 8) {
                ForEach(weekData) { day in
                    VStack(spacing: 4) {
                        Text(day.dayName)
                            .font(.caption2)
                            .foregroundColor(themeManager.colors.textSecondary)
                        
                        Circle()
                            .fill(day.isCompleted ? themeManager.colors.success : themeManager.colors.textSecondary.opacity(0.3))
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
    }
}

// MARK: - Add Habit View
struct AddHabitView: View {
    @ObservedObject var viewModel: HabitsViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var habitName = ""
    @State private var habitDescription = ""
    @State private var habitType: HabitType = .daily
    @State private var targetValue = 1
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Form Section
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("habits.name".localized)
                            .font(.headline)
                            .foregroundColor(themeManager.colors.textPrimary)
                        
                        TextField("habits.namePlaceholder".localized, text: $habitName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("habits.description".localized)
                            .font(.headline)
                            .foregroundColor(themeManager.colors.textPrimary)
                        
                        TextField("habits.descriptionPlaceholder".localized, text: $habitDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("habits.frequency".localized)
                            .font(.headline)
                            .foregroundColor(themeManager.colors.textPrimary)
                        
                        Picker("Frequency", selection: $habitType) {
                            Text("habits.daily".localized).tag(HabitType.daily)
                            Text("habits.weekly".localized).tag(HabitType.weekly)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: createHabit) {
                        Text("habits.create".localized)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeManager.colors.primary)
                            .cornerRadius(12)
                    }
                    .disabled(habitName.isEmpty)
                    
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
            .navigationTitle("habits.addHabit".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
    
    private func createHabit() {
        let newHabit = Habit(
            id: UUID().uuidString,
            name: habitName,
            description: habitDescription,
            type: habitType,
            targetValue: targetValue,
            currentStreak: 0,
            isCompletedToday: false,
            weeklyProgress: 0.0,
            createdAt: Date()
        )
        
        viewModel.addHabit(newHabit)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Models
struct Habit: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let type: HabitType
    let targetValue: Int
    let currentStreak: Int
    let isCompletedToday: Bool
    let weeklyProgress: Double
    let createdAt: Date
    
    var streakCount: Int { currentStreak }
}

enum HabitType: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
}

struct DayData: Identifiable {
    let id = UUID()
    let dayName: String
    let isCompleted: Bool
}

// MARK: - Preview
#Preview {
    HabitsView()
        .environmentObject(ThemeManager())
} 