//
//  GoalTrackerApp.swift
//  GoalTracker
//
//  Created by Joshua Browning on 12/31/25.
//

import SwiftUI

@main
struct GoalTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab {
                    HomeView()
                }
                Tab {
                    FeedView()
                }
            }
        }
    }
}
