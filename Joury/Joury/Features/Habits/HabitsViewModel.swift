//
//  HabitsViewModel.swift
//  Joury
//
//  View model for habits tracking functionality.
//

import Foundation
import Combine

@MainActor
class HabitsViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    private let cacheManager = CacheManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var totalHabitsCount: Int {
        habits.count
    }
    
    var completedTodayCount: Int {
        habits.filter { $0.isCompletedToday }.count
    }
    
    var todayProgress: Double {
        guard totalHabitsCount > 0 else { return 0.0 }
        return Double(completedTodayCount) / Double(totalHabitsCount)
    }
    
    var weeklyData: [DayData] {
        // Generate mock weekly data for now
        let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return weekdays.enumerated().map { index, day in
            DayData(dayName: day, isCompleted: index < 4) // Mock completion for first 4 days
        }
    }
    
    // MARK: - API Methods
    func loadHabits() {
        isLoading = true
        errorMessage = nil
        
        // Try to load from cache first
        if let cachedHabits: [Habit] = cacheManager.getObject([Habit].self, forKey: "user_habits") {
            habits = cachedHabits
            isLoading = false
        }
        
        // Then fetch from API
        Task {
            do {
                let fetchedHabits: [Habit] = try await networkManager.request(
                    endpoint: "/habits",
                    method: .GET,
                    responseType: [Habit].self
                ).asyncValue()
                
                await MainActor.run {
                    habits = fetchedHabits
                    isLoading = false
                    
                    // Cache the results
                    cacheManager.setObject(fetchedHabits, forKey: "user_habits", expiration: .minutes(5))
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    
                    // If API fails and we have no cached data, use mock data
                    if habits.isEmpty {
                        loadMockHabits()
                    }
                }
            }
        }
    }
    
    func addHabit(_ habit: Habit) {
        Task {
            do {
                let createdHabit: Habit = try await networkManager.request(
                    endpoint: "/habits",
                    method: .POST,
                    body: habit,
                    responseType: Habit.self
                ).asyncValue()
                
                await MainActor.run {
                    habits.append(createdHabit)
                    updateCache()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    // For now, add locally even if API fails
                    habits.append(habit)
                    updateCache()
                }
            }
        }
    }
    
    func toggleHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        
        // Update local state immediately
        let updatedHabit = Habit(
            id: habit.id,
            name: habit.name,
            description: habit.description,
            type: habit.type,
            targetValue: habit.targetValue,
            currentStreak: habit.isCompletedToday ? habit.currentStreak - 1 : habit.currentStreak + 1,
            isCompletedToday: !habit.isCompletedToday,
            weeklyProgress: habit.weeklyProgress, // This would be recalculated by backend
            createdAt: habit.createdAt
        )
        
        habits[index] = updatedHabit
        updateCache()
        
        // Sync with backend
        Task {
            do {
                let _ = try await networkManager.request(
                    endpoint: "/habits/\(habit.id)/toggle",
                    method: .POST,
                    responseType: Habit.self
                ).asyncValue()
            } catch {
                // Revert if API call fails
                await MainActor.run {
                    habits[index] = habit
                    errorMessage = error.localizedDescription
                    updateCache()
                }
            }
        }
    }
    
    func editHabit(_ habit: Habit) {
        // TODO: Implement habit editing
        print("Edit habit: \(habit.name)")
    }
    
    func deleteHabit(_ habit: Habit) {
        Task {
            do {
                try await networkManager.request(
                    endpoint: "/habits/\(habit.id)",
                    method: .DELETE,
                    responseType: EmptyResponse.self
                ).asyncValue()
                
                await MainActor.run {
                    habits.removeAll { $0.id == habit.id }
                    updateCache()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func updateCache() {
        cacheManager.setObject(habits, forKey: "user_habits", expiration: .minutes(5))
    }
    
    private func loadMockHabits() {
        habits = [
            Habit(
                id: "1",
                name: "Morning Exercise",
                description: "30 minutes of morning workout",
                type: .daily,
                targetValue: 1,
                currentStreak: 5,
                isCompletedToday: true,
                weeklyProgress: 0.8,
                createdAt: Date()
            ),
            Habit(
                id: "2",
                name: "Read Books",
                description: "Read at least 20 pages daily",
                type: .daily,
                targetValue: 20,
                currentStreak: 3,
                isCompletedToday: false,
                weeklyProgress: 0.6,
                createdAt: Date()
            ),
            Habit(
                id: "3",
                name: "Meditation",
                description: "10 minutes mindfulness meditation",
                type: .daily,
                targetValue: 10,
                currentStreak: 12,
                isCompletedToday: true,
                weeklyProgress: 0.9,
                createdAt: Date()
            )
        ]
        updateCache()
    }
}

// MARK: - Supporting Types
// EmptyResponse is now defined in SharedModels.swift 