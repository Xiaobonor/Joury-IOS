//
//  FocusViewModel.swift
//  Joury
//
//  View model for focus mode functionality including Pomodoro timer and focus rooms.
//

import Foundation
import Combine

@MainActor
class FocusViewModel: ObservableObject {
    // MARK: - Timer Properties
    @Published var isRunning = false
    @Published var timeRemaining: TimeInterval = 25 * 60 // 25 minutes
    @Published var currentPhase: FocusPhase = .work
    @Published var completedSessions = 0
    @Published var targetSessions = 4
    
    // MARK: - Room Properties
    @Published var focusRooms: [FocusRoom] = []
    @Published var currentRoom: FocusRoom?
    @Published var isConnectedToRoom = false
    
    // MARK: - Stats Properties
    @Published var todayStats = FocusStats(sessions: 0, minutes: 0)
    @Published var weeklyStats: [Int] = [25, 30, 20, 45, 35, 15, 40] // Mock data
    @Published var achievements: [Achievement] = []
    
    private var timer: Timer?
    private let totalWorkTime: TimeInterval = 25 * 60
    private let totalBreakTime: TimeInterval = 5 * 60
    private let totalLongBreakTime: TimeInterval = 15 * 60
    
    private let networkManager = NetworkManager.shared
    private let cacheManager = CacheManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var timerProgress: Double {
        let totalTime = currentPhase == .work ? totalWorkTime : 
                       (completedSessions % 4 == 3 ? totalLongBreakTime : totalBreakTime)
        return (totalTime - timeRemaining) / totalTime
    }
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    init() {
        loadAchievements()
        loadTodayStats()
        loadFocusRooms()
    }
    
