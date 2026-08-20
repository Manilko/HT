//
//  APIClient.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

class APIClient {
  static let shared = APIClient()

  private let baseURL = "https://api.habittracker.example/v1"
  private let session: URLSession
  private let storageManager: StorageManager
  private let authService: AuthService

  private init(storageManager: StorageManager = .shared, authService: AuthService = .shared) {
    self.storageManager = storageManager
    self.authService = authService
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 300
    self.session = URLSession(configuration: config)
  }

  func request<T: Decodable>(
    endpoint: String,
    method: HTTPMethod = .get,
    body: Encodable? = nil
  ) async throws -> T {
    return try await performRequest(endpoint: endpoint, method: method, body: body, retryCount: 0)
  }

  private func performRequest<T: Decodable>(
    endpoint: String,
    method: HTTPMethod,
    body: Encodable?,
    retryCount: Int
  ) async throws -> T {
    guard let url = URL(string: baseURL + endpoint) else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if let accessToken = storageManager.accessToken {
      request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    if let body = body {
      request.httpBody = try JSONEncoder().encode(body)
    }

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try JSONDecoder().decode(T.self, from: data)
    case 401 where retryCount == 0:
      // Token expired - try to refresh and retry
      do {
        try await authService.refreshTokenIfNeeded()
        return try await performRequest(endpoint: endpoint, method: method, body: body, retryCount: 1)
      } catch {
        throw APIError.unauthorized
      }
    case 401:
      throw APIError.unauthorized
    case 404:
      throw APIError.notFound
    case 500...599:
      throw APIError.serverError
    default:
      throw APIError.unknown
    }
  }

  func download(endpoint: String) async throws -> Data {
    guard let url = URL(string: baseURL + endpoint) else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)

    if let accessToken = storageManager.accessToken {
      request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw APIError.invalidResponse
    }

    return data
  }
}

enum HTTPMethod: String {
  case get = "GET"
  case post = "POST"
  case patch = "PATCH"
  case put = "PUT"
  case delete = "DELETE"
}

enum APIError: LocalizedError {
  case invalidURL
  case invalidResponse
  case unauthorized
  case notFound
  case serverError
  case decodingError
  case unknown

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .invalidResponse:
      return "Invalid response"
    case .unauthorized:
      return "Unauthorized"
    case .notFound:
      return "Not found"
    case .serverError:
      return "Server error"
    case .decodingError:
      return "Decoding error"
    case .unknown:
      return "Unknown error"
    }
  }
}
