//
//  AuthService.swift
//  monotation
//
//  Authentication service with Apple Sign In
//

import Foundation
import UIKit
import Combine
import AuthenticationServices
import Supabase

@MainActor
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    // MARK: - Published Properties
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let supabaseService = SupabaseService.shared
    
    private override init() {
        super.init()
        checkAuthState()
    }
    
    // MARK: - Check Auth State
    
    func checkAuthState() {
        Task {
            let isAvailable = await supabaseService.isAvailable
            if isAvailable,
               let authClient = await supabaseService.authClient {
                do {
                    let session = try await authClient.session
                    await updateUser(from: session.user)
                } catch {
                    // No session - user not logged in
                    isAuthenticated = false
                    currentUser = nil
                }
            } else {
                // Supabase not configured, use mock auth
                isAuthenticated = false
                currentUser = nil
            }
        }
    }
    
    // MARK: - Apple Sign In
    
    // TODO: Complete Apple Sign In implementation
    // - Create AuthView for UI
    // - Complete delegate setup
    // - Configure Apple Sign In in Supabase (see SUPABASE_SETUP.md Step 5)
    func signInWithApple() async throws {
        let isAvailable = await supabaseService.isAvailable
        guard isAvailable else {
            // Mock sign in for development
            await mockSignIn()
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Request Apple ID credential
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            // Perform authorization
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            
            // This will be handled in delegate methods
            // For now, we'll use a simplified approach
            throw AuthError.notImplemented("Apple Sign In delegate setup needed")
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        let isAvailable = await supabaseService.isAvailable
        guard isAvailable else {
            // Mock sign out
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        do {
            guard let authClient = await supabaseService.authClient else {
                isAuthenticated = false
                currentUser = nil
                return
            }
            
            try await authClient.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Get Current User ID
    
    var currentUserId: String? {
        currentUser?.id.uuidString
    }
    
    // MARK: - Helper Methods
    
    private func updateUser(from user: User) async {
        currentUser = user
        isAuthenticated = true
    }
    
    private func mockSignIn() async {
        // Mock user for development when Supabase not configured
        // Create a simple mock user - we'll use a basic structure
        // Note: This is a temporary solution until Supabase is configured
        isAuthenticated = true
        // currentUser will be nil for mock mode, but isAuthenticated = true allows app to work
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            Task {
                do {
                    // Get identity token
                    guard let identityToken = appleIDCredential.identityToken,
                          let idTokenString = String(data: identityToken, encoding: .utf8) else {
                        throw AuthError.invalidToken
                    }
                    
                    // Sign in with Supabase
                    guard let authClient = await supabaseService.authClient else {
                        throw AuthError.signInFailed(NSError(domain: "AuthService", code: -1))
                    }
                    
                    let session = try await authClient.signInWithIdToken(
                        credentials: .init(
                            provider: .apple,
                            idToken: idTokenString
                        )
                    )
                    
                    await updateUser(from: session.user)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the main window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case notImplemented(String)
    case invalidToken
    case signInFailed(Error)
    case signOutFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notImplemented(let message):
            return "Не реализовано: \(message)"
        case .invalidToken:
            return "Неверный токен авторизации"
        case .signInFailed(let error):
            return "Ошибка входа: \(error.localizedDescription)"
        case .signOutFailed(let error):
            return "Ошибка выхода: \(error.localizedDescription)"
        }
    }
}

