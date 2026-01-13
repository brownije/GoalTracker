//
//  Camera.swift
//  GoalTracker
//
//  Created by Joshua Browning on 1/9/26.
//

import Foundation
import SwiftUI
@preconcurrency import AVFoundation
internal import Combine

@MainActor
final class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    
    @Published var isMultiCamSupported: Bool = AVCaptureMultiCamSession.isMultiCamSupported
    @Published var isConfigured = false
    @Published var configurationError: String?
    @Published var lastCapturedImage: UIImage?
    @Published var isCapturing: Bool = false
    
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
        let alreadyConfigured = self.isConfigured
        let session = self.session
        guard !alreadyConfigured else { return }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            var newBackInput: AVCaptureDeviceInput? = nil
            var newFrontInput: AVCaptureDeviceInput? = nil
            var newBackPhotoOutput: AVCapturePhotoOutput? = nil
            var newFrontPhotoOutput: AVCapturePhotoOutput? = nil
            var newBackPreviewPort: AVCaptureInput.Port? = nil
            var newFrontPreviewPort: AVCaptureInput.Port? = nil
            
            var localConfigurationError: String? = nil
            session.beginConfiguration()
            defer { session.commitConfiguration() }
            
            localConfigurationError = nil

            // Configure session preset depending on session type
            if let multi = session as? AVCaptureMultiCamSession {
                // AVCaptureMultiCamSession does NOT support .photo preset
                if multi.canSetSessionPreset(.high) {
                    multi.sessionPreset = .high
                }
            } else {
                // Regular AVCaptureSession: prefer .photo, else fall back to .high
                if session.canSetSessionPreset(.photo) {
                    session.sessionPreset = .photo
                } else if session.canSetSessionPreset(.high) {
                    session.sessionPreset = .high
                }
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
                    localConfigurationError = "Failed to create device input: \(error.localizedDescription)"
                }
                return nil
            }

            if AVCaptureMultiCamSession.isMultiCamSupported, let multi = session as? AVCaptureMultiCamSession {
                // Try to add both inputs and two photo outputs
                newBackInput = addInput(for: backDevice)
                newFrontInput = addInput(for: frontDevice)

                // Track preview ports (the first video port of each input)
                newBackPreviewPort = newBackInput?.ports.first(where: { $0.mediaType == .video })
                newFrontPreviewPort = newFrontInput?.ports.first(where: { $0.mediaType == .video })

                // Outputs
                let backOut = AVCapturePhotoOutput()
                let frontOut = AVCapturePhotoOutput()
                
                if multi.canAddOutput(backOut) { multi.addOutput(backOut); newBackPhotoOutput = backOut }
                if multi.canAddOutput(frontOut) { multi.addOutput(frontOut); newFrontPhotoOutput = frontOut }

                // If we couldn't add both inputs/outputs, mark an error to fallback
                if newBackInput == nil || newFrontInput == nil || newBackPhotoOutput == nil || newFrontPhotoOutput == nil {
                    localConfigurationError = localConfigurationError ?? "Multi-cam configuration incomplete; falling back to single camera."
                    // Clean up and fall back
                    multi.inputs.forEach { multi.removeInput($0) }
                    multi.outputs.forEach { multi.removeOutput($0) }
                }
            } else {
                // Single-camera (back) configuration
                if let input = addInput(for: backDevice) {
                    newBackInput = input
                    newBackPreviewPort = input.ports.first(where: { $0.mediaType == .video })
                } else {
                    localConfigurationError = localConfigurationError ?? "Unable to add back camera input."
                }

                let output = AVCapturePhotoOutput()
                if session.canAddOutput(output) {
                    session.addOutput(output)
                    newBackPhotoOutput = output
                } else {
                    localConfigurationError = localConfigurationError ?? "Unable to add photo output."
                }
            }
            
            let capturedConfigurationError = localConfigurationError
            let capturedBackInput = newBackInput
            let capturedFrontInput = newFrontInput
            let capturedBackPhotoOutput = newBackPhotoOutput
            let capturedFrontPhotoOutput = newFrontPhotoOutput
            let capturedBackPreviewPort = newBackPreviewPort
            let capturedFrontPreviewPort = newFrontPreviewPort

            Task { @MainActor in
                self.configurationError = capturedConfigurationError
                if capturedConfigurationError == nil {
                    self.backInput = capturedBackInput
                    self.frontInput = capturedFrontInput
                    self.backPhotoOutput = capturedBackPhotoOutput
                    self.frontPhotoOutput = capturedFrontPhotoOutput
                    self.backPreviewPort = capturedBackPreviewPort
                    self.frontPreviewPort = capturedFrontPreviewPort
                    self.isConfigured = true
                } else {
                    self.isConfigured = false
                }
            }
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
        let session = self.session
        sessionQueue.async {
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    // MARK: - Capture Photos
    func captureBackPhoto(settings: AVCapturePhotoSettings = AVCapturePhotoSettings(), delegate: AVCapturePhotoCaptureDelegate) {
        let output = self.backPhotoOutput
        sessionQueue.async {
            guard let output = output else { return }
            output.capturePhoto(with: settings, delegate: delegate)
        }
    }
    func captureFrontPhoto(settings: AVCapturePhotoSettings = AVCapturePhotoSettings(), delegate: AVCapturePhotoCaptureDelegate) {
        let output = self.frontPhotoOutput
        sessionQueue.async {
            guard let output = output else { return }
            output.capturePhoto(with: settings, delegate: delegate)
        }
    }

    func capturePhoto() {
        // Prefer back camera if available, else front
        if backPhotoOutput != nil {
            captureBackPhoto(delegate: self)
        } else if frontPhotoOutput != nil {
            captureFrontPhoto(delegate: self)
        }
    }

    // MARK: - Preview Ports Accessors
    func frontVideoPort() -> AVCaptureInput.Port? { frontPreviewPort }
    func backVideoPort() -> AVCaptureInput.Port? { backPreviewPort }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Photo processing error: \(error)")
            return
        }
        if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            self.lastCapturedImage = image
        }
    }

    // MARK: - UI Helpers
    @ViewBuilder
    func captureButton() -> some View {
        Button(action: {
            self.capturePhoto()
        }) {
            ZStack {
                Circle().stroke(Color.white, lineWidth: 3).frame(width: 66, height: 66)
                Circle().fill(Color.white).frame(width: 56, height: 56)
            }
        }
        .accessibilityLabel(Text("Capture Photo"))
    }
}

