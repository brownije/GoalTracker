//
//  AuthView.swift
//  GoalTracker
//
//  Created by Joshua Browning on 1/14/26.
//


import SwiftUI
import Supabase

struct AuthView: View {
  @State var email = ""
  @State var password = ""
  @State var isLoading = false
  @State var result: Result<Void, Error>?

  var body: some View {
    Form {
      Section {
        TextField("Email", text: $email)
          .textContentType(.emailAddress)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
      }
        
        Section {
            TextField("Password", text: $password)
                .textContentType(.password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }

      Section {
        Button("Sign in") {
          signInButtonTapped()
        }

        if isLoading {
          ProgressView()
        }
      }

      if let result {
        Section {
          switch result {
          case .success:
            Text("Verify your email.")
          case .failure(let error):
            Text(error.localizedDescription).foregroundStyle(.red)
          }
        }
      }
    }
  }

  func signInButtonTapped() {
    Task {
      isLoading = true
      defer { isLoading = false }

      do {
          try await supabase.auth.signIn(
            email: email,
            password: "password"
        )
        result = .success(())
      } catch {
        result = .failure(error)
      }
    }
  }
}

#Preview {
    AuthView()
}
