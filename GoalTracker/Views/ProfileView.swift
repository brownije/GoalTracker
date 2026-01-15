//
//  ProfileView.swift
//  GoalTracker
//
//  Created by Joshua Browning on 1/14/26.
//

import SwiftUI

struct ProfileView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var fullName: String = ""
    
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Public Information")) {
                    TextField("Username", text: $username)
                    TextField("Full Name", text: $fullName)
                }
                
                Section {
                    Button("Update Profile") {
                        updateProfile()
                    }
                }
            }
        }
        .navigationTitle("Edit Profile")
        .task {
            await getInitialProfile()
        }
    }
    
    func getInitialProfile() async {
        // Backend handling
        print("Getting profile...")
    }
    
    func updateProfile() {
        // MARK: TODO: Add pfp func
        print("Updating profile...")
    }
}

#Preview {
    ProfileView()
}
