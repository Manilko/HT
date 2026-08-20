//
//  Extensions.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

extension Color {
  static let habitTrackerBlue = Color(red: 0.0, green: 0.5, blue: 1.0)
  static let habitTrackerGreen = Color(red: 0.0, green: 0.75, blue: 0.0)
  static let habitTrackerRed = Color(red: 1.0, green: 0.0, blue: 0.0)
}

extension Date {
  var startOfDay: Date {
    Calendar.current.startOfDay(for: self)
  }

  var endOfDay: Date {
    var components = DateComponents()
    components.day = 1
    components.second = -1
    return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
  }

  func isToday() -> Bool {
    Calendar.current.isDateInToday(self)
  }

  func isYesterday() -> Bool {
    Calendar.current.isDateInYesterday(self)
  }

  func formattedDateString() -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: self)
  }
}

extension String {
  var isEmptyOrWhitespace: Bool {
    trimmingCharacters(in: .whitespaces).isEmpty
  }
}
