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
    @Published var isMultiCamSupported: Bool = AVCaptureMultiCamSession.isMultiCamSupported
    @Published var isConfigured = false
    @Published var configurationError: String?
    
    // Public session that a preview layer or SwiftUI wrapper can use later
    let session: AVCaptureSession = {
        if AVCaptureMultiCamSession.isMultiCamSupported {
            return AVCaptureMultiCamSession()
        } else {
            return AVCaptureSession()
        }
    }()
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var frontInput: AVCaptureDeviceInput?
    private var backInput: AVCaptureDeviceInput?
    private var frontPhotoOutput: AVCapturePhotoOutput?
    private var backPhotoOutput: AVCapturePhotoOutput?
    
    // Expose video preview connections for UI layers/wrappers
    private(set) var frontPreviewPort: AVCaptureInput.Port?
    private(set) var backPreviewPort: AVCaptureInput.Port?

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

    // Capture session for BACK camera or multi-cam if supported
    func configureSession() {
        guard !isConfigured else { return }

        sessionQueue.sync {
            session.beginConfiguration()
            defer { session.commitConfiguration() }

            configurationError = nil

            // Preset: choose a reasonable quality for multi-cam
            if session.canSetSessionPreset(.high) {
                session.sessionPreset = .high
            }

            // Discover devices
            let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)

            // Helper to add input for a device
            func addInput(for device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
                guard let device else { return nil }
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if session.canAddInput(input) {
                        session.addInput(input)
                        return input
                    }
                } catch {
                    configurationError = "Failed to create device input: \(error.localizedDescription)"
                }
                return nil
            }

            if AVCaptureMultiCamSession.isMultiCamSupported, let multi = session as? AVCaptureMultiCamSession {
                // Try to add both inputs and two photo outputs
                backInput = addInput(for: backDevice)
                frontInput = addInput(for: frontDevice)

                // Track preview ports (the first video port of each input)
                backPreviewPort = backInput?.ports.first(where: { $0.mediaType == .video })
                frontPreviewPort = frontInput?.ports.first(where: { $0.mediaType == .video })

                // Outputs
                let backOut = AVCapturePhotoOutput()
                let frontOut = AVCapturePhotoOutput()

                if multi.canAddOutput(backOut) { multi.addOutput(backOut); backPhotoOutput = backOut }
                if multi.canAddOutput(frontOut) { multi.addOutput(frontOut); frontPhotoOutput = frontOut }

                // If we couldn't add both inputs/outputs, mark an error to fallback
                if backInput == nil || frontInput == nil || backPhotoOutput == nil || frontPhotoOutput == nil {
                    configurationError = configurationError ?? "Multi-cam configuration incomplete; falling back to single camera."
                    // Clean up and fall back
                    multi.inputs.forEach { multi.removeInput($0) }
                    multi.outputs.forEach { multi.removeOutput($0) }
                }
            }

            // Fallback to single back camera (or front if back not available)
            if !AVCaptureMultiCamSession.isMultiCamSupported || (backPhotoOutput == nil && frontPhotoOutput == nil) {
                // Ensure we are working with a standard AVCaptureSession
                let usableSession: AVCaptureSession
                if let multi = session as? AVCaptureMultiCamSession {
                    // Recreate a standard session if needed
                    let newSession = AVCaptureSession()
                    // Transfer preset
                    newSession.sessionPreset = session.sessionPreset
                    // Swap the session reference is not possible here since it's a let; so we just reconfigure using the existing session
                    // We will simply configure the existing session with single camera inputs/outputs below
                    _ = newSession // placeholder to avoid unused warning in this scope
                }

                // Remove any existing inputs/outputs (if coming from failed multi-cam)
                session.inputs.forEach { session.removeInput($0) }
                session.outputs.forEach { session.removeOutput($0) }

                // Choose preferred device: back first, else front
                let preferred = backDevice ?? frontDevice
                let input = addInput(for: preferred)
                backInput = input
                frontInput = nil
                backPreviewPort = input?.ports.first(where: { $0.mediaType == .video })
                frontPreviewPort = nil

                let output = AVCapturePhotoOutput()
                if session.canAddOutput(output) { session.addOutput(output); backPhotoOutput = output; frontPhotoOutput = nil }

                if input == nil || backPhotoOutput == nil {
                    configurationError = configurationError ?? "Failed to configure camera session."
                }
            }

            self.isConfigured = configurationError == nil
        }
    }

    // Start running the session if configured and authorized
    func start() {
        let configured = self.isConfigured
        let session = self.session
        sessionQueue.async {
            guard configured, !session.isRunning else { return }
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

    // MARK: - Capture Photos
    func captureBackPhoto(settings: AVCapturePhotoSettings = AVCapturePhotoSettings(), delegate: AVCapturePhotoCaptureDelegate) {
        sessionQueue.async { [weak self] in
            guard let self, let output = self.backPhotoOutput else { return }
            output.capturePhoto(with: settings, delegate: delegate)
        }
    }
    func captureFrontPhoto(settings: AVCapturePhotoSettings = AVCapturePhotoSettings(), delegate: AVCapturePhotoCaptureDelegate) {
        sessionQueue.async { [weak self] in
            guard let self, let output = self.frontPhotoOutput else { return }
            output.capturePhoto(with: settings, delegate: delegate)
        }
    }

    // MARK: - Preview Ports Accessors
    func frontVideoPort() -> AVCaptureInput.Port? { frontPreviewPort }
    func backVideoPort() -> AVCaptureInput.Port? { backPreviewPort }
}

