//
//  Camera.swift
//  GoalTracker
//
//  Created by Joshua Browning on 1/9/26.
//

import Foundation
import SwiftUI
import AVFoundation
internal import Combine

// Camera manager for later CameraView
final class CameraManager: ObservableObject {
    var objectWillChange: ObservableObjectPublisher = .init()
    
    
    // Public session that a preview layer or SwiftUI wrapper can use later
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var photoOutput: AVCapturePhotoOutput?
    private var isConfigured = false

    // Request camera permission
    func requestPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    // Capture session for BACK camera
    func configureSession() {
        guard !isConfigured else { return }

        sessionQueue.sync {
            session.beginConfiguration()
            defer { session.commitConfiguration() }

            // Preset
            if session.canSetSessionPreset(.photo) {
                session.sessionPreset = .photo
            }

            // Input: back wide angle camera
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
            } catch {
                print("CameraManager: Failed to create/add device input - \(error.localizedDescription)")
                return
            }

            // Output: photo
            let photoOutput = AVCapturePhotoOutput()
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                self.photoOutput = photoOutput
            }

            self.isConfigured = true
        }
    }

    // Start running the session if configured and authorized
    func start() {
          let isConfigured = self.isConfigured
          let session = self.session
          sessionQueue.async {
              guard isConfigured, !session.isRunning else { return }
              session.startRunning()
          }
      }

    // Stop running the session
    func stop() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }
}

