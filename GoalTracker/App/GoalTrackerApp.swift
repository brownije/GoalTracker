//
//  GoalTrackerApp.swift
//  GoalTracker
//
//  Created by Joshua Browning on 12/31/25.
//

import SwiftUI
import Supabase

@main
struct GoalTrackerApp: App {
    
    @State var isAuthenticated = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    HomeView()
                } else {
                    AuthView()
                }
            }
            .task {
                for await state in supabase.auth.authStateChanges {
                    if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                        isAuthenticated = state.session != nil
                    }
                }
            }
        }
    }
}
