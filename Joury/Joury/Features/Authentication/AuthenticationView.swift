import SwiftUI
import GoogleSignIn

// MARK: - Authentication View
struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        themeManager.colors.primary.opacity(0.1),
                        themeManager.colors.secondary.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App Logo and Title
                    VStack(spacing: 20) {
                        // Logo placeholder
                        Circle()
                            .fill(themeManager.colors.primary)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text("J")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: themeManager.colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Text("general.app_name".localized)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.colors.textPrimary)
                            
                            Text("welcome_subtitle".localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    Spacer()
                    
                    // Authentication Options
                    VStack(spacing: 16) {
                        // Google Sign In Button
                        Button(action: {
                            Task {
                                await signInWithGoogle()
                            }
                        }) {
                            HStack(spacing: 12) {
                                // Google logo placeholder
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text("G")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.blue)
                                    )
                                
                                Text("auth.sign_in_with_google".localized)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading)
                        .scaleEffect(isLoading ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isLoading)
                        
                        // Guest Sign In Button
                        Button(action: {
                            Task {
                                await signInAsGuest()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(themeManager.colors.primary)
                                
                                Text("auth.continue_as_guest".localized)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(themeManager.colors.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeManager.colors.primary, lineWidth: 2)
                                    .fill(themeManager.colors.background)
                            )
                        }
                        .disabled(isLoading)
                        .scaleEffect(isLoading ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isLoading)
                    }
                    .padding(.horizontal, 32)
                    
                    // Loading indicator
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("general.loading".localized)
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.colors.textSecondary)
                        }
                        .padding(.top, 16)
                    }
                    
                    Spacer()
                    
                    // Privacy notice
                    Text("privacy_notice".localized)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                }
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("general.ok".localized) {
                showErrorAlert = false
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .onReceive(authManager.$authState) { state in
            switch state {
            case .loading:
                isLoading = true
            case .authenticated, .unauthenticated:
                isLoading = false
            case .error(let error):
                isLoading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func signInWithGoogle() async {
        isLoading = true
        do {
            try await authManager.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        isLoading = false
    }
    
    private func signInAsGuest() async {
        isLoading = true
        do {
            try await authManager.signInAsGuest()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        isLoading = false
    }
}

// MARK: - Preview
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(ThemeManager())
            .environmentObject(LocalizationManager())
    }
} 
