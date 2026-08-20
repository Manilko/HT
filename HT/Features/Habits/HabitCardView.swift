//
//  HabitCardView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct HabitCardView: View {
  let habit: HabitListItem
  let onCheckIn: () -> Void
  let onTap: () -> Void
  @Environment(\.isEnabled) private var isEnabled

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
        // Header
        HStack(spacing: DesignTokens.Spacing.md) {
          VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(habit.name)
              .font(DesignTokens.Typography.subheadline)
              .foregroundColor(DesignTokens.Colors.textPrimary)
              .lineLimit(2)

            if let description = habit.description, !description.isEmpty {
              Text(description)
                .font(DesignTokens.Typography.bodySmall)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .lineLimit(2)
            }
          }

          Spacer()

          VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
            statusBadge
            todayIndicator
          }
        }

        Divider()
          .background(DesignTokens.Colors.divider)

        // Stats Row
        HStack(spacing: DesignTokens.Spacing.lg) {
          statItem(
            icon: "flame.fill",
            value: "\(habit.currentStreak)",
            label: "Current",
            color: DesignTokens.Colors.streakFire
          )

          statItem(
            icon: "star.fill",
            value: "\(habit.bestStreak)",
            label: "Best",
            color: DesignTokens.Colors.streakStar
          )

          statItem(
            icon: "checkmark.circle.fill",
            value: "\(habit.totalCheckIns)",
            label: "Total",
            color: DesignTokens.Colors.success
          )

          Spacer()
        }

        // Action Button
        if habit.status.isActive {
          Button(action: onCheckIn) {
            HStack(spacing: DesignTokens.Spacing.sm) {
              Image(systemName: habit.todayCompleted ? "checkmark.circle.fill" : "plus.circle")

              Text(habit.todayCompleted ? "Checked in" : "Check in")
                .font(DesignTokens.Typography.bodySmall)
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
              habit.todayCompleted
                ? DesignTokens.Colors.success.opacity(0.1)
                : DesignTokens.Colors.info.opacity(0.1)
            )
            .foregroundColor(
              habit.todayCompleted
                ? DesignTokens.Colors.success
                : DesignTokens.Colors.info
            )
            .cornerRadius(DesignTokens.CornerRadius.sm)
          }
          .disabled(habit.todayCompleted)
        }
      }
      .padding(DesignTokens.Spacing.lg)
      .cardStyle()
    }
    .buttonStyle(PlainButtonStyle())
    .opacity(isEnabled ? 1.0 : 0.5)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Habit: \(habit.name)")
    .accessibilityHint(
      "Streak: \(habit.currentStreak) days. " +
      "\(habit.todayCompleted ? "Completed today" : "Not completed today")"
    )
  }

  @ViewBuilder
  private var statusBadge: some View {
    let (color, icon) = statusInfo
    HStack(spacing: DesignTokens.Spacing.xs) {
      Circle()
        .fill(color)
        .frame(width: 6, height: 6)

      Text(habit.status.displayName)
        .font(DesignTokens.Typography.caption)
        .fontWeight(.semibold)
        .foregroundColor(color)
    }
    .padding(.horizontal, DesignTokens.Spacing.sm)
    .padding(.vertical, DesignTokens.Spacing.xs)
    .background(color.opacity(0.08))
    .cornerRadius(DesignTokens.CornerRadius.sm)
  }

  @ViewBuilder
  private var todayIndicator: some View {
    if habit.status.isActive {
      if habit.todayCompleted {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 16))
          .foregroundColor(DesignTokens.Colors.success)
          .accessibilityLabel("Completed today")
      } else {
        Image(systemName: "circle")
          .font(.system(size: 16))
          .foregroundColor(DesignTokens.Colors.textTertiary)
          .accessibilityLabel("Not completed today")
      }
    }
  }

  private var statusInfo: (color: Color, icon: String) {
    switch habit.status {
    case .active:
      return (DesignTokens.Colors.activeGreen, "play.circle")
    case .paused:
      return (DesignTokens.Colors.pausedOrange, "pause.circle")
    case .archived:
      return (DesignTokens.Colors.archivedGray, "archivebox")
    }
  }

  @ViewBuilder
  private func statItem(
    icon: String,
    value: String,
    label: String,
    color: Color
  ) -> some View {
    VStack(alignment: .center, spacing: 2) {
      HStack(spacing: DesignTokens.Spacing.xs) {
        Image(systemName: icon)
          .font(.system(size: 12))
          .foregroundColor(color)

        Text(value)
          .font(DesignTokens.Typography.captionBold)
          .foregroundColor(DesignTokens.Colors.textPrimary)
      }

      Text(label)
        .font(DesignTokens.Typography.caption)
        .foregroundColor(DesignTokens.Colors.textTertiary)
    }
  }
}

#Preview {
  VStack(spacing: DesignTokens.Spacing.lg) {
    HabitCardView(
      habit: HabitListItem(
        from: Habit(
          id: 1,
          name: "Morning Run",
          description: "5 miles every morning",
          startDate: "2026-08-20",
          status: .active,
          currentStreak: 7,
          bestStreak: 15,
          totalCheckIns: 20,
          createdAt: "2026-08-20T10:00:00Z",
          updatedAt: "2026-08-20T10:00:00Z"
        ),
        currentStreak: 7,
        bestStreak: 15,
        totalCheckIns: 20,
        todayCompleted: true
      ),
      onCheckIn: {},
      onTap: {}
    )

    HabitCardView(
      habit: HabitListItem(
        from: Habit(
          id: 2,
          name: "Evening Meditation",
          description: "20 minutes",
          startDate: "2026-08-20",
          status: .active,
          currentStreak: 3,
          bestStreak: 10,
          totalCheckIns: 5,
          createdAt: "2026-08-20T10:00:00Z",
          updatedAt: "2026-08-20T10:00:00Z"
        ),
        currentStreak: 3,
        bestStreak: 10,
        totalCheckIns: 5,
        todayCompleted: false
      ),
      onCheckIn: {},
      onTap: {}
    )
  }
  .padding()
  .background(DesignTokens.Colors.background)
}
