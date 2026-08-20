//
//  AuthView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct AuthView: View {
  @StateObject private var viewModel: AuthViewModel

  init(viewModel: AuthViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    VStack(spacing: 20) {
      Text("Habit Tracker")
        .font(.largeTitle)
        .fontWeight(.bold)

      Spacer()

      Button(action: {
        // Sign in with Google
      }) {
        Label("Sign in with Google", systemImage: "g.circle")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
      }

      Button(action: {
        // Sign in with GitHub
      }) {
        Label("Sign in with GitHub", systemImage: "github")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.black)
          .foregroundColor(.white)
          .cornerRadius(8)
      }

      Spacer()
    }
    .padding()
  }
}

#Preview {
  AuthView(viewModel: AuthViewModel(authService: MockAuthService()))
}
