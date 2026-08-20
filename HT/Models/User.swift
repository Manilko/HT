//
//  User.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

struct User: Identifiable, Codable {
  let id: Int
  let email: String
  let displayName: String
  let oauthId: String
  let oauthProvider: String
  let timezone: String
  let profilePictureUrl: String?
  let createdAt: Date
  let updatedAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case email
    case displayName = "display_name"
    case oauthId = "oauth_id"
    case oauthProvider = "oauth_provider"
    case timezone
    case profilePictureUrl = "profile_picture_url"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}
