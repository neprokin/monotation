//
//  AuthService.swift
//  monotation
//
//  Authentication service with Apple Sign In
//

import Foundation
import UIKit
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
            do {
                if supabaseService.isAvailable,
                   let authClient = await supabaseService.authClient {
                    let session = try await authClient.session
                    if let session = session {
                        await updateUser(from: session.user)
                    } else {
                        isAuthenticated = false
                        currentUser = nil
                    }
                } else {
                    // Supabase not configured, use mock auth
                    isAuthenticated = false
                    currentUser = nil
                }
            } catch {
                print("❌ AuthService.checkAuthState error: \(error)")
                isAuthenticated = false
                currentUser = nil
            }
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple() async throws {
        guard supabaseService.isAvailable else {
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
        guard supabaseService.isAvailable else {
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
        currentUser = User(
            id: UUID(),
            email: "mock@example.com",
            createdAt: Date()
        )
        isAuthenticated = true
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
                    
                    if let session = session {
                        await updateUser(from: session.user)
                    }
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

