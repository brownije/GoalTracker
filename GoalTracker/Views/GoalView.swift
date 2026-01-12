//
//  CreateGoalView.swift
//  GoalTracker
//
//  Created by Joshua Browning on 12/31/25.
//

import SwiftUI

struct GoalView: View {
    @Environment(\.dismiss) var dismiss
    let goal: Goal?
    let isNew: Bool

    // Specify creation or edit
    let onSave: (String) -> Void
 
    @State private var name: String = ""
    
    init(goal: Goal, isNew: Bool, onSave: @escaping (String) -> Void) {
        self.isNew = isNew
        self.goal = isNew ? goal : goal as Goal
        self.onSave = onSave
        _name = State(initialValue: goal.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Goal name", text: $name)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("\(name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

