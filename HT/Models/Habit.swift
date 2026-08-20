//
//  Habit.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

struct Habit: Identifiable, Codable {
  let id: Int
  let userId: Int
  let name: String
  let description: String?
  let color: String?
  let frequency: String
  let createdAt: Date
  let updatedAt: Date
  let deletedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case name
    case description
    case color
    case frequency
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case deletedAt = "deleted_at"
  }
}
