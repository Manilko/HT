//
//  HabitDetailView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct HabitDetailView: View {
  let habit: HabitListItem
  let viewModel: HabitListViewModel
  @Environment(\.dismiss) var dismiss
  @State private var showEditForm = false
  @State private var showDeleteConfirmation = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        // Header
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
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

            StatusBadge(status: habit.status)
          }

          HStack(spacing: 8) {
            Image(systemName: "calendar")
              .foregroundColor(.secondary)

            Text("Started on \(formattedStartDate)")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)

        // Statistics
        VStack(spacing: 12) {
          HStack(spacing: 12) {
            StatCard(icon: "flame", title: "Current Streak", value: "\(habit.currentStreak)", unit: "days")
            StatCard(icon: "star.fill", title: "Best Streak", value: "\(habit.bestStreak)", unit: "days")
          }

          StatCard(icon: "checkmark.circle", title: "Total Check-ins", value: "\(habit.totalCheckIns)", unit: "")
            .frame(maxWidth: .infinity)
        }

        if !habit.status.isArchived {
          // Check-in section for active habits
          if habit.status.isActive {
            VStack(spacing: 8) {
              let isCheckingIn = viewModel.checkingInHabitId == habit.id
              let hasError = viewModel.checkInErrors[habit.id] != nil
              let errorMessage = viewModel.checkInErrors[habit.id]

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

                  Button(action: {
                    Task {
                      await viewModel.undoTodaysCheckIn(habit)
                    }
                  }) {
                    if isCheckingIn {
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
                  .disabled(isCheckingIn || hasError)
                }
              } else {
                VStack(spacing: 8) {
                  if hasError {
                    HStack {
                      Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 16))
                      Text(errorMessage ?? "Failed to check in")
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
                      Image(systemImage: "circle")
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

                  Button(action: {
                    Task {
                      await viewModel.checkInToday(habit)
                    }
                  }) {
                    if isCheckingIn {
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
                  .disabled(isCheckingIn || hasError)

                  if hasError {
                    Button(action: {
                      viewModel.clearCheckInError(habit.id)
                    }) {
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

          // Actions
          VStack(spacing: 12) {
            if habit.status.isPaused {
              Button(action: {
                Task {
                  await viewModel.resumeHabit(habit)
                  dismiss()
                }
              }) {
                Label("Resume", systemImage: "play.circle.fill")
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .background(Color.green)
                  .foregroundColor(.white)
                  .cornerRadius(8)
              }
            } else if habit.status.isActive {
              Button(action: {
                Task {
                  await viewModel.pauseHabit(habit)
                  dismiss()
                }
              }) {
                Label("Pause", systemImage: "pause.circle.fill")
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .background(Color.orange)
                  .foregroundColor(.white)
                  .cornerRadius(8)
              }
            }

            Button(action: { showEditForm = true }) {
              Label("Edit", systemImage: "pencil")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            Button(action: {
              Task {
                await viewModel.archiveHabit(habit)
                dismiss()
              }
            }) {
              Label("Archive", systemImage: "archivebox")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
          }
        } else {
          Button(role: .destructive, action: { showDeleteConfirmation = true }) {
            Label("Delete Archived Habit", systemImage: "trash")
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
              .background(Color.red.opacity(0.1))
              .foregroundColor(.red)
              .cornerRadius(8)
          }
        }

        Spacer()
      }
      .padding()
    }
    .navigationTitle("Habit Details")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showEditForm) {
      NavigationStack {
        HabitFormView(viewModel: HabitFormViewModel(habitToEdit: Habit(
          id: habit.id,
          name: habit.name,
          description: habit.description,
          startDate: "",
          status: habit.status,
          createdAt: "",
          updatedAt: ""
        )))
        .onDisappear {
          Task {
            await viewModel.loadHabits()
          }
        }
      }
    }
    .alert("Delete Habit?", isPresented: $showDeleteConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        Task {
          await viewModel.deleteHabit(habit)
          dismiss()
        }
      }
    } message: {
      Text("This action cannot be undone. All check-in history will be deleted.")
    }
  }

  private var formattedStartDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: ISO8601DateFormatter().date(from: habit.startDate) ?? Date())
  }
}

struct StatusBadge: View {
  let status: HabitStatus

  var statusColor: Color {
    switch status {
    case .active:
      return .green
    case .paused:
      return .orange
    case .archived:
      return .gray
    }
  }

  var body: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(statusColor)
        .frame(width: 8, height: 8)

      Text(status.displayName)
        .font(.caption)
        .fontWeight(.semibold)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(statusColor.opacity(0.1))
    .cornerRadius(6)
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

      HStack(alignment: .baseline, spacing: 4) {
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
    HabitDetailView(
      habit: HabitListItem(
        from: Habit(
          id: 1,
          name: "Morning Run",
          description: "Run 5 miles",
          startDate: "2026-08-20T00:00:00Z",
          status: .active,
          currentStreak: 7,
          bestStreak: 15,
          totalCheckIns: 20,
          createdAt: "2026-08-20T10:00:00Z",
          updatedAt: "2026-08-20T10:00:00Z"
        ),
        currentStreak: 7,
        bestStreak: 15,
        totalCheckIns: 20
      ),
      viewModel: HabitListViewModel()
    )
  }
}
