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
            icon: viewModel.allHabits.isEmpty ? "checkmark.circle" : "magnifyingglass",
            title: viewModel.allHabits.isEmpty ? "No habits yet" : "No results",
            message: viewModel.allHabits.isEmpty ? "Create your first habit to get started" : "Try adjusting your filters or search",
            action: {
              if viewModel.allHabits.isEmpty {
                showCreateForm = true
              } else {
                viewModel.clearFilters()
              }
            },
            actionLabel: viewModel.allHabits.isEmpty ? "Create Habit" : "Clear Filters"
          )
        } else {
          List {
            ForEach(viewModel.filteredHabits) { habit in
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
      .safeAreaInset(edge: .top) {
        VStack(spacing: 12) {
          // Search bar
          HStack {
            Image(systemName: "magnifyingglass")
              .foregroundColor(.gray)

            TextField("Search habits", text: $viewModel.searchText)
              .onChange(of: viewModel.searchText) { _, newValue in
                viewModel.updateSearch(newValue)
              }
              .textInputAutocapitalization(.never)
              .accessibilityLabel("Search habits")

            if !viewModel.searchText.isEmpty {
              Button(action: { viewModel.updateSearch("") }) {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.gray)
              }
              .accessibilityLabel("Clear search")
            }
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 8)
          .background(Color(.systemGray6))
          .cornerRadius(8)

          // Filter pills
          VStack(spacing: 8) {
            HStack(spacing: 8) {
              // Status filters
              FilterPill(
                label: "Active",
                isActive: viewModel.selectedStatuses.contains(.active),
                action: { viewModel.toggleStatus(.active) }
              )

              FilterPill(
                label: "Paused",
                isActive: viewModel.selectedStatuses.contains(.paused),
                action: { viewModel.toggleStatus(.paused) }
              )

              FilterPill(
                label: "Archived",
                isActive: viewModel.selectedStatuses.contains(.archived),
                action: { viewModel.toggleStatus(.archived) }
              )

              Spacer()
            }

            HStack(spacing: 8) {
              FilterPill(
                label: "Completed Today",
                isActive: viewModel.showCompletedOnly,
                action: { viewModel.toggleCompletionFilter() }
              )

              if viewModel.hasActiveFilters {
                Button(action: { viewModel.clearFilters() }) {
                  HStack(spacing: 4) {
                    Image(systemName: "xmark")
                      .font(.caption)

                    Text("Clear")
                      .font(.caption)
                      .fontWeight(.medium)
                  }
                  .padding(.horizontal, 10)
                  .padding(.vertical, 6)
                  .foregroundColor(.blue)
                  .background(Color.blue.opacity(0.1))
                  .cornerRadius(6)
                }
                .accessibilityLabel("Clear all filters")
              }

              Spacer()
            }
          }
          .padding(.horizontal)
          .padding(.bottom, 8)
        }
        .padding(.top, 12)
        .background(Color(.systemBackground))
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

struct FilterPill: View {
  let label: String
  let isActive: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(label)
        .font(.caption)
        .fontWeight(.medium)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundColor(isActive ? .white : .blue)
        .background(isActive ? Color.blue : Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
    .accessibilityLabel("Filter: \(label)")
    .accessibilityHint(isActive ? "Active" : "Inactive")
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
