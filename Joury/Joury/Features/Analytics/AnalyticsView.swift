//
//  AnalyticsView.swift
//  Joury
//
//  Analytics and insights view with mood trends, habit statistics, and AI-generated reports.
//

import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
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
            .navigationTitle("analytics.analytics".localized)
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
                    Text(range.title)
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
            Text("analytics.overview".localized)
                .font(.headline)
                .foregroundColor(themeManager.colors.textPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    OverviewCardView(
                        title: "analytics.journalEntries".localized,
                        value: "\(viewModel.overview.journalEntries)",
                        change: viewModel.overview.journalEntriesChange,
                        icon: "book.fill",
                        color: themeManager.colors.primary
                    )
                    
                    OverviewCardView(
                        title: "analytics.avgMood".localized,
                        value: String(format: "%.1f", viewModel.overview.averageMood),
                        change: viewModel.overview.moodChange,
                        icon: "heart.fill",
                        color: themeManager.colors.warning
                    )
                    
                    OverviewCardView(
                        title: "analytics.habitsCompleted".localized,
                        value: "\(viewModel.overview.habitsCompleted)",
                        change: viewModel.overview.habitsChange,
                        icon: "checkmark.circle.fill",
                        color: themeManager.colors.success
                    )
                    
                    OverviewCardView(
                        title: "analytics.focusMinutes".localized,
                        value: "\(viewModel.overview.focusMinutes)",
                        change: viewModel.overview.focusChange,
                        icon: "timer.circle.fill",
                        color: themeManager.colors.secondary
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Mood Trends Section
    private var moodTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("analytics.moodTrends".localized)
                    .font(.headline)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
                
                Button(action: { viewModel.showMoodDetails() }) {
                    Text("analytics.seeDetails".localized)
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
                Text("analytics.habitsPerformance".localized)
                    .font(.headline)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
                
                Text("\(Int(viewModel.habitsCompletionRate * 100))% completed")
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
            Text("analytics.journalInsights".localized)
                .font(.headline)
                .foregroundColor(themeManager.colors.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                // Top Keywords
                InsightCardView(
                    title: "analytics.topKeywords".localized,
                    content: viewModel.topKeywords.joined(separator: " • "),
                    icon: "text.bubble.fill"
                )
                .padding(.horizontal, 20)
                
                // Emotional Insights
                InsightCardView(
                    title: "analytics.emotionalInsights".localized,
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
            Text("analytics.weeklyReport".localized)
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
    
    var title: String {
        switch self {
        case .week: return "analytics.week".localized
        case .month: return "analytics.month".localized
        case .quarter: return "analytics.quarter".localized
        }
    }
}

// MARK: - Overview Card View
struct OverviewCardView: View {
    let title: String
    let value: String
    let change: Double
    let icon: String
    let color: Color
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                    
                    Text("\(abs(change), specifier: "%.1f")%")
                        .font(.caption)
                }
                .foregroundColor(change >= 0 ? themeManager.colors.success : themeManager.colors.error)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
            }
        }
        .padding(16)
        .frame(width: 140, height: 100)
        .background(themeManager.colors.surface)
        .cornerRadius(12)
        .shadow(color: themeManager.colors.textPrimary.opacity(0.1), radius: 2, x: 0, y: 1)
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Text("\(habit.completedDays)/\(habit.totalDays) days")
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(habit.completionRate * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                ProgressView(value: habit.completionRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.colors.primary))
                    .frame(width: 60)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
        .padding(12)
        .background(themeManager.colors.surface)
        .cornerRadius(8)
    }
}

// MARK: - Insight Card View
struct InsightCardView: View {
    let title: String
    let content: String
    let icon: String
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(themeManager.colors.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Text(content)
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .background(themeManager.colors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Weekly Report Card View
struct WeeklyReportCardView: View {
    let report: WeeklyReport
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.title)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    Text(report.dateRange)
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textSecondary)
                }
                
                Spacer()
                
                Button(action: { /* Open detailed report */ }) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(themeManager.colors.primary)
                }
            }
            
            Text(report.summary)
                .font(.subheadline)
                .foregroundColor(themeManager.colors.textPrimary)
                .lineLimit(4)
            
            HStack {
                ForEach(report.highlights, id: \.self) { highlight in
                    Text("• \(highlight)")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textSecondary)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [themeManager.colors.primary.opacity(0.1), themeManager.colors.secondary.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.colors.primary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    AnalyticsView()
        .environmentObject(ThemeManager())
} 