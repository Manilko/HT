//
//  APIResponse.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

struct APIResponse<T: Decodable>: Decodable {
  let success: Bool
  let data: T?
  let error: APIErrorResponse?
  let timestamp: String

  enum CodingKeys: String, CodingKey {
    case success
    case data
    case error
    case timestamp
  }
}

struct APIErrorResponse: Decodable {
  let code: String
  let message: String
  let details: [String: String]?
}
