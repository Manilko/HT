//
//  HabitListView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct HabitListView: View {
  @StateObject private var viewModel = HabitListViewModel()
  @State private var showCreateForm = false
  @State private var selectedHabit: HabitListItem?

  var body: some View {
    NavigationStack {
      ZStack {
        if viewModel.isLoading && viewModel.isEmpty {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        } else if viewModel.isEmpty {
          EmptyStateView(
            icon: "checkmark.circle",
            title: "No habits yet",
            message: "Create your first habit to get started",
            action: {
              showCreateForm = true
            },
            actionLabel: "Create Habit"
          )
        } else {
          List {
            ForEach(viewModel.habits) { habit in
              HabitRowView(habit: habit)
                .onTapGesture {
                  selectedHabit = habit
                }
                .swipeActions(edge: .trailing) {
                  if !habit.status.isArchived {
                    Button(role: .destructive) {
                      viewModel.confirmDeleteHabit(habit)
                    } label: {
                      Label("Archive", systemImage: "archivebox")
                    }
                  }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Habit: \(habit.name)")
                .accessibilityHint("\(habit.status.displayName) · Current streak: \(habit.currentStreak) days")
            }
          }
          .listStyle(.plain)
        }
      }
      .navigationTitle("Habits")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { showCreateForm = true }) {
            Image(systemName: "plus.circle.fill")
              .font(.system(size: 18))
          }
          .accessibilityLabel("Create new habit")
        }
      }
      .sheet(isPresented: $showCreateForm) {
        NavigationStack {
          HabitFormView(viewModel: HabitFormViewModel())
            .onDisappear {
              Task {
                await viewModel.loadHabits()
              }
            }
        }
      }
      .sheet(item: $selectedHabit) { habit in
        NavigationStack {
          HabitDetailView(habit: habit, viewModel: viewModel)
        }
      }
      .alert("Archive Habit?", isPresented: $viewModel.showDeleteConfirmation) {
        if let habit = viewModel.habitToDelete {
          Button("Cancel", role: .cancel) {}
          Button("Archive", role: .destructive) {
            Task {
              await viewModel.archiveHabit(habit)
            }
          }
        }
      } message: {
        Text("This habit will be moved to archived. You can delete it later.")
      }
      .alert("Error", isPresented: viewModel.hasError ? .constant(true) : .constant(false)) {
        Button("OK") {
          viewModel.clearError()
        }
      } message: {
        if let error = viewModel.errorMessage {
          Text(error)
        }
      }
      .task {
        await viewModel.loadHabits()
      }
    }
  }
}

struct EmptyStateView: View {
  let icon: String
  let title: String
  let message: String
  let action: () -> Void
  let actionLabel: String

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: icon)
        .font(.system(size: 60))
        .foregroundColor(.gray)

      VStack(spacing: 8) {
        Text(title)
          .font(.headline)

        Text(message)
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }

      Button(action: action) {
        Text(actionLabel)
          .font(.semibold)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
      }
      .padding(.top, 10)

      Spacer()
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
  }
}

#Preview {
  HabitListView()
}
