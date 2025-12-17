//
//  CameraView.swift
//  TestProductdummy
//
//  Created by GitHub Copilot on 12/16/25.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @Binding var captureSession: AVCaptureSession?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let captureSession = captureSession else { return }
        
        // Remove existing preview layers
        uiView.layer.sublayers?.removeAll(where: { $0 is AVCaptureVideoPreviewLayer })
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = uiView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        uiView.layer.addSublayer(previewLayer)
    }
}
