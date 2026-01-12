//
//  CameraView.swift
//  GoalTracker
//
//  Created by Joshua Browning on 1/9/26.
//

import SwiftUI
import AVFoundation

final class CameraPreviewContainerView: UIView {
    let previewLayer: AVCaptureVideoPreviewLayer

    init(session: AVCaptureSession) {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

struct PreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewContainerView {
        CameraPreviewContainerView(session: session)
    }

    func updateUIView(_ uiView: CameraPreviewContainerView, context: Context) {
        // No-op; layoutSubviews keeps the preview layer sized correctly.
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        // Keeping the type for future expansion; no state needed now.
    }
}

struct CameraView: View {
    @StateObject private var camera = CameraManager()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main back camera preview
            PreviewView(session: camera.session)
                .ignoresSafeArea()

            // Picture-in-picture style small preview (placeholder)
            // TODO: Replace with a true front-camera or multicam session when available.
            PreviewView(session: camera.session)
                .frame(width: 140, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .shadow(radius: 6, y: 3)
                .padding()
        }
        .task {
            // Request permission, configure, and start the session
            if await camera.requestPermission() {
                camera.configureSession()
                camera.start()
            }
        }
        .onDisappear {
            camera.stop()
        }
    }
}

#Preview {
    CameraView()
}
