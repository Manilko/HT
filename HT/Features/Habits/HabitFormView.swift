//
//  HabitFormView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct HabitFormView: View {
  @StateObject var viewModel: HabitFormViewModel
  @Environment(\.dismiss) var dismiss

  var body: some View {
    Form {
      Section("Habit Details") {
        TextField("Habit name", text: $viewModel.name)
          .accessibilityLabel("Habit name")

        TextField("Description (optional)", text: $viewModel.description, axis: .vertical)
          .lineLimit(3...)
          .accessibilityLabel("Habit description")

        if !viewModel.isEditMode {
          DatePicker("Start date", selection: $viewModel.startDate, displayedComponents: .date)
            .accessibilityLabel("Habit start date")
        }
      }

      if viewModel.isEditMode {
        Section("Info") {
          HStack {
            Text("Start date")
            Spacer()
            Text(formattedStartDate)
              .foregroundColor(.secondary)
          }
        }
      }

      if let errorMessage = viewModel.errorMessage {
        Section {
          VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
              Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)

              VStack(alignment: .leading, spacing: 2) {
                Text("Error")
                  .fontWeight(.semibold)

                Text(errorMessage)
                  .font(.caption)
              }
            }
            .padding(8)
            .background(Color.red.opacity(0.1))
            .cornerRadius(6)
          }
        }
      }
    }
    .navigationTitle(viewModel.titleText)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button("Cancel") {
          dismiss()
        }
      }

      ToolbarItem(placement: .topBarTrailing) {
        Button(viewModel.submitButtonText) {
          Task {
            await viewModel.submit()
            if viewModel.errorMessage == nil {
              dismiss()
            }
          }
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .fontWeight(.semibold)
      }
    }
    .overlay {
      if viewModel.isLoading {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color(.systemBackground).opacity(0.5))
      }
    }
  }

  private var formattedStartDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: viewModel.startDate)
  }
}

#Preview {
  NavigationStack {
    HabitFormView(viewModel: HabitFormViewModel())
  }
}
