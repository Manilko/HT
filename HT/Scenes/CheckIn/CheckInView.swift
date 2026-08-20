//
//  CheckInView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct CheckInView: View {
  @StateObject private var viewModel: CheckInViewModel
  let habitId: Int

  init(habitId: Int, viewModel: CheckInViewModel) {
    self.habitId = habitId
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    VStack(spacing: 20) {
      Text("Log Check-in")
        .font(.title2)

      TextField("Add notes (optional)", text: $viewModel.notes)
        .textFieldStyle(.roundedBorder)
        .padding()

      Button(action: {
        Task {
          await viewModel.logCheckIn(habitId: habitId)
        }
      }) {
        Text("Log Check-in")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.green)
          .foregroundColor(.white)
          .cornerRadius(8)
      }
      .disabled(viewModel.isLoading)

      Spacer()
    }
    .padding()
  }
}

#Preview {
  CheckInView(habitId: 1, viewModel: CheckInViewModel(habitService: MockHabitService()))
}
