//
//  AuthenticationViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
  @Published var isLoading = false
  @Published var isAuthenticated = false
  @Published var errorMessage: String?

  private let authManager: AuthenticationManager

  init(authManager: AuthenticationManager = .shared) {
    self.authManager = authManager
    self.isAuthenticated = authManager.isAuthenticated()
  }

  func signInWithGoogle() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      try await authManager.signInWithGoogle()
      await MainActor.run {
        self.isAuthenticated = true
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func signInWithGitHub() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      try await authManager.signInWithGitHub()
      await MainActor.run {
        self.isAuthenticated = true
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
