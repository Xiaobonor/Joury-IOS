//
//  AnalyticsViewModel.swift
//  Joury
//
//  View model for analytics functionality including mood trends, habit statistics, and AI insights.
//

import Foundation
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var overview = AnalyticsOverview()
    @Published var moodData: [MoodDataPoint] = []
    @Published var habitsPerformance: [HabitPerformance] = []
    @Published var habitsCompletionRate: Double = 0.0
    @Published var topKeywords: [String] = []
    @Published var emotionalInsight: String = ""
    @Published var weeklyReport: WeeklyReport?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    private let cacheManager = CacheManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadMockData()
    }
    
    // MARK: - Public Methods
    func loadAnalytics(for timeRange: TimeRange) {
        isLoading = true
        errorMessage = nil
        
        // Try to load from cache first
        if let cachedData: AnalyticsData = cacheManager.getObject(AnalyticsData.self, forKey: "analytics_\(timeRange.rawValue)") {
            updateUI(with: cachedData)
            isLoading = false
        }
        
        // Then fetch from API
        Task {
            do {
                let analyticsData: AnalyticsData = try await networkManager.request(
                    endpoint: "/analytics",
                    method: .GET,
                    parameters: ["timeRange": timeRange.rawValue],
                    responseType: AnalyticsData.self
                ).asyncValue()
                
                await MainActor.run {
                    updateUI(with: analyticsData)
                    isLoading = false
                    
                    // Cache the results
                    cacheManager.setObject(analyticsData, forKey: "analytics_\(timeRange.rawValue)", expiration: .minutes(5))
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    
                    // If API fails, use mock data
                    loadMockData()
                }
            }
        }
    }
    
    func showMoodDetails() {
        // TODO: Navigate to detailed mood analysis
        print("Show mood details")
    }
    
    func generateWeeklyReport() {
        Task {
            do {
                let report: WeeklyReport = try await networkManager.request(
                    endpoint: "/analytics/weekly-report",
                    method: .POST,
                    responseType: WeeklyReport.self
                ).asyncValue()
                
                await MainActor.run {
                    weeklyReport = report
                    cacheManager.setObject(report, forKey: "weekly_report", expiration: .hours(24))
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func updateUI(with data: AnalyticsData) {
        overview = data.overview
        moodData = data.moodData
        habitsPerformance = data.habitsPerformance
        topKeywords = data.topKeywords
        emotionalInsight = data.emotionalInsight
        weeklyReport = data.weeklyReport
        
        // Calculate habits completion rate
        if !habitsPerformance.isEmpty {
            habitsCompletionRate = habitsPerformance.map { $0.completionRate }.reduce(0, +) / Double(habitsPerformance.count)
        }
    }
    
    private func loadMockData() {
        // Mock overview data
        overview = AnalyticsOverview(
            journalEntries: 18,
            journalEntriesChange: 12.5,
            averageMood: 7.2,
            moodChange: -2.1,
            habitsCompleted: 85,
            habitsChange: 8.3,
            focusMinutes: 325,
            focusChange: 15.2
        )
        
        // Mock mood data
        moodData = [
            MoodDataPoint(date: Date().addingTimeInterval(-6*24*60*60), mood: 6.5, label: "Mon"),
            MoodDataPoint(date: Date().addingTimeInterval(-5*24*60*60), mood: 7.2, label: "Tue"),
            MoodDataPoint(date: Date().addingTimeInterval(-4*24*60*60), mood: 5.8, label: "Wed"),
            MoodDataPoint(date: Date().addingTimeInterval(-3*24*60*60), mood: 8.1, label: "Thu"),
            MoodDataPoint(date: Date().addingTimeInterval(-2*24*60*60), mood: 7.5, label: "Fri"),
            MoodDataPoint(date: Date().addingTimeInterval(-1*24*60*60), mood: 6.9, label: "Sat"),
            MoodDataPoint(date: Date(), mood: 7.8, label: "Sun")
        ]
        
        // Mock habits performance
        habitsPerformance = [
            HabitPerformance(
                id: "1",
                name: "Morning Exercise",
                completedDays: 5,
                totalDays: 7,
                completionRate: 0.71
            ),
            HabitPerformance(
                id: "2",
                name: "Daily Reading",
                completedDays: 6,
                totalDays: 7,
                completionRate: 0.86
            ),
            HabitPerformance(
                id: "3",
                name: "Meditation",
                completedDays: 4,
                totalDays: 7,
                completionRate: 0.57
            ),
            HabitPerformance(
                id: "4",
                name: "Journal Writing",
                completedDays: 7,
                totalDays: 7,
                completionRate: 1.0
            )
        ]
        
        // Calculate habits completion rate
        habitsCompletionRate = habitsPerformance.map { $0.completionRate }.reduce(0, +) / Double(habitsPerformance.count)
        
        // Mock insights
        topKeywords = ["work", "exercise", "family", "reading", "grateful"]
        emotionalInsight = "This week showed a generally positive emotional trend with some midweek stress. Your mood improved significantly toward the weekend, likely due to consistent exercise and quality time with family."
        
        // Mock weekly report
        weeklyReport = WeeklyReport(
            title: "Week 42 Personal Growth Report",
            dateRange: "Oct 16 - Oct 22, 2024",
            summary: "This week demonstrated strong commitment to personal growth with notable improvements in habit consistency and emotional well-being. Your journaling practice has been particularly insightful, revealing patterns of growth and self-awareness.",
            highlights: [
                "100% journal completion",
                "86% habit consistency",
                "Mood trend: Positive ↗️"
            ],
            aiInsights: "Your consistent morning routine appears to be a key factor in maintaining positive mood levels. Consider exploring meditation techniques to handle midweek stress more effectively.",
            generatedAt: Date()
        )
        
        // Cache mock data
        let mockData = AnalyticsData(
            overview: overview,
            moodData: moodData,
            habitsPerformance: habitsPerformance,
            topKeywords: topKeywords,
            emotionalInsight: emotionalInsight,
            weeklyReport: weeklyReport
        )
        
        cacheManager.setObject(mockData, forKey: "analytics_week", expiration: .minutes(5))
    }
}

// MARK: - Supporting Data Models
struct AnalyticsOverview: Codable {
    let journalEntries: Int
    let journalEntriesChange: Double
    let averageMood: Double
    let moodChange: Double
    let habitsCompleted: Int
    let habitsChange: Double
    let focusMinutes: Int
    let focusChange: Double
    
    init(
        journalEntries: Int = 0,
        journalEntriesChange: Double = 0.0,
        averageMood: Double = 0.0,
        moodChange: Double = 0.0,
        habitsCompleted: Int = 0,
        habitsChange: Double = 0.0,
        focusMinutes: Int = 0,
        focusChange: Double = 0.0
    ) {
        self.journalEntries = journalEntries
        self.journalEntriesChange = journalEntriesChange
        self.averageMood = averageMood
        self.moodChange = moodChange
        self.habitsCompleted = habitsCompleted
        self.habitsChange = habitsChange
        self.focusMinutes = focusMinutes
        self.focusChange = focusChange
    }
}

struct MoodDataPoint: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let mood: Double
    let label: String
    
    enum CodingKeys: String, CodingKey {
        case date, mood, label
    }
}

struct HabitPerformance: Identifiable, Codable {
    let id: String
    let name: String
    let completedDays: Int
    let totalDays: Int
    let completionRate: Double
}

struct WeeklyReport: Identifiable, Codable {
    let id = UUID()
    let title: String
    let dateRange: String
    let summary: String
    let highlights: [String]
    let aiInsights: String
    let generatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case title, dateRange, summary, highlights, aiInsights, generatedAt
    }
}

struct AnalyticsData: Codable {
    let overview: AnalyticsOverview
    let moodData: [MoodDataPoint]
    let habitsPerformance: [HabitPerformance]
    let topKeywords: [String]
    let emotionalInsight: String
    let weeklyReport: WeeklyReport?
} 