//
//  Streak.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

struct Streak: Identifiable, Codable {
  let id: Int
  let habitId: Int
  let currentStreakDays: Int
  let bestStreakDays: Int
  let bestStreakStartDate: String?
  let bestStreakEndDate: String?
  let totalCheckIns: Int
  let lastCheckInDate: String?
  let updatedAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case habitId = "habit_id"
    case currentStreakDays = "current_streak_days"
    case bestStreakDays = "best_streak_days"
    case bestStreakStartDate = "best_streak_start_date"
    case bestStreakEndDate = "best_streak_end_date"
    case totalCheckIns = "total_check_ins"
    case lastCheckInDate = "last_check_in_date"
    case updatedAt = "updated_at"
  }
}
