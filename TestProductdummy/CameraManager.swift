//
//  CameraManager.swift
//  TestProductdummy
//
//  Created by GitHub Copilot on 12/16/25.
//

import AVFoundation
import UIKit
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var captureSession: AVCaptureSession?
    @Published var permissionGranted = false
    @Published var videoDimensions: CGSize = .zero
    
    var videoOutput: AVCaptureVideoDataOutput?
    var sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.setupCaptureSession()
                    }
                }
            }
        default:
            permissionGranted = false
        }
    }
    
    func setupCaptureSession() {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            return
        }
        
        session.addInput(videoInput)
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            videoOutput = output
            
            // Get the actual video dimensions from the connection
            if let connection = output.connection(with: .video),
               let formatDescription = connection.inputPorts.first?.formatDescription {
                let dimensions = formatDescription.dimensions
                DispatchQueue.main.async {
                    self.videoDimensions = CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
                }
            }
        }
        
        session.commitConfiguration()
        
        DispatchQueue.main.async {
            self.captureSession = session
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func setDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        sampleBufferDelegate = delegate
        videoOutput?.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "videoQueue"))
    }
}