    // MARK: - Timer Methods
    func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateTimer()
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = currentPhase == .work ? totalWorkTime : 
                       (completedSessions % 4 == 3 ? totalLongBreakTime : totalBreakTime)
    }
    
    func skipPhase() {
        pauseTimer()
        completeCurrentPhase()
    }
    
    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            completeCurrentPhase()
        }
    }
    
    private func completeCurrentPhase() {
        pauseTimer()
        
        if currentPhase == .work {
            completedSessions += 1
            todayStats.sessions += 1
            todayStats.minutes += 25
            
            // Determine break type
            if completedSessions % 4 == 0 {
                currentPhase = .longBreak
                timeRemaining = totalLongBreakTime
            } else {
                currentPhase = .shortBreak
                timeRemaining = totalBreakTime
            }
        } else {
            currentPhase = .work
            timeRemaining = totalWorkTime
        }
        
        // Send completion notification
        sendCompletionNotification()
        
        // Update achievements
        checkAchievements()
        
        // Cache updated stats
        saveStatsToCache()
    }
    
    private func sendCompletionNotification() {
        // TODO: Implement local notification
        print("Phase completed: \(currentPhase)")
    }
    
    // MARK: - Focus Rooms Methods
    func loadFocusRooms() {
        // Try to load from cache first
        if let cachedRooms: [FocusRoom] = cacheManager.getObject([FocusRoom].self, forKey: "focus_rooms") {
            focusRooms = cachedRooms
        }
        
        // Load mock data for now
        loadMockRooms()
        
        // TODO: Implement API call
        /*
        Task {
            do {
                            let rooms: [FocusRoom] = try await networkManager.request(
                endpoint: "/focus/rooms",
                method: .GET,
                responseType: [FocusRoom].self
            ).asyncValue()
                
                focusRooms = rooms
                cacheManager.setObject(rooms, forKey: "focus_rooms", expiration: .minutes(1))
            } catch {
                print("Failed to load focus rooms: \(error)")
            }
        }
        */
    }
    
    func joinRoom(_ room: FocusRoom) {
        currentRoom = room
        isConnectedToRoom = true
        
        // TODO: Implement WebSocket connection for real-time updates
        print("Joined room: \(room.name)")
    }
    
    func leaveRoom() {
        currentRoom = nil
        isConnectedToRoom = false
        
        // TODO: Implement WebSocket disconnection
        print("Left focus room")
    }
    
    func createRoom(name: String, description: String) {
        let newRoom = FocusRoom(
            id: UUID().uuidString,
            name: name,
            description: description,
            participantCount: 1,
            isActive: true,
            createdAt: Date()
        )
        
        focusRooms.append(newRoom)
        
        // TODO: Implement API call to create room
        /*
        Task {
            do {
                let createdRoom: FocusRoom = try await networkManager.request(
                    endpoint: "/focus/rooms",
                    method: .POST,
                    body: newRoom,
                    responseType: FocusRoom.self
                )
                
                // Update local state with server response
                if let index = focusRooms.firstIndex(where: { $0.id == newRoom.id }) {
                    focusRooms[index] = createdRoom
                }
                
                joinRoom(createdRoom)
            } catch {
                print("Failed to create room: \(error)")
            }
        }
        */
    }
    
    // MARK: - Stats and Achievements
    private func loadTodayStats() {
        if let cachedStats: FocusStats = cacheManager.getObject(FocusStats.self, forKey: "today_focus_stats") {
            todayStats = cachedStats
        }
    }
    
    private func saveStatsToCache() {
        cacheManager.setObject(todayStats, forKey: "today_focus_stats", expiration: .hours(24))
    }
    
    private func loadAchievements() {
        achievements = [
            Achievement(
                id: "first_session",
                title: "First Focus",
                description: "Complete your first focus session",
                icon: "star.fill",
                isUnlocked: todayStats.sessions > 0
            ),
            Achievement(
                id: "daily_goal",
                title: "Daily Hero",
                description: "Complete 4 sessions in one day",
                icon: "flame.fill",
                isUnlocked: todayStats.sessions >= 4
            ),
            Achievement(
                id: "focus_master",
                title: "Focus Master",
                description: "Complete 100 total sessions",
                icon: "crown.fill",
                isUnlocked: false // Would check total sessions from backend
            ),
            Achievement(
                id: "early_bird",
                title: "Early Bird",
                description: "Start a session before 8 AM",
                icon: "sunrise.fill",
                isUnlocked: false
            )
        ]
    }
    
    private func checkAchievements() {
        var hasNewAchievement = false
        
        for i in 0..<achievements.count {
            let oldStatus = achievements[i].isUnlocked
            
            switch achievements[i].id {
            case "first_session":
                achievements[i].isUnlocked = todayStats.sessions > 0
            case "daily_goal":
                achievements[i].isUnlocked = todayStats.sessions >= 4
            default:
                break
            }
            
            if !oldStatus && achievements[i].isUnlocked {
                hasNewAchievement = true
                showAchievementNotification(achievements[i])
            }
        }
    }
    
    private func showAchievementNotification(_ achievement: Achievement) {
        // TODO: Show achievement notification
        print("🏆 Achievement unlocked: \(achievement.title)")
    }
    
    // MARK: - Mock Data
    private func loadMockRooms() {
        focusRooms = [
            FocusRoom(
                id: "1",
                name: "Study Together",
                description: "Focused study session for students and professionals",
                participantCount: 12,
                isActive: true,
                createdAt: Date()
            ),
            FocusRoom(
                id: "2",
                name: "Morning Productivity",
                description: "Start your day with a productive work session",
                participantCount: 8,
                isActive: true,
                createdAt: Date()
            ),
            FocusRoom(
                id: "3",
                name: "Deep Work Zone",
                description: "For those who need intense focus and concentration",
                participantCount: 5,
                isActive: true,
                createdAt: Date()
            ),
            FocusRoom(
                id: "4",
                name: "Creative Flow",
                description: "Perfect for creative work and brainstorming",
                participantCount: 15,
                isActive: true,
                createdAt: Date()
            )
        ]
        
        cacheManager.setObject(focusRooms, forKey: "focus_rooms", expiration: .minutes(1))
    }
}

// MARK: - Supporting Types
enum FocusPhase {
    case work
    case shortBreak
    case longBreak
    
    var title: String {
        switch self {
        case .work: return "focus.workPhase".localized
        case .shortBreak: return "focus.shortBreak".localized
        case .longBreak: return "focus.longBreak".localized
        }
    }
}

struct FocusRoom: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let participantCount: Int
    let isActive: Bool
    let createdAt: Date
}

struct FocusStats: Codable {
    var sessions: Int
    var minutes: Int
}

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    var isUnlocked: Bool
} 