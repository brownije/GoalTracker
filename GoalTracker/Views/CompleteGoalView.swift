//
//  CompleteGoalView.swift
//  GoalTracker
//
//  Created by Joshua Browning on 1/8/26.
//

import SwiftUI

// SwiftUI wrapper for CameraController (assumed to be a UIViewController subclass)
struct CameraControllerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraController {
        CameraController()
    }

    func updateUIViewController(_ uiViewController: CameraController, context: Context) {
        // Update the view controller if needed
    }
}

struct CompleteGoalView: View {
    var body: some View {
        CameraControllerView()
    }
}

#Preview {
    CompleteGoalView()
}
