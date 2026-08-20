//
//  UserServiceProtocol.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

protocol UserServiceProtocol: AnyObject {
  func fetchCurrentUser() async throws -> User
  func updateTimezone(_ timezone: String) async throws -> User
  func updateProfile(displayName: String) async throws -> User
  func deleteAccount() async throws
}

class MockUserService: UserServiceProtocol {
  func fetchCurrentUser() async throws -> User {
    throw NSError(domain: "mock", code: 0)
  }

  func updateTimezone(_ timezone: String) async throws -> User {
    throw NSError(domain: "mock", code: 0)
  }

  func updateProfile(displayName: String) async throws -> User {
    throw NSError(domain: "mock", code: 0)
  }

  func deleteAccount() async throws {
    // Mock
  }
}
