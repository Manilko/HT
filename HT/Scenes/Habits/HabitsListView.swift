//
//  HabitsListView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct HabitsListView: View {
  @StateObject private var viewModel: HabitsListViewModel
  @State private var showingNewHabitSheet = false

  init(viewModel: HabitsListViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    NavigationStack {
      VStack {
        if viewModel.isLoading {
          ProgressView()
        } else if viewModel.habits.isEmpty {
          Text("No habits yet. Create your first habit!")
            .foregroundColor(.gray)
        } else {
          List {
            ForEach(viewModel.habits, id: \.id) { habit in
              HabitRowView(habit: habit)
            }
          }
        }
      }
      .navigationTitle("My Habits")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button(action: { showingNewHabitSheet = true }) {
            Label("Add", systemImage: "plus")
          }
        }
      }
      .sheet(isPresented: $showingNewHabitSheet) {
        NewHabitView()
      }
    }
    .onAppear {
      Task {
        await viewModel.loadHabits()
      }
    }
  }
}

struct HabitRowView: View {
  let habit: Habit

  var body: some View {
    VStack(alignment: .leading) {
      Text(habit.name)
        .font(.headline)
      if let description = habit.description {
        Text(description)
          .font(.caption)
          .foregroundColor(.gray)
      }
    }
  }
}

struct NewHabitView: View {
  @Environment(\.dismiss) var dismiss

  var body: some View {
    VStack {
      Text("New Habit")
        .font(.title2)
      Spacer()
      Button("Close") {
        dismiss()
      }
    }
    .padding()
  }
}

#Preview {
  HabitsListView(viewModel: HabitsListViewModel(habitService: MockHabitService()))
}
