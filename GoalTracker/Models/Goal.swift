//
//  Goal.swift
//  GoalTracker
//
//  Created by Joshua Browning on 12/31/25.
//

import SwiftUI

struct Goal: Hashable, Identifiable {
    let id: UUID // Unique Identifier
    var name: String
    var completed: Bool

    // Initialize the goal with a stable id and optional completed flag
    init(id: UUID = UUID(), name: String, completed: Bool) {
        self.id = id
        self.name = name
        self.completed = completed
    }
}
