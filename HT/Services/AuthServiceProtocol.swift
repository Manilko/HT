//
//  AuthServiceProtocol.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation
import Combine

protocol AuthServiceProtocol: AnyObject {
  func signInWithGoogle() async throws
  func signInWithGitHub() async throws
  func refreshToken() async throws
  func logout() async throws
  func isAuthenticated() -> Bool
}

class MockAuthService: AuthServiceProtocol {
  func signInWithGoogle() async throws {
    // Mock implementation
  }

  func signInWithGitHub() async throws {
    // Mock implementation
  }

  func refreshToken() async throws {
    // Mock implementation
  }

  func logout() async throws {
    // Mock implementation
  }

  func isAuthenticated() -> Bool {
    false
  }
}
