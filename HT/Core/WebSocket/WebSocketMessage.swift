//
//  WebSocketMessage.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

// MARK: - Message Types

enum WebSocketMessageType: String, Codable {
  case subscribe
  case unsubscribe
  case streakMilestone = "streak_milestone"
  case error
}

// MARK: - Client Messages

struct ClientMessage: Encodable {
  let type: String
  let payload: Payload?

  struct Payload: Encodable {
    let milestones: Bool?
  }

  static func subscribe() -> ClientMessage {
    ClientMessage(
      type: "subscribe",
      payload: Payload(milestones: true)
    )
  }

  static func unsubscribe() -> ClientMessage {
    ClientMessage(
      type: "unsubscribe",
      payload: nil
    )
  }
}

// MARK: - Server Messages

struct ServerMessage: Decodable {
  let type: String
  let payload: AnyCodable?

  enum DecodingError: LocalizedError {
    case invalidType
    case missingPayload
    case decodingFailed(String)

    var errorDescription: String? {
      switch self {
      case .invalidType:
        return "Invalid message type"
      case .missingPayload:
        return "Message payload is missing"
      case .decodingFailed(let reason):
        return "Failed to decode message: \(reason)"
      }
    }
  }
}

// MARK: - Milestone Notification

struct MilestoneNotification: Decodable, Equatable {
  let habitId: Int
  let habitName: String
  let milestone: Int
  let currentStreak: Int

  enum CodingKeys: String, CodingKey {
    case habitId
    case habitName
    case milestone
    case currentStreak
  }
}

// MARK: - Error Message

struct ErrorMessage: Decodable {
  let message: String
}

// MARK: - Generic Decodable Container

struct AnyCodable: Decodable {
  let value: Any

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let boolValue = try? container.decode(Bool.self) {
      self.value = boolValue
    } else if let intValue = try? container.decode(Int.self) {
      self.value = intValue
    } else if let doubleValue = try? container.decode(Double.self) {
      self.value = doubleValue
    } else if let stringValue = try? container.decode(String.self) {
      self.value = stringValue
    } else if let arrayValue = try? container.decode([AnyCodable].self) {
      self.value = arrayValue.map { $0.value }
    } else if let dictValue = try? container.decode([String: AnyCodable].self) {
      var result: [String: Any] = [:]
      for (key, value) in dictValue {
        result[key] = value.value
      }
      self.value = result
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "AnyCodable cannot decode value"
        )
      )
    }
  }

  func decode<T: Decodable>(as type: T.Type) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: value)
    let decoder = JSONDecoder()
    return try decoder.decode(type, from: data)
  }
}
