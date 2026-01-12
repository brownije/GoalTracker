//
//  HomeView.swift
//  GoalTracker
//
//  Created by Joshua Browning on 12/31/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var store = GoalsStore(
        goals: [
            Goal(name: "Work out", completed: false),
            Goal(name: "Errands", completed: true)
        ]
    )

    @State private var showingCreate = false
    @State private var editingGoal: Goal?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray4)
                    .ignoresSafeArea()

                List {
                    ForEach(store.goals) { goal in
                        NavigationLink(value: goal) {
                            HStack {
                                Text(goal.name)
                                Spacer()
                                if goal.completed {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        // Swipe R-L to delete
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if let index = store.goals.firstIndex(where: { $0.id == goal.id }) {
                                    store.goals.remove(at: index)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        // Swipe L-R to edit
                        .swipeActions(edge: .leading) {
                            Button {
                                editingGoal = goal
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                        }
                    }
                    .onDelete(perform: store.delete)
                    
                    Section(footer:
                        HStack {
                            Spacer()
                            Button {
                                showingCreate = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Add Goal")
                                }
                                .font(.title)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 12)
                    ) {
                        EmptyView() // Nothing
                    }
                }
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 70)
                .font(.title3)
            }
            .sheet(item: $editingGoal) { goal in
                GoalView(goal: goal, isNew: false) { name in
                    if let idx = store.goals.firstIndex(where: { $0.id == goal.id }) {
                        store.goals[idx].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    editingGoal = nil
                }
            }
            .sheet(isPresented: $showingCreate) {
                GoalView(goal: Goal(name: "", completed: false), isNew: true) { name in
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    store.add(name: trimmed, completed: false)
                    showingCreate = false
                }
            }
            .navigationTitle("Goals to complete: \(store.goals.count)")
            // Complete goal
            .navigationDestination(for: Goal.self) { goal in
                CompleteGoalView()
            }
        }
    }
}

#Preview {
    HomeView()
}
