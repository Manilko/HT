//
//  MonthlyCalendarView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct MonthlyCalendarView: View {
  let habit: HabitListItem
  let checkIns: [CheckIn]
  @State private var displayedMonth = Date()

  var body: some View {
    VStack(spacing: 16) {
      monthHeader
      dayLabels
      calendarGrid
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }

  private var monthHeader: some View {
    HStack {
      Button(action: { previousMonth() }) {
        Image(systemName: "chevron.left")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.blue)
      }

      Spacer()

      Text(monthYearString)
        .font(.headline)
        .fontWeight(.semibold)

      Spacer()

      Button(action: { nextMonth() }) {
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.blue)
      }
    }
  }

  private var dayLabels: some View {
    HStack(spacing: 0) {
      ForEach(0..<7, id: \.self) { index in
        Text(dayInitials[index])
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity)
      }
    }
  }

  private var calendarGrid: some View {
    VStack(spacing: 8) {
      let weeks = getWeeks(for: displayedMonth)

      ForEach(weeks, id: \.self) { week in
        HStack(spacing: 8) {
          ForEach(week, id: \.self) { date in
            calendarDay(date)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func calendarDay(_ date: Date?) -> some View {
    if let date = date {
      let isOutsideRange = date < habitStartDate || date > today
      let isCompleted = isCheckInDate(date)
      let isToday = calendar.isDateInToday(date)

      VStack {
        Text("\(calendar.component(.day, from: date))")
          .font(.caption)
          .fontWeight(.semibold)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 40)
      .background(dayBackground(isCompleted: isCompleted, isOutsideRange: isOutsideRange, isToday: isToday))
      .cornerRadius(6)
      .opacity(isOutsideRange ? 0.3 : 1)
    } else {
      Color.clear
        .frame(height: 40)
    }
  }

  private func dayBackground(isCompleted: Bool, isOutsideRange: Bool, isToday: Bool) -> Color {
    if isOutsideRange {
      return Color(.systemGray5)
    }

    if isCompleted {
      return Color.green.opacity(0.7)
    }

    if isToday {
      return Color.blue.opacity(0.1)
    }

    return Color(.systemBackground)
  }

  private func isCheckInDate(_ date: Date) -> Bool {
    let dateStr = dateString(date)
    return checkIns.contains { $0.checkInDate.prefix(10) == dateStr }
  }

  private func getWeeks(for month: Date) -> [[Date?]] {
    let range = calendar.range(of: .day, in: .month, for: month)!
    let numDays = range.count
    let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
    let firstWeekday = calendar.component(.weekday, from: firstDay)

    var weeks: [[Date?]] = []
    var week: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

    for day in 1...numDays {
      let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay)!
      week.append(date)

      if week.count == 7 {
        weeks.append(week)
        week = []
      }
    }

    if !week.isEmpty {
      week.append(contentsOf: Array(repeating: nil, count: 7 - week.count))
      weeks.append(week)
    }

    return weeks
  }

  private func previousMonth() {
    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
  }

  private func nextMonth() {
    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
  }

  private var monthYearString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter.string(from: displayedMonth)
  }

  private var habitStartDate: Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.date(from: habit.startDate) ?? Date()
  }

  private var today: Date {
    calendar.startOfDay(for: Date())
  }

  private var calendar: Calendar {
    Calendar.current
  }

  private var dayInitials: [String] {
    ["S", "M", "T", "W", "T", "F", "S"]
  }

  private func dateString(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.string(from: date)
  }
}

#Preview {
  ScrollView {
    MonthlyCalendarView(
      habit: HabitListItem(
        from: Habit(
          id: 1,
          name: "Morning Run",
          description: "Run 5 miles every morning",
          startDate: "2026-07-20",
          status: .active,
          currentStreak: 7,
          bestStreak: 15,
          totalCheckIns: 20,
          createdAt: "2026-07-20T10:00:00Z",
          updatedAt: "2026-08-20T10:00:00Z"
        ),
        currentStreak: 7,
        bestStreak: 15,
        totalCheckIns: 20
      ),
      checkIns: [
        CheckIn(id: 1, habitId: 1, userId: 1, checkInDate: "2026-08-15", createdAt: "2026-08-15T10:00:00Z"),
        CheckIn(id: 2, habitId: 1, userId: 1, checkInDate: "2026-08-16", createdAt: "2026-08-16T10:00:00Z"),
        CheckIn(id: 3, habitId: 1, userId: 1, checkInDate: "2026-08-17", createdAt: "2026-08-17T10:00:00Z"),
        CheckIn(id: 4, habitId: 1, userId: 1, checkInDate: "2026-08-19", createdAt: "2026-08-19T10:00:00Z"),
        CheckIn(id: 5, habitId: 1, userId: 1, checkInDate: "2026-08-20", createdAt: "2026-08-20T10:00:00Z"),
      ]
    )
    .padding()
  }
}
