//
//  DashboardView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct DashboardView: View {
  @StateObject private var viewModel = HabitListViewModel()
  @StateObject private var notificationManager = MilestoneNotificationManager()
  @State private var showCreateForm = false
  @State private var selectedHabit: HabitListItem?
  @Environment(\.horizontalSizeClass) var sizeClass

  var body: some View {
    NavigationStack {
      ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()

        if viewModel.isLoading && viewModel.isEmpty {
          loadingState
        } else if viewModel.isEmpty {
          emptyState
        } else {
          habitsList
        }
      }
      .navigationTitle("Habits")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { showCreateForm = true }) {
            Image(systemName: "plus.circle.fill")
              .font(.system(size: 18))
              .foregroundColor(DesignTokens.Colors.info)
              .accessibilityLabel("Create new habit")
          }
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
          HabitDetailsViewNew(habitId: habit.id)
        }
      }
      .task {
        await viewModel.loadHabits()
      }
      .onAppear {
        notificationManager.start()
      }
      .onDisappear {
        notificationManager.stop()
      }
    }
  }

  @ViewBuilder
  private var loadingState: some View {
    VStack(spacing: DesignTokens.Spacing.lg) {
      ProgressView()
        .controlSize(.large)

      Text("Loading habits...")
        .font(DesignTokens.Typography.body)
        .foregroundColor(DesignTokens.Colors.textSecondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignTokens.Colors.background)
  }

  @ViewBuilder
  private var emptyState: some View {
    VStack(spacing: DesignTokens.Spacing.xl) {
      Image(systemName: "checkmark.circle")
        .font(.system(size: 60))
        .foregroundColor(DesignTokens.Colors.textTertiary)

      VStack(spacing: DesignTokens.Spacing.md) {
        Text(viewModel.allHabits.isEmpty ? "No habits yet" : "No results")
          .font(DesignTokens.Typography.title3)
          .foregroundColor(DesignTokens.Colors.textPrimary)

        Text(
          viewModel.allHabits.isEmpty
            ? "Create your first habit to get started"
            : "Try adjusting your filters or search"
        )
        .font(DesignTokens.Typography.body)
        .foregroundColor(DesignTokens.Colors.textSecondary)
        .multilineTextAlignment(.center)
      }

      Button(action: {
        if viewModel.allHabits.isEmpty {
          showCreateForm = true
        } else {
          viewModel.clearFilters()
        }
      }) {
        Text(viewModel.allHabits.isEmpty ? "Create Habit" : "Clear Filters")
          .frame(maxWidth: .infinity)
          .padding(.vertical, DesignTokens.Spacing.md)
          .background(DesignTokens.Colors.info)
          .foregroundColor(.white)
          .cornerRadius(DesignTokens.CornerRadius.md)
      }
      .padding(.top, DesignTokens.Spacing.lg)
    }
    .padding(DesignTokens.Spacing.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignTokens.Colors.background)
  }

  @ViewBuilder
  private var habitsList: some View {
    ScrollView {
      VStack(spacing: DesignTokens.Spacing.lg) {
        // Search and Filters
        searchBar
        filterPills
        summaryStats

        // Habits
        VStack(spacing: DesignTokens.Spacing.md) {
          ForEach(viewModel.filteredHabits) { habit in
            HabitCardView(
              habit: habit,
              onCheckIn: {
                Task {
                  await viewModel.checkInToday(habit)
                }
              },
              onTap: {
                selectedHabit = habit
              }
            )
            .swipeActions(edge: .trailing) {
              if !habit.status.isArchived {
                Button(role: .destructive) {
                  viewModel.confirmDeleteHabit(habit)
                } label: {
                  Label("Archive", systemImage: "archivebox")
                }
              }
            }
          }
        }

        if viewModel.hasError, let error = viewModel.errorMessage {
          errorBanner(error)
        }
      }
      .padding(DesignTokens.Spacing.lg)
    }
  }

  @ViewBuilder
  private var searchBar: some View {
    HStack(spacing: DesignTokens.Spacing.md) {
      Image(systemName: "magnifyingglass")
        .foregroundColor(DesignTokens.Colors.textTertiary)

      TextField("Search habits", text: $viewModel.searchText)
        .font(DesignTokens.Typography.body)
        .onChange(of: viewModel.searchText) { _, newValue in
          viewModel.updateSearch(newValue)
        }
        .accessibilityLabel("Search habits")

      if !viewModel.searchText.isEmpty {
        Button(action: { viewModel.updateSearch("") }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(DesignTokens.Colors.textTertiary)
        }
        .accessibilityLabel("Clear search")
      }
    }
    .padding(DesignTokens.Spacing.md)
    .background(DesignTokens.Colors.surfaceSecondary)
    .cornerRadius(DesignTokens.CornerRadius.md)
  }

  @ViewBuilder
  private var filterPills: some View {
    VStack(spacing: DesignTokens.Spacing.md) {
      HStack(spacing: DesignTokens.Spacing.md) {
        filterPill(label: "Active", isActive: viewModel.selectedStatuses.contains(.active)) {
          viewModel.toggleStatus(.active)
        }

        filterPill(label: "Paused", isActive: viewModel.selectedStatuses.contains(.paused)) {
          viewModel.toggleStatus(.paused)
        }

        filterPill(label: "Archived", isActive: viewModel.selectedStatuses.contains(.archived)) {
          viewModel.toggleStatus(.archived)
        }

        Spacer()
      }

      if viewModel.hasActiveFilters {
        HStack(spacing: DesignTokens.Spacing.md) {
          filterPill(
            label: "Completed Today",
            isActive: viewModel.showCompletedOnly
          ) {
            viewModel.toggleCompletionFilter()
          }

          Button(action: { viewModel.clearFilters() }) {
            HStack(spacing: DesignTokens.Spacing.xs) {
              Image(systemName: "xmark")
              Text("Clear")
            }
            .font(DesignTokens.Typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(DesignTokens.Colors.info)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(DesignTokens.Colors.info.opacity(0.1))
            .cornerRadius(DesignTokens.CornerRadius.sm)
          }
          .accessibilityLabel("Clear all filters")

          Spacer()
        }
      }
    }
  }

  @ViewBuilder
  private var summaryStats: some View {
    HStack(spacing: DesignTokens.Spacing.md) {
      summaryStatCard(
        icon: "list.number",
        value: "\(viewModel.filteredHabits.count)",
        label: "Habits"
      )

      summaryStatCard(
        icon: "checkmark.circle.fill",
        value: "\(viewModel.filteredHabits.filter { $0.todayCompleted }.count)",
        label: "Today"
      )

      summaryStatCard(
        icon: "flame.fill",
        value: "\(viewModel.filteredHabits.map { $0.currentStreak }.max() ?? 0)",
        label: "Max"
      )

      Spacer()
    }
  }

  @ViewBuilder
  private func filterPill(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(label)
        .font(DesignTokens.Typography.caption)
        .fontWeight(.semibold)
        .foregroundColor(isActive ? .white : DesignTokens.Colors.info)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(isActive ? DesignTokens.Colors.info : DesignTokens.Colors.info.opacity(0.1))
        .cornerRadius(DesignTokens.CornerRadius.sm)
    }
    .accessibilityLabel("Filter: \(label)")
    .accessibilityHint(isActive ? "Active" : "Inactive")
  }

  @ViewBuilder
  private func summaryStatCard(icon: String, value: String, label: String) -> some View {
    VStack(spacing: DesignTokens.Spacing.xs) {
      HStack(spacing: DesignTokens.Spacing.xs) {
        Image(systemName: icon)
          .font(.system(size: 12))
          .foregroundColor(DesignTokens.Colors.info)

        Text(value)
          .font(DesignTokens.Typography.captionBold)
      }
      .foregroundColor(DesignTokens.Colors.textPrimary)

      Text(label)
        .font(DesignTokens.Typography.caption)
        .foregroundColor(DesignTokens.Colors.textTertiary)
    }
    .padding(DesignTokens.Spacing.md)
    .cardStyle()
  }

  @ViewBuilder
  private func errorBanner(_ error: String) -> some View {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
      HStack(spacing: DesignTokens.Spacing.md) {
        Image(systemName: "exclamationmark.circle.fill")
          .foregroundColor(DesignTokens.Colors.error)

        Text(error)
          .font(DesignTokens.Typography.body)
          .foregroundColor(DesignTokens.Colors.textPrimary)

        Spacer()

        Button(action: { viewModel.clearError() }) {
          Image(systemName: "xmark")
            .foregroundColor(DesignTokens.Colors.textTertiary)
        }
      }
    }
    .padding(DesignTokens.Spacing.lg)
    .background(DesignTokens.Colors.error.opacity(0.1))
    .cornerRadius(DesignTokens.CornerRadius.md)
  }
}

#Preview {
  DashboardView()
}
