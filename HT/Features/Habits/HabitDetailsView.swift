//
//  HabitDetailsView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct HabitDetailsViewNew: View {
  @StateObject private var viewModel: HabitDetailsViewModel
  @Environment(\.dismiss) var dismiss

  init(habitId: Int) {
    _viewModel = StateObject(wrappedValue: HabitDetailsViewModel(habitId: habitId))
  }

  var body: some View {
    ZStack {
      if viewModel.isLoading {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let habit = viewModel.habit {
        ScrollView {
          VStack(spacing: 20) {
            // Header
            habitHeader(habit)

            // Stats Grid
            statsGrid(habit)

            // Check-in Status
            checkInStatusSection(habit)

            // Calendar
            VStack(alignment: .leading, spacing: 12) {
              Text("Check-in History")
                .font(.headline)
                .fontWeight(.semibold)

              MonthlyCalendarView(habit: habit, checkIns: viewModel.checkIns)
            }

            Spacer()
          }
          .padding()
        }
      } else if viewModel.hasError {
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 48))
            .foregroundColor(.red)

          Text("Failed to Load Habit")
            .font(.headline)

          if let error = viewModel.errorMessage {
            Text(error)
              .font(.caption)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
          }

          Button(action: { Task { await viewModel.loadDetails() } }) {
            Text("Try Again")
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
              .background(Color.blue)
              .foregroundColor(.white)
              .cornerRadius(8)
          }

          Button(action: { viewModel.clearError() }) {
            Text("Dismiss")
              .foregroundColor(.red)
          }
        }
        .padding(40)
      }
    }
    .navigationTitle("Habit Details")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.loadDetails()
    }
  }

  @ViewBuilder
  private func habitHeader(_ habit: HabitListItem) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 8) {
          Text(habit.name)
            .font(.title2)
            .fontWeight(.bold)

          if let description = habit.description, !description.isEmpty {
            Text(description)
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }

        Spacer()

        statusBadge(habit.status)
      }

      HStack(spacing: 12) {
        Image(systemName: "calendar")
          .foregroundColor(.secondary)

        Text("Started \(formattedStartDate(habit))")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }

  @ViewBuilder
  private func statsGrid(_ habit: HabitListItem) -> some View {
    VStack(spacing: 12) {
      HStack(spacing: 12) {
        StatCard(icon: "flame", title: "Current Streak", value: "\(habit.currentStreak)", unit: "days")
        StatCard(icon: "star.fill", title: "Best Streak", value: "\(habit.bestStreak)", unit: "days")
      }

      StatCard(icon: "checkmark.circle.fill", title: "Total Check-ins", value: "\(habit.totalCheckIns)", unit: "")
        .frame(maxWidth: .infinity)
    }
  }

  @ViewBuilder
  private func checkInStatusSection(_ habit: HabitListItem) -> some View {
    if habit.status.isActive {
      VStack(spacing: 12) {
        if habit.todayCompleted {
          VStack(spacing: 8) {
            HStack {
              Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
              Text("Completed today")
                .fontWeight(.semibold)
              Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)

            Button(action: { Task { await viewModel.undoTodaysCheckIn() } }) {
              if viewModel.isCheckingIn {
                ProgressView()
                  .tint(.white)
              } else {
                Label("Undo Check-in", systemImage: "xmark.circle")
              }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(viewModel.isCheckingIn)
          }
        } else {
          VStack(spacing: 8) {
            if let error = viewModel.checkInError {
              HStack {
                Image(systemName: "exclamationmark.circle.fill")
                  .font(.system(size: 16))
                Text(error)
                  .font(.caption)
                  .lineLimit(2)
                Spacer()
              }
              .padding(.vertical, 8)
              .padding(.horizontal, 12)
              .frame(maxWidth: .infinity)
              .background(Color.red.opacity(0.1))
              .cornerRadius(8)
            } else {
              HStack {
                Image(systemName: "circle")
                  .font(.system(size: 16))
                Text("Not completed today")
                  .fontWeight(.semibold)
                Spacer()
              }
              .padding(.vertical, 8)
              .padding(.horizontal, 12)
              .frame(maxWidth: .infinity)
              .background(Color.gray.opacity(0.1))
              .cornerRadius(8)
            }

            Button(action: { Task { await viewModel.checkInToday() } }) {
              if viewModel.isCheckingIn {
                ProgressView()
                  .tint(.white)
              } else {
                Label("Check In Today", systemImage: "plus.circle")
              }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(viewModel.isCheckingIn)

            if viewModel.checkInError != nil {
              Button(action: { viewModel.clearCheckInError() }) {
                Text("Dismiss")
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 8)
                  .foregroundColor(.red)
              }
            }
          }
        }
      }
      .padding()
      .background(Color(.systemGray6))
      .cornerRadius(12)
    }
  }

  @ViewBuilder
  private func statusBadge(_ status: HabitStatus) -> some View {
    let color: Color
    switch status {
    case .active:
      color = .green
    case .paused:
      color = .orange
    case .archived:
      color = .gray
    }

    HStack(spacing: 6) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)

      Text(status.displayName)
        .font(.caption)
        .fontWeight(.semibold)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(color.opacity(0.1))
    .cornerRadius(6)
  }

  private func formattedStartDate(_ habit: HabitListItem) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withFullDate]
    if let date = isoFormatter.date(from: habit.startDate) {
      return formatter.string(from: date)
    }
    return habit.startDate
  }
}

struct StatCard: View {
  let icon: String
  let title: String
  let value: String
  let unit: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: icon)
          .foregroundColor(.blue)
          .font(.system(size: 16))

        Text(title)
          .font(.caption)
          .foregroundColor(.secondary)

        Spacer()
      }

      HStack(alignment: .bottom, spacing: 4) {
        Text(value)
          .font(.system(size: 28, weight: .bold))

        Text(unit)
          .font(.caption)
          .foregroundColor(.secondary)

        Spacer()
      }
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(8)
  }
}

#Preview {
  NavigationStack {
    HabitDetailsViewNew(habitId: 1)
  }
}
