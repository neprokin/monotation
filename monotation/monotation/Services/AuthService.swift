//
//  AuthService.swift
//  monotation
//
//  Authentication service (simplified for CloudKit)
//  Note: CloudKit uses iCloud account automatically, so authentication is not required.
//  This service is kept for potential future Apple Sign In integration.
//

import Foundation
import UIKit
import Combine
import AuthenticationServices

@MainActor
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private override init() {
        super.init()
        // CloudKit uses iCloud account automatically, so user is always "authenticated"
        isAuthenticated = true
    }
    
    // MARK: - Apple Sign In (Future Implementation)
    
    // TODO: Complete Apple Sign In implementation if needed in the future
    // For now, CloudKit uses iCloud account automatically
    func signInWithApple() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // CloudKit doesn't require explicit sign in
        // iCloud account is used automatically
        isAuthenticated = true
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        // CloudKit doesn't support sign out
        // User data is tied to iCloud account
        isAuthenticated = false
    }
    
    // MARK: - Get Current User ID
    
    var currentUserId: String? {
        // CloudKit uses iCloud account automatically
        // Return nil as CloudKit handles user identification internally
        nil
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

