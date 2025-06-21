//
//  ProfileViewModel.swift
//  Joury
//
//  ViewModel for Profile view
//

import SwiftUI
import Combine
import UIKit
import StoreKit
import MessageUI

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var profileImage: UIImage?
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var journalCount: Int = 0
    @Published var currentStreak: Int = 0
    @Published var habitsCompleted: Int = 0
    @Published var showingSettings: Bool = false
    @Published var showingSignOutAlert: Bool = false
    @Published var showingImagePicker: Bool = false
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let authManager = AuthenticationManager.shared
    
    // MARK: - Computed Properties
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var currentLanguageDisplayName: String {
        let locale = Locale.current
        let language = Locale.preferredLanguages.first ?? "en"
        return locale.localizedString(forLanguageCode: String(language.prefix(2))) ?? "English"
    }
    
    // MARK: - Initialization
    init() {
        setupObservers()
        loadProfileData()
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Observe authentication state changes
        authManager.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authState in
                self?.updateUserInfo(from: authState)
            }
            .store(in: &cancellables)
    }
    
    private func updateUserInfo(from authState: AuthenticationState) {
        switch authState {
        case .authenticated(let user):
            userName = user.name 
            userEmail = user.email
            loadUserProfileImage()
        case .unauthenticated:
            userName = NSLocalizedString("common.guest", comment: "")
            userEmail = NSLocalizedString("common.guest_email", comment: "")
            profileImage = nil
        case .loading:
            break
        case .error:
            userName = ""
            userEmail = ""
            profileImage = nil
        }
    }
    
    private func loadUserProfileImage() {
        // Load profile image from local storage or remote source
        // TODO: Implement profile image loading
    }
    
    // MARK: - Public Methods
    func loadProfileData() {
        isLoading = true
        
        // Update user info based on current auth state
        updateUserInfo(from: authManager.authState)
        
        // Load statistics from local storage or API
        loadStatistics()
        
        isLoading = false
    }
    
    private func loadStatistics() {
        // TODO: Load actual statistics from data sources
        // For now, using mock data
        journalCount = UserDefaults.standard.integer(forKey: "journal_count")
        currentStreak = UserDefaults.standard.integer(forKey: "current_streak")
        habitsCompleted = UserDefaults.standard.integer(forKey: "habits_completed")
        
        // If no data exists, set some default values
        if journalCount == 0 && currentStreak == 0 && habitsCompleted == 0 {
            journalCount = 5
            currentStreak = 3
            habitsCompleted = 12
        }
    }
    
    func signOut() async {
        await authManager.signOut()
    }
    
    func rateApp() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        
        SKStoreReviewController.requestReview(in: scene)
    }
    
    func sendFeedback() {
        let email = "support@joury.app"
        let subject = "Joury App Feedback"
        let body = """
        
        ---
        App Version: \(appVersion)
        Device: \(UIDevice.current.model)
        iOS Version: \(UIDevice.current.systemVersion)
        ---
        """
        
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.setToRecipients([email])
            mailComposer.setSubject(subject)
            mailComposer.setMessageBody(body, isHTML: false)
            
            // Present mail composer
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
               let rootViewController = keyWindow.rootViewController {
                rootViewController.present(mailComposer, animated: true)
            }
        } else {
            // Open default mail app
            let mailURL = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            
            if let url = URL(string: mailURL) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func showPrivacyPolicy() {
        let urlString = "https://joury.app/privacy"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    func showTermsOfService() {
        let urlString = "https://joury.app/terms"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    func updateProfileImage(_ image: UIImage) {
        profileImage = image
        
        // Save to local storage
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: "profile_image")
        }
        
        // TODO: Upload to server if authenticated
    }
    
    func removeProfileImage() {
        profileImage = nil
        UserDefaults.standard.removeObject(forKey: "profile_image")
        
        // TODO: Remove from server if authenticated
    }
}


