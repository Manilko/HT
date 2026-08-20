//
//  HabitRowView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct HabitRowView: View {
  let habit: HabitListItem

  var statusColor: Color {
    switch habit.status {
    case .active:
      return .green
    case .paused:
      return .orange
    case .archived:
      return .gray
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 8) {
            Text(habit.name)
              .font(.headline)

            Spacer()

            HStack(spacing: 4) {
              Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

              Text(habit.status.displayName)
                .font(.caption)
                .foregroundColor(statusColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(6)
          }

          if let description = habit.description, !description.isEmpty {
            Text(description)
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(1)
          }
        }

        if habit.todayCompleted {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 18))
            .foregroundColor(.green)
            .accessibilityLabel("Completed today")
        }
      }

      HStack(spacing: 20) {
        StreakBadge(icon: "flame", value: habit.currentStreak, label: "Current")
        StreakBadge(icon: "star.fill", value: habit.bestStreak, label: "Best")
        StreakBadge(icon: "checkmark.circle", value: habit.totalCheckIns, label: "Total")

        Spacer()
      }
      .font(.caption)
    }
    .padding(.vertical, 8)
  }
}

struct StreakBadge: View {
  let icon: String
  let value: Int
  let label: String

  var body: some View {
    VStack(spacing: 2) {
      HStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 12))

        Text("\(value)")
          .fontWeight(.semibold)
      }

      Text(label)
        .font(.caption2)
        .foregroundColor(.secondary)
    }
  }
}

#Preview {
  HabitRowView(
    habit: HabitListItem(
      from: Habit(
        id: 1,
        name: "Morning Run",
        description: "Run 5 miles every morning",
        startDate: "2026-08-20",
        status: .active,
        createdAt: "2026-08-20T10:00:00Z",
        updatedAt: "2026-08-20T10:00:00Z"
      ),
      currentStreak: 7,
      bestStreak: 15,
      totalCheckIns: 20,
      todayCompleted: true
    )
  )
  .padding()
}
