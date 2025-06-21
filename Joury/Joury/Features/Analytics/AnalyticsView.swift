//
//  AnalyticsView.swift
//  Joury
//
//  Analytics and insights view with mood trends, habit statistics, and AI-generated reports.
//

import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Selector
                    timeRangeSelector
                    
                    // Overview Cards
                    overviewSection
                    
                    // Mood Trends
                    moodTrendsSection
                    
                    // Habits Performance
                    habitsPerformanceSection
                    
                    // Journal Insights
                    journalInsightsSection
                    
                    // AI Weekly Report
                    if viewModel.weeklyReport != nil {
                        weeklyReportSection
                    }
                }
                .padding(.vertical, 20)
            }
            .background(themeManager.colors.background)
            .navigationTitle(localizationManager.string(for: "analytics.analytics"))
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.loadAnalytics(for: selectedTimeRange)
            }
            .onAppear {
                viewModel.loadAnalytics(for: selectedTimeRange)
            }
        }
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    selectedTimeRange = range
                    viewModel.loadAnalytics(for: range)
                }) {
                    Text(localizationManager.string(for: range.localizationKey))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeRange == range ? .white : themeManager.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTimeRange == range ? themeManager.colors.primary : Color.clear
                        )
                }
            }
        }
        .background(themeManager.colors.surface)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.string(for: "analytics.overview"))
                .font(.headline)
                .foregroundColor(themeManager.colors.textPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    HStack(spacing: 20) {
                        OverviewCardView(
                            titleKey: "analytics.journal_entries",
                            value: "\(viewModel.overview.journalEntries)",
                            subtitle: String(format: localizationManager.string(for: "analytics.overview.journal_subtitle"), 2),
                            icon: "book.fill",
                            color: themeManager.colors.primary
                        )
                        
                        OverviewCardView(
                            titleKey: "analytics.avg_mood",
                            value: String(format: "%.1f", viewModel.overview.averageMood),
                            subtitle: String(format: localizationManager.string(for: "analytics.overview.mood_subtitle"), "+0.3"),
                            icon: "heart.fill",
                            color: themeManager.colors.success
                        )
                        
                        OverviewCardView(
                            titleKey: "analytics.habits_completed",
                            value: "\(viewModel.overview.habitsCompleted)",
                            subtitle: String(format: localizationManager.string(for: "common.percent"), 85),
                            icon: "checkmark.circle.fill",
                            color: themeManager.colors.warning
                        )
                        
                        OverviewCardView(
                            titleKey: "analytics.focus_minutes",
                            value: "\(viewModel.overview.focusMinutes)",
                            subtitle: String(format: localizationManager.string(for: "analytics.overview.focus_subtitle"), "+15"),
                            icon: "timer.circle.fill",
                            color: themeManager.colors.info
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Mood Trends Section
    private var moodTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(localizationManager.string(for: "analytics.mood_trends"))
                    .font(.headline)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
                
                Button(action: { viewModel.showMoodDetails() }) {
                    Text(localizationManager.string(for: "analytics.see_details"))
                        .font(.caption)
                        .foregroundColor(themeManager.colors.primary)
                }
            }
            .padding(.horizontal, 20)
            
            MoodTrendChartView(data: viewModel.moodData, timeRange: selectedTimeRange)
                .frame(height: 200)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Habits Performance Section
    private var habitsPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(localizationManager.string(for: "analytics.habits_performance"))
                    .font(.headline)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
                
                Text(String(format: localizationManager.string(for: "analytics.percent_completed"), Int(viewModel.habitsCompletionRate * 100)))
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(viewModel.habitsPerformance) { habit in
                    HabitPerformanceRowView(habit: habit)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Journal Insights Section
    private var journalInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.string(for: "analytics.journal_insights"))
                .font(.headline)
                .foregroundColor(themeManager.colors.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                // Top Keywords
                InsightCardView(
                    titleKey: "analytics.top_keywords",
                    content: viewModel.topKeywords.joined(separator: " • "),
                    icon: "text.bubble.fill"
                )
                .padding(.horizontal, 20)
                
                // Emotional Insights
                InsightCardView(
                    titleKey: "analytics.emotional_insights",
                    content: viewModel.emotionalInsight,
                    icon: "brain.head.profile"
                )
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Weekly Report Section
    private var weeklyReportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.string(for: "analytics.weekly_report"))
                .font(.headline)
                .foregroundColor(themeManager.colors.textPrimary)
                .padding(.horizontal, 20)
            
            if let report = viewModel.weeklyReport {
                WeeklyReportCardView(report: report)
                    .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Time Range Enum
enum TimeRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    
    var localizationKey: String {
        switch self {
        case .week: return "analytics.week"
        case .month: return "analytics.month"
        case .quarter: return "analytics.quarter"
        }
    }
}

// MARK: - Overview Card View
struct OverviewCardView: View {
    let titleKey: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(localizationManager.string(for: titleKey))
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.colors.textPrimary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(themeManager.colors.textSecondary)
        }
        .padding(16)
        .frame(width: 160, height: 140)
        .background(themeManager.colors.surface)
        .cornerRadius(16)
        .shadow(color: themeManager.colors.shadow.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Mood Trend Chart View
struct MoodTrendChartView: View {
    let data: [MoodDataPoint]
    let timeRange: TimeRange
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            // Chart area (simplified line chart)
            ZStack {
                // Grid lines
                VStack {
                    ForEach(0..<5) { _ in
                        Rectangle()
                            .fill(themeManager.colors.textSecondary.opacity(0.2))
                            .frame(height: 1)
                        Spacer()
                    }
                }
                
                // Mood line
                if !data.isEmpty {
                    Path { path in
                        let points = data.enumerated().map { index, point in
                            CGPoint(
                                x: CGFloat(index) / CGFloat(data.count - 1),
                                y: 1.0 - (point.mood - 1.0) / 9.0
                            )
                        }
                        
                        if let firstPoint = points.first {
                            path.move(to: firstPoint)
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(themeManager.colors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .background(
                        Path { path in
                            let points = data.enumerated().map { index, point in
                                CGPoint(
                                    x: CGFloat(index) / CGFloat(data.count - 1),
                                    y: 1.0 - (point.mood - 1.0) / 9.0
                                )
                            }
                            
                            if let firstPoint = points.first {
                                path.move(to: CGPoint(x: firstPoint.x, y: 1.0))
                                path.addLine(to: firstPoint)
                                for point in points.dropFirst() {
                                    path.addLine(to: point)
                                }
                                if let lastPoint = points.last {
                                    path.addLine(to: CGPoint(x: lastPoint.x, y: 1.0))
                                }
                                path.closeSubpath()
                            }
                        }
                        .fill(
                            LinearGradient(
                                colors: [themeManager.colors.primary.opacity(0.3), themeManager.colors.primary.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    )
                }
            }
            .frame(height: 150)
            
            // X-axis labels
            HStack {
                ForEach(data.indices, id: \.self) { index in
                    if index % max(1, data.count / 4) == 0 {
                        Text(data[index].label)
                            .font(.caption2)
                            .foregroundColor(themeManager.colors.textSecondary)
                        
                        if index < data.count - 1 {
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(themeManager.colors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Habit Performance Row View
struct HabitPerformanceRowView: View {
    let habit: HabitPerformance
    
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        HStack {
            Text(habit.name)
                .font(.subheadline)
                .foregroundColor(themeManager.colors.textPrimary)
            
            Spacer()
            
            Text(String(format: localizationManager.string(for: "analytics.completed_days"), habit.completedDays, habit.totalDays))
                .font(.caption)
                .foregroundColor(themeManager.colors.textSecondary)
        }
    }
}

// MARK: - Insight Card View
struct InsightCardView: View {
    let titleKey: String
    let content: String
    let icon: String
    
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(themeManager.colors.primary)
                Text(localizationManager.string(for: titleKey))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.colors.textPrimary)
            }
            Text(content)
                .font(.body)
                .foregroundColor(themeManager.colors.textSecondary)
                .lineLimit(3)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Weekly Report Card View
struct WeeklyReportCardView: View {
    let report: WeeklyReport
    
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(report.title)
                .font(.headline)
                .foregroundColor(themeManager.colors.textPrimary)
            
            Text(report.dateRange)
                .font(.caption)
                .foregroundColor(themeManager.colors.textSecondary)
            
            Divider()
            
            Text(report.summary)
                .font(.body)
                .foregroundColor(themeManager.colors.textSecondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(report.highlights, id: \.self) { highlight in
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(themeManager.colors.warning)
                        Text(highlight)
                            .font(.subheadline)
                    }
                }
            }
            .foregroundColor(themeManager.colors.textPrimary)
            
            Divider()
            
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(themeManager.colors.primary)
                Text(localizationManager.string(for: "analytics.insights"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.colors.textPrimary)
            }
            
            Text(report.aiInsights)
                .font(.body)
                .foregroundColor(themeManager.colors.textSecondary)
        }
        .padding()
        .background(themeManager.colors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    AnalyticsView()
        .environmentObject(ThemeManager())
} 