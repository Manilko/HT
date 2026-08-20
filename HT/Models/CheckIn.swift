//
//  CheckIn.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

struct CheckIn: Identifiable, Codable {
  let id: Int
  let habitId: Int
  let userId: Int
  let checkInDate: String
  let notes: String?
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case habitId = "habit_id"
    case userId = "user_id"
    case checkInDate = "check_in_date"
    case notes
    case createdAt = "created_at"
  }
}
