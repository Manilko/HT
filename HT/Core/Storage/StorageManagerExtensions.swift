//
//  StorageManagerExtensions.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

extension StorageManager {
  private enum StorageKeys {
    static let accessToken = "accessToken"
    static let refreshToken = "refreshToken"
    static let userId = "userId"
    static let userEmail = "userEmail"
    static let userName = "userName"
  }

  // MARK: - Token Management

  func getAccessToken() -> String? {
    getFromKeychain(key: StorageKeys.accessToken)
  }

  func saveAccessToken(_ token: String) {
    saveToKeychain(key: StorageKeys.accessToken, value: token)
  }

  func clearAccessToken() {
    deleteFromKeychain(key: StorageKeys.accessToken)
  }

  func getRefreshToken() -> String? {
    getFromKeychain(key: StorageKeys.refreshToken)
  }

  func saveRefreshToken(_ token: String) {
    saveToKeychain(key: StorageKeys.refreshToken, value: token)
  }

  func clearRefreshToken() {
    deleteFromKeychain(key: StorageKeys.refreshToken)
  }

  // MARK: - User Data

  func getUserId() -> Int? {
    guard let userId = UserDefaults.standard.value(forKey: StorageKeys.userId) as? Int else {
      return nil
    }
    return userId
  }

  func saveUserId(_ id: Int) {
    UserDefaults.standard.set(id, forKey: StorageKeys.userId)
  }

  func getUserEmail() -> String? {
    UserDefaults.standard.string(forKey: StorageKeys.userEmail)
  }

  func saveUserEmail(_ email: String) {
    UserDefaults.standard.set(email, forKey: StorageKeys.userEmail)
  }

  func getUserName() -> String? {
    UserDefaults.standard.string(forKey: StorageKeys.userName)
  }

  func saveUserName(_ name: String) {
    UserDefaults.standard.set(name, forKey: StorageKeys.userName)
  }

  func clearUser() {
    UserDefaults.standard.removeObject(forKey: StorageKeys.userId)
    UserDefaults.standard.removeObject(forKey: StorageKeys.userEmail)
    UserDefaults.standard.removeObject(forKey: StorageKeys.userName)
  }

  // MARK: - Keychain Operations

  private func getFromKeychain(key: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess,
          let data = result as? Data,
          let string = String(data: data, encoding: .utf8) else {
      return nil
    }

    return string
  }

  private func saveToKeychain(key: String, value: String) {
    guard let data = value.data(using: .utf8) else { return }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
    ]

    SecItemDelete(query as CFDictionary)
    SecItemAdd(query as CFDictionary, nil)
  }

  private func deleteFromKeychain(key: String) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
    ]

    SecItemDelete(query as CFDictionary)
  }
}
