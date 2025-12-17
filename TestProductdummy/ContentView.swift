//
//  ContentView.swift
//  TestProductdummy
//
//  Created by Ajendla, Bharath on 12/16/25.
//

import SwiftUI
import AVFoundation
import Combine
import MediaPipeTasksVision

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var viewModel = GestureRecognitionViewModel()
    
    var body: some View {
        ZStack {
            // Camera preview
            if cameraManager.permissionGranted {
                GeometryReader { geometry in
                    ZStack {
                        CameraView(captureSession: $cameraManager.captureSession)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .onAppear {
                                viewModel.setupCameraManager(cameraManager)
                                viewModel.viewSize = geometry.size
                            }
                        
                        // Hand landmarks overlay
                        if !viewModel.handLandmarks.isEmpty {
                            HandLandmarksOverlayView(
                                landmarks: viewModel.handLandmarks,
                                imageSize: cameraManager.videoDimensions,
                                viewSize: geometry.size
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
                .ignoresSafeArea()
                
                // Simple status overlay
                VStack {
                    HStack {
                        if !viewModel.handLandmarks.isEmpty {
                            Text("✋ Hand Detected: \(viewModel.handLandmarks.count)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.green.opacity(0.7))
                                .cornerRadius(8)
                        } else {
                            Text("👋 Show your hand")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .imageScale(.large)
                        .font(.system(size: 60))
                        .foregroundStyle(.tint)
                    
                    Text("Camera Access Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Please grant camera permission in Settings to use gesture recognition.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
        }
    }
}

// MARK: - View Model
class GestureRecognitionViewModel: NSObject, ObservableObject {
    @Published var handLandmarks: [[NormalizedLandmark]] = []
    @Published var detectedGesture: String?
    @Published var handedness: String?
    @Published var confidence: Float?
    
    var viewSize: CGSize = .zero
    weak var cameraManager: CameraManager?
    
    private var gestureRecognizerService: GestureRecognizerService?
    private var lastProcessedTime: Int = 0
    private let processingInterval = 33 // Process every 33ms (~30 FPS)
    
    func setupCameraManager(_ cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        
        // Initialize gesture recognizer with live stream mode
        gestureRecognizerService = GestureRecognizerService(
            modelPath: "gesture_recognizer",
            runningMode: .liveStream
        )
        gestureRecognizerService?.delegate = self
        
        // Set self as the sample buffer delegate
        cameraManager.setDelegate(self)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension GestureRecognitionViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, 
                      didOutput sampleBuffer: CMSampleBuffer, 
                      from connection: AVCaptureConnection) {
        let currentTime = Int(Date().timeIntervalSince1970 * 1000)
        
        // Update video dimensions from the actual sample buffer
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            let dimensions = CGSize(width: width, height: height)
            
            // Update camera manager's video dimensions if they haven't been set yet
            if cameraManager?.videoDimensions == .zero {
                DispatchQueue.main.async {
                    self.cameraManager?.videoDimensions = dimensions
                }
            }
        }
        
        // Throttle processing to avoid overwhelming the system
        guard currentTime - lastProcessedTime >= processingInterval else {
            return
        }
        
        lastProcessedTime = currentTime
        gestureRecognizerService?.recognizeAsync(sampleBuffer: sampleBuffer, timestampMs: currentTime)
    }
}

// MARK: - GestureRecognizerServiceDelegate
extension GestureRecognitionViewModel: GestureRecognizerServiceDelegate {
    func gestureRecognizerService(_ service: GestureRecognizerService, 
                                 didRecognizeGestures result: GestureRecognizerResult) {
        DispatchQueue.main.async {
            // Update hand landmarks for visualization
            self.handLandmarks = result.landmarks
            
            // Update gesture info (optional)
            if let gesture = result.gestures.first?.first {
                self.detectedGesture = gesture.categoryName
                self.confidence = gesture.score
                
                if let hand = result.handedness.first?.first {
                    self.handedness = hand.categoryName
                }
            } else {
                self.detectedGesture = nil
                self.handedness = nil
                self.confidence = nil
            }
        }
    }
    
    func gestureRecognizerService(_ service: GestureRecognizerService, 
                                 didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.handLandmarks = []
        }
    }
}

#Preview {
    ContentView()
}
