//
//  HabitDetailView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct HabitDetailView: View {
  let habitId: Int
  @StateObject private var viewModel: HabitDetailViewModel
  @Environment(\.dismiss) var dismiss

  init(habitId: Int) {
    self.habitId = habitId
    _viewModel = StateObject(wrappedValue: HabitDetailViewModel(habitId: habitId))
  }

  var body: some View {
    VStack {
      if viewModel.isLoading {
        ProgressView()
      } else if let habit = viewModel.habit {
        Form {
          Section(header: Text("Habit")) {
            HStack {
              Text("Name")
              Spacer()
              Text(habit.name)
                .foregroundColor(.gray)
            }

            if let description = habit.description {
              HStack {
                Text("Description")
                Spacer()
                Text(description)
                  .foregroundColor(.gray)
              }
            }
          }

          if let streak = viewModel.streak {
            Section(header: Text("Streak")) {
              HStack {
                Text("Current Streak")
                Spacer()
                Text("\(streak.currentStreakDays) days")
                  .foregroundColor(.green)
              }

              HStack {
                Text("Best Streak")
                Spacer()
                Text("\(streak.bestStreakDays) days")
                  .foregroundColor(.blue)
              }

              HStack {
                Text("Total Check-ins")
                Spacer()
                Text("\(streak.totalCheckIns)")
                  .foregroundColor(.gray)
              }
            }
          }

          Section {
            Button(action: { Task { await viewModel.logCheckIn() } }) {
              HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Log Check-in Today")
              }
              .foregroundColor(.green)
            }
            .disabled(viewModel.isLoading)
          }
        }
      }
    }
    .navigationTitle("Habit Details")
    .onAppear {
      Task {
        await viewModel.loadHabitDetails()
      }
    }
  }
}

#Preview {
  NavigationStack {
    HabitDetailView(habitId: 1)
  }
}
