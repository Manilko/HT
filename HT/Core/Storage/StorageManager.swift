//
//  StorageManager.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation
import Security

class StorageManager {
  static let shared = StorageManager()

  private let keychainService = "com.habittracker.app"
  private let userDefaults = UserDefaults.standard

  // MARK: - Token Management

  var accessToken: String? {
    get { retrieveFromKeychain(key: "accessToken") }
  }

  var refreshToken: String? {
    get { retrieveFromKeychain(key: "refreshToken") }
  }

  func saveAccessToken(_ token: String) {
    storeInKeychain(key: "accessToken", value: token)
  }

  func saveRefreshToken(_ token: String) {
    storeInKeychain(key: "refreshToken", value: token)
  }

  func clearAllTokens() {
    deleteFromKeychain(key: "accessToken")
    deleteFromKeychain(key: "refreshToken")
  }

  // MARK: - Keychain Operations

  private func storeInKeychain(key: String, value: String) {
    let data = value.data(using: .utf8)!
    let query = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: keychainService,
      kSecAttrAccount: key,
      kSecValueData: data,
    ] as [String: Any]

    SecItemDelete(query as CFDictionary)
    SecItemAdd(query as CFDictionary, nil)
  }

  private func retrieveFromKeychain(key: String) -> String? {
    let query = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: keychainService,
      kSecAttrAccount: key,
      kSecReturnData: true,
    ] as [String: Any]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess,
          let data = result as? Data,
          let token = String(data: data, encoding: .utf8) else {
      return nil
    }

    return token
  }

  private func deleteFromKeychain(key: String) {
    let query = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: keychainService,
      kSecAttrAccount: key,
    ] as [String: Any]

    SecItemDelete(query as CFDictionary)
  }

  // MARK: - UserDefaults

  func saveUserID(_ id: Int) {
    userDefaults.set(id, forKey: "userID")
  }

  func getUserID() -> Int? {
    let id = userDefaults.integer(forKey: "userID")
    return id > 0 ? id : nil
  }

  func saveTimezone(_ timezone: String) {
    userDefaults.set(timezone, forKey: "timezone")
  }

  func getTimezone() -> String {
    return userDefaults.string(forKey: "timezone") ?? TimeZone.current.identifier
  }
}
