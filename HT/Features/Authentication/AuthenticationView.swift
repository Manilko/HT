//
//  AuthenticationView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct AuthenticationView: View {
  @StateObject private var viewModel = AuthenticationViewModel()
  @EnvironmentObject var coordinator: AppCoordinator

  var body: some View {
    VStack(spacing: 30) {
      VStack(spacing: 10) {
        Text("Habit Tracker")
          .font(.system(size: 34, weight: .bold))

        Text("Build better habits")
          .font(.subheadline)
          .foregroundColor(.gray)
      }

      Spacer()

      VStack(spacing: 15) {
        Button(action: { Task { await viewModel.signInWithGoogle() } }) {
          HStack(spacing: 12) {
            Image(systemName: "g.circle.fill")
              .font(.system(size: 20))

            Text("Sign in with Google")
              .font(.system(size: 16, weight: .semibold))

            Spacer()
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .padding(.horizontal, 20)
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
        }
        .disabled(viewModel.isLoading)

        Button(action: { Task { await viewModel.signInWithGitHub() } }) {
          HStack(spacing: 12) {
            Image(systemName: "github")
              .font(.system(size: 20))

            Text("Sign in with GitHub")
              .font(.system(size: 16, weight: .semibold))

            Spacer()
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .padding(.horizontal, 20)
          .background(Color.black)
          .foregroundColor(.white)
          .cornerRadius(10)
        }
        .disabled(viewModel.isLoading)
      }

      if viewModel.isLoading {
        ProgressView()
          .padding()
      }

      if let error = viewModel.errorMessage {
        Text(error)
          .font(.caption)
          .foregroundColor(.red)
          .padding()
          .frame(maxWidth: .infinity)
          .background(Color.red.opacity(0.1))
          .cornerRadius(8)
      }

      Spacer()
    }
    .padding(20)
    .background(Color(.systemBackground))
    .onChange(of: viewModel.isAuthenticated) { oldValue, newValue in
      if newValue {
        coordinator.setAuthenticated(true)
      }
    }
  }
}

#Preview {
  AuthenticationView()
    .environmentObject(AppCoordinator())
}
