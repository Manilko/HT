//
//  AuthViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let authService: AuthServiceProtocol

  init(authService: AuthServiceProtocol) {
    self.authService = authService
  }

  func signInWithGoogle() async {
    // Implementation coming soon
  }

  func signInWithGitHub() async {
    // Implementation coming soon
  }

  func refreshToken() async {
    // Implementation coming soon
  }

  func logout() async {
    // Implementation coming soon
  }
}
