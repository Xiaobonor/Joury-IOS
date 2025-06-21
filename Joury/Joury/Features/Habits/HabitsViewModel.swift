//
//  HabitsViewModel.swift
//  Joury
//
//  Habits view model for managing habit tracking
//

import SwiftUI
import Combine

@MainActor
class HabitsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var habits: [Habit] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var completedTodayCount: Int {
        habits.filter { $0.isCompletedToday }.count
    }
    
    var totalHabitsCount: Int {
        habits.count
    }
    
    var todayProgress: Double {
        guard totalHabitsCount > 0 else { return 0.0 }
        return Double(completedTodayCount) / Double(totalHabitsCount)
    }
    
    var weeklyData: [DayData] {
        let calendar = Calendar.current
        let today = Date()
        var weekData: [DayData] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i - 6, to: today) ?? today
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            let isCompleted = habits.allSatisfy { habit in
                if let lastCompleted = habit.lastCompleted {
                    return calendar.isDate(lastCompleted, inSameDayAs: date)
                }
                return false
            }
            weekData.append(DayData(dayName: dayName, isCompleted: isCompleted))
        }
        return weekData
    }
    
    // MARK: - Initialization
    init() {
        loadMockData()
    }
    
    // MARK: - Public Methods
    func loadHabits() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let networkManager = NetworkManager.shared
                let response: [Habit] = try await networkManager.request(
                    endpoint: "/habits",
                    method: .GET,
                    responseType: [Habit].self
                ).asyncValue()
                
                await MainActor.run {
                    self.habits = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load habits: \(error.localizedDescription)"
                    self.isLoading = false
                    // Fallback to mock data for now
                    self.loadMockData()
                }
            }
        }
    }
    
    func toggleHabit(_ habit: Habit) {
        Task {
            do {
                let networkManager = NetworkManager.shared
                let response: Habit = try await networkManager.request(
                    endpoint: "/habits/\(habit.id)/toggle",
                    method: .POST,
                    responseType: Habit.self
                ).asyncValue()
                
                await MainActor.run {
                    if let index = self.habits.firstIndex(where: { $0.id == habit.id }) {
                        self.habits[index] = response
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to toggle habit: \(error.localizedDescription)"
                    // Fallback to local toggle for better UX
                    if let index = self.habits.firstIndex(where: { $0.id == habit.id }) {
                        self.habits[index].isCompletedToday.toggle()
                        if self.habits[index].isCompletedToday {
                            self.habits[index].lastCompleted = Date()
                            self.habits[index].currentStreak += 1
                        } else {
                            self.habits[index].currentStreak = max(0, self.habits[index].currentStreak - 1)
                        }
                        self.updateWeeklyProgress(for: &self.habits[index])
                    }
                }
            }
        }
    }
    
    func addHabit(_ habit: Habit) {
        Task {
            do {
                let networkManager = NetworkManager.shared
                
                // Create habit data for API
                let habitData = CreateHabitRequest(
                    name: habit.name,
                    description: habit.description,
                    type: habit.type.rawValue,
                    targetValue: habit.targetValue
                )
                
                let response: Habit = try await networkManager.request(
                    endpoint: "/habits",
                    method: .POST,
                    body: habitData,
                    responseType: Habit.self
                ).asyncValue()
                
                await MainActor.run {
                    self.habits.append(response)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to create habit: \(error.localizedDescription)"
                    // Fallback to local add for better UX
                    self.habits.append(habit)
                }
            }
        }
    }
    
    func editHabit(_ habit: Habit) {
        // TODO: Implement edit habit functionality
        print("Editing habit: \(habit.name)")
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
    }
    
    // MARK: - Private Methods
    private func loadMockData() {
        habits = [
            Habit(
                name: NSLocalizedString("habits.morning_meditation", comment: ""),
                description: NSLocalizedString("habits.meditation_desc", comment: ""),
                type: .daily,
                targetValue: 1,
                currentStreak: 7,
                isCompletedToday: true,
                weeklyProgress: 0.86,
                lastCompleted: Date()
            ),
            Habit(
                name: NSLocalizedString("habits.daily_journal", comment: ""),
                description: NSLocalizedString("habits.journal_desc", comment: ""),
                type: .daily,
                targetValue: 1,
                currentStreak: 5,
                isCompletedToday: false,
                weeklyProgress: 0.71,
                lastCompleted: Calendar.current.date(byAdding: .day, value: -1, to: Date())
            ),
            Habit(
                name: NSLocalizedString("habits.gratitude_practice", comment: ""),
                description: NSLocalizedString("habits.gratitude_desc", comment: ""),
                type: .daily,
                targetValue: 1,
                currentStreak: 12,
                isCompletedToday: true,
                weeklyProgress: 1.0,
                lastCompleted: Date()
            )
        ]
    }
    
    private func updateWeeklyProgress(for habit: inout Habit) {
        let calendar = Calendar.current
        let today = Date()
        var completedDays = 0
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i - 6, to: today),
               let lastCompleted = habit.lastCompleted,
               calendar.isDate(lastCompleted, inSameDayAs: date) {
                completedDays += 1
            }
        }
        
        habit.weeklyProgress = Double(completedDays) / 7.0
    }
} 