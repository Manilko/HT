//
//  Habit.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

enum HabitStatus: String, Codable {
  case active = "ACTIVE"
  case paused = "PAUSED"
  case archived = "ARCHIVED"

  var displayName: String {
    switch self {
    case .active:
      return "Active"
    case .paused:
      return "Paused"
    case .archived:
      return "Archived"
    }
  }

  var isArchived: Bool {
    self == .archived
  }

  var isActive: Bool {
    self == .active
  }

  var isPaused: Bool {
    self == .paused
  }
}

struct Habit: Identifiable, Codable {
  let id: Int
  let name: String
  let description: String?
  let startDate: String
  let status: HabitStatus
  let createdAt: String
  let updatedAt: String

  var isReadOnly: Bool {
    status.isArchived
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case description
    case startDate
    case status
    case createdAt
    case updatedAt
  }
}

struct HabitDTO: Codable {
  let id: Int
  let name: String
  let description: String?
  let startDate: String
  let status: HabitStatus
  let createdAt: String
  let updatedAt: String

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case description
    case startDate
    case status
    case createdAt
    case updatedAt
  }

  func toHabit() -> Habit {
    Habit(
      id: id,
      name: name,
      description: description,
      startDate: startDate,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}

struct CreateHabitRequest: Codable {
  let name: String
  let description: String?
  let startDate: String

  enum CodingKeys: String, CodingKey {
    case name
    case description
    case startDate
  }
}

struct UpdateHabitRequest: Codable {
  let name: String?
  let description: String?
  let status: HabitStatus?

  enum CodingKeys: String, CodingKey {
    case name
    case description
    case status
  }

  init(name: String? = nil, description: String? = nil, status: HabitStatus? = nil) {
    self.name = name
    self.description = description
    self.status = status
  }
}

struct HabitListItem: Identifiable {
  let id: Int
  let name: String
  let description: String?
  let status: HabitStatus
  let currentStreak: Int
  let bestStreak: Int
  let totalCheckIns: Int
  let todayCompleted: Bool

  init(from habit: Habit, currentStreak: Int = 0, bestStreak: Int = 0, totalCheckIns: Int = 0, todayCompleted: Bool = false) {
    self.id = habit.id
    self.name = habit.name
    self.description = habit.description
    self.status = habit.status
    self.currentStreak = currentStreak
    self.bestStreak = bestStreak
    self.totalCheckIns = totalCheckIns
    self.todayCompleted = todayCompleted
  }
}
