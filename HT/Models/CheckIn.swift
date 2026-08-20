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
  let createdAt: String

  var dateFormatted: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    if let date = formatter.date(from: checkInDate) {
      formatter.dateStyle = .medium
      return formatter.string(from: date)
    }
    return checkInDate
  }

  enum CodingKeys: String, CodingKey {
    case id
    case habitId
    case userId
    case checkInDate
    case createdAt
  }
}
