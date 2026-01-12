//
//  GoalsStore.swift
//  GoalTracker
//
//  Created by Joshua Browning on 12/31/25.
//

import Foundation
import SwiftUI
internal import Combine

/// An observable object that manages a collection of goals.
@MainActor
final class GoalsStore: ObservableObject {
    
    /// The list of goals.
    @Published var goals: [Goal] = []

    /// Initializes the store with an optional list of goals.
    /// - Parameter goals: The initial goals to store. Defaults to an empty array.
    init(goals: [Goal] = []) {
        self.goals = goals
    }

    /// Adds a new goal with the given name.
    /// - Parameter name: The name of the goal to add.
    func add(name: String, completed: Bool) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        goals.append(Goal(name: trimmed, completed: completed))
    }

    /// Deletes goals at the specified offsets.
    /// - Parameter offsets: The index set of goals to delete.
    func delete(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
    }

    /// Deletes a goal with the specified ID.
    /// - Parameter id: The identifier of the goal to delete.
    func delete(id: Goal.ID) {
        if let idx = goals.firstIndex(where: { $0.id == id }) {
            goals.remove(at: idx)
        }
    }
}

