//
//  CreateHabitView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct CreateHabitView: View {
  @StateObject private var viewModel = CreateHabitViewModel()
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Habit Information")) {
          TextField("Habit name", text: $viewModel.habitName)

          TextField("Description (optional)", text: $viewModel.habitDescription)
        }

        Section {
          ColorPicker("Select a color", selection: $viewModel.habitColor)
        }

        Section {
          Button(action: { Task { await createHabit() } }) {
            if viewModel.isLoading {
              ProgressView()
            } else {
              Text("Create Habit")
                .foregroundColor(.blue)
            }
          }
          .disabled(!viewModel.isFormValid || viewModel.isLoading)
        }

        if let error = viewModel.errorMessage {
          Section {
            Text(error)
              .font(.caption)
              .foregroundColor(.red)
          }
        }
      }
      .navigationTitle("New Habit")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }

  private func createHabit() async {
    await viewModel.createHabit()
    if viewModel.errorMessage == nil {
      dismiss()
    }
  }
}

#Preview {
  CreateHabitView()
}
