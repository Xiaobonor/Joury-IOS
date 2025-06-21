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
            MoodDataPoint(date: Date().addingTimeInterval(-6*24*60*60), mood: 6.5, label: NSLocalizedString("weekday.monday", comment: "")),
            MoodDataPoint(date: Date().addingTimeInterval(-5*24*60*60), mood: 7.2, label: NSLocalizedString("weekday.tuesday", comment: "")),
            MoodDataPoint(date: Date().addingTimeInterval(-4*24*60*60), mood: 5.8, label: NSLocalizedString("weekday.wednesday", comment: "")),
            MoodDataPoint(date: Date().addingTimeInterval(-3*24*60*60), mood: 8.1, label: NSLocalizedString("weekday.thursday", comment: "")),
            MoodDataPoint(date: Date().addingTimeInterval(-2*24*60*60), mood: 7.5, label: NSLocalizedString("weekday.friday", comment: "")),
            MoodDataPoint(date: Date().addingTimeInterval(-1*24*60*60), mood: 6.9, label: NSLocalizedString("weekday.saturday", comment: "")),
            MoodDataPoint(date: Date(), mood: 7.8, label: NSLocalizedString("weekday.sunday", comment: ""))
        ]
        
        // Mock habits performance
        habitsPerformance = [
            HabitPerformance(
                id: "1",
                name: NSLocalizedString("analytics.habit.morning_exercise", comment: ""),
                completedDays: 5,
                totalDays: 7,
                completionRate: 0.71
            ),
            HabitPerformance(
                id: "2",
                name: NSLocalizedString("analytics.habit.daily_reading", comment: ""),
                completedDays: 6,
                totalDays: 7,
                completionRate: 0.86
            ),
            HabitPerformance(
                id: "3",
                name: NSLocalizedString("analytics.habit.meditation", comment: ""),
                completedDays: 4,
                totalDays: 7,
                completionRate: 0.57
            ),
            HabitPerformance(
                id: "4",
                name: NSLocalizedString("analytics.habit.journal_writing", comment: ""),
                completedDays: 7,
                totalDays: 7,
                completionRate: 1.0
            )
        ]
        
        // Calculate habits completion rate
        habitsCompletionRate = habitsPerformance.map { $0.completionRate }.reduce(0, +) / Double(habitsPerformance.count)
        
        // Mock insights
        topKeywords = [
            NSLocalizedString("keyword.work", comment: ""),
            NSLocalizedString("keyword.exercise", comment: ""),
            NSLocalizedString("keyword.family", comment: ""),
            NSLocalizedString("keyword.reading", comment: ""),
            NSLocalizedString("keyword.grateful", comment: "")
        ]
        emotionalInsight = NSLocalizedString("analytics.emotional_insight_sample", comment: "")
        
        // Mock weekly report
        weeklyReport = WeeklyReport(
            title: NSLocalizedString("analytics.weekly_report_title", comment: ""),
            dateRange: NSLocalizedString("analytics.weekly_report_date", comment: ""),
            summary: NSLocalizedString("analytics.weekly_report_summary", comment: ""),
            highlights: [
                NSLocalizedString("analytics.highlight.journal_completion", comment: ""),
                NSLocalizedString("analytics.highlight.habit_consistency", comment: ""),
                NSLocalizedString("analytics.highlight.mood_trend", comment: "")
            ],
            aiInsights: NSLocalizedString("analytics.ai_insights_sample", comment: ""),
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