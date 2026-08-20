//
//  HabitsView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct HabitsView: View {
  @StateObject private var viewModel = HabitsViewModel()
  @ObservedObject var coordinator: HabitsCoordinator

  var body: some View {
    NavigationStack(path: $coordinator.path) {
      VStack {
        if viewModel.isLoading {
          ProgressView()
        } else if viewModel.habits.isEmpty {
          VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
              .font(.system(size: 50))
              .foregroundColor(.gray)

            Text("No habits yet")
              .font(.headline)

            Text("Create your first habit to get started")
              .font(.subheadline)
              .foregroundColor(.gray)

            Button(action: { coordinator.navigate(to: .create) }) {
              Label("Create Habit", systemImage: "plus.circle.fill")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
          }
          .frame(maxHeight: .infinity, alignment: .center)
        } else {
          List {
            ForEach(viewModel.habits) { habit in
              NavigationLink(value: HabitsCoordinator.HabitRoute.detail(habitId: habit.id)) {
                HabitRowView(habit: habit)
              }
            }
          }
        }
      }
      .navigationTitle("My Habits")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { coordinator.navigate(to: .create) }) {
            Image(systemName: "plus")
          }
        }
      }
      .navigationDestination(for: HabitsCoordinator.HabitRoute.self) { route in
        coordinator.view(for: route)
      }
      .onAppear {
        Task {
          await viewModel.loadHabits()
        }
      }
    }
  }
}

struct HabitRowView: View {
  let habit: Habit

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(habit.name)
        .font(.headline)

      if let description = habit.description {
        Text(description)
          .font(.caption)
          .foregroundColor(.gray)
          .lineLimit(2)
      }
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  HabitsView(coordinator: HabitsCoordinator())
}
