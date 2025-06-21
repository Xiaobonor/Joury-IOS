//
//  SharedModels.swift
//  Joury
//
//  Shared data models used across the application
//

import Foundation

// MARK: - Shared Response Models

/// Empty response structure for API endpoints that don't return data
struct EmptyResponse: Codable {
    // Empty response for DELETE operations and similar endpoints
}

// MARK: - Habit Models

/// Unified Habit model used across the application
struct Habit: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var description: String
    var type: HabitType
    var targetValue: Int
    var currentStreak: Int
    var isCompletedToday: Bool
    var weeklyProgress: Double
    var lastCompleted: Date?
    var createdAt: Date
    
    var streakCount: Int { currentStreak }
    
    var isCompletedTodayComputed: Bool {
        guard let lastCompleted = lastCompleted else { return false }
        return Calendar.current.isDateInToday(lastCompleted)
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String = "",
        type: HabitType = .daily,
        targetValue: Int = 1,
        currentStreak: Int = 0,
        isCompletedToday: Bool = false,
        weeklyProgress: Double = 0.0,
        lastCompleted: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.targetValue = targetValue
        self.currentStreak = currentStreak
        self.isCompletedToday = isCompletedToday
        self.weeklyProgress = weeklyProgress
        self.lastCompleted = lastCompleted
        self.createdAt = createdAt
    }
}

/// Habit type enumeration
enum HabitType: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var localizedDisplayName: String {
        switch self {
        case .daily:
            return NSLocalizedString("habits.daily", comment: "")
        case .weekly:
            return NSLocalizedString("habits.weekly", comment: "")
        case .monthly:
            return NSLocalizedString("habits.monthly", comment: "")
        }
    }
}

/// Day data for weekly progress visualization
struct DayData: Identifiable {
    let id = UUID()
    let dayName: String
    let isCompleted: Bool
}

// MARK: - Request Models

/// Request model for creating a new habit
struct CreateHabitRequest: Codable {
    let name: String
    let description: String
    let type: String
    let targetValue: Int
}

// MARK: - Journal Types

/// Journal writing modes
enum JournalMode: CaseIterable {
    case traditional
    case interactive
    
    var title: String {
        switch self {
        case .traditional: return "journal.mode.traditional"
        case .interactive: return "journal.mode.interactive"
        }
    }
    
    var icon: String {
        switch self {
        case .traditional: return "square.and.pencil"
        case .interactive: return "bubble.left.and.bubble.right"
        }
    }
    
    var description: String {
        switch self {
        case .traditional: return "journal.mode.traditional.description"
        case .interactive: return "journal.mode.interactive.description"
        }
    }
} 