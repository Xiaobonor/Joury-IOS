//
//  JournalViewModel.swift
//  Joury
//
//  ViewModel for managing journal state and AI interactions.
//

import Foundation
import Combine

@MainActor
class JournalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var messages: [JournalMessage] = []
    @Published var isLoading = false
    @Published var currentMoodScore: Double?
    @Published var extractedTasks: [String] = []
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private let cacheManager = CacheManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentJournalId: String?
    
    // MARK: - Public Methods
    
    /// Load today's journal entry
    func loadTodayJournal() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let today = Date().toDateString()
            let journal = try await fetchOrCreateJournal(for: today)
            
            currentJournalId = journal.id
            messages = journal.messages
            currentMoodScore = journal.latestMoodScore
            extractedTasks = journal.extractedTasks
            
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load today's journal: \(error)")
        }
        
        isLoading = false
    }
    
    /// Send a message to the AI and handle the response
    func sendMessage(_ content: String) async {
        guard let journalId = currentJournalId else {
            errorMessage = "No active journal session"
            return
        }
        
        // Add user message immediately
        let userMessage = JournalMessage(
            id: UUID().uuidString,
            content: content,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        do {
            // Send message to API
            let response = try await sendMessageToAPI(
                journalId: journalId,
                content: content
            )
            
            // Add AI response
            let aiMessage = JournalMessage(
                id: response.messageId,
                content: response.aiResponse,
                isFromUser: false,
                timestamp: Date()
            )
            messages.append(aiMessage)
            
            // Update mood and tasks if provided
            if let mood = response.moodAnalysis {
                currentMoodScore = mood.moodScore
            }
            
            if !response.extractedTasks.isEmpty {
                extractedTasks.append(contentsOf: response.extractedTasks)
            }
            
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to send message: \(error)")
            
            // Add fallback response
            let fallbackMessage = JournalMessage(
                id: UUID().uuidString,
                content: "I'm sorry, I'm having trouble responding right now. Please try again.",
                isFromUser: false,
                timestamp: Date()
            )
            messages.append(fallbackMessage)
        }
    }
    
    /// Get reflection questions for the user
    func getReflectionQuestions() async -> [String] {
        do {
            let questions = try await fetchReflectionQuestions()
            return questions
        } catch {
            print("Failed to fetch reflection questions: \(error)")
            return [
                "How are you feeling right now?",
                "What's been on your mind today?",
                "What are you grateful for?",
                "What would you like to focus on?"
            ]
        }
    }
    
    /// Clear current session (for testing or logout)
    func clearSession() {
        messages.removeAll()
        currentJournalId = nil
        currentMoodScore = nil
        extractedTasks.removeAll()
        errorMessage = nil
    }
}

// MARK: - Private API Methods
private extension JournalViewModel {
    
    func fetchOrCreateJournal(for date: String) async throws -> JournalResponse {
        let endpoint = "journals/today"
        
        // Try to get from cache first
        if let cached = cacheManager.getObject(JournalResponse.self, forKey: "journal_\(date)") {
            return cached
        }
        
        let response: JournalResponse = try await networkManager.request(
            endpoint: endpoint,
            method: .GET,
            responseType: JournalResponse.self
        ).asyncValue()
        
        // Cache the response
        cacheManager.setObject(response, forKey: "journal_\(date)", expiration: .seconds(300))
        
        return response
    }
    
    func sendMessageToAPI(journalId: String, content: String) async throws -> MessageResponse {
        let endpoint = "journals/\(journalId)/messages"
        let body = MessageRequest(content: content)
        
        let response: MessageResponse = try await networkManager.request(
            endpoint: endpoint,
            method: .POST,
            body: body,
            responseType: MessageResponse.self
        ).asyncValue()
        
        return response
    }
    
    func fetchReflectionQuestions() async throws -> [String] {
        let endpoint = "journals/reflection-questions"
        
        let response: ReflectionQuestionsResponse = try await networkManager.request(
            endpoint: endpoint,
            method: .GET,
            responseType: ReflectionQuestionsResponse.self
        ).asyncValue()
        
        return response.questions
    }
}

// MARK: - Data Models

struct JournalMessage: Identifiable, Codable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

struct JournalResponse: Codable {
    let id: String
    let date: String
    let messages: [JournalMessage]
    let latestMoodScore: Double?
    let extractedTasks: [String]
    let createdAt: String
    let updatedAt: String
}

struct MessageRequest: Codable {
    let content: String
}

struct MessageResponse: Codable {
    let messageId: String
    let aiResponse: String
    let moodAnalysis: MoodAnalysisResponse?
    let extractedTasks: [String]
    let followUpQuestions: [String]
}

struct MoodAnalysisResponse: Codable {
    let moodScore: Double
    let primaryEmotion: String
    let confidence: Double
    let moodTags: [String]
}

struct ReflectionQuestionsResponse: Codable {
    let questions: [String]
}

// MARK: - Helper Extensions

extension Date {
    func toDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
} 