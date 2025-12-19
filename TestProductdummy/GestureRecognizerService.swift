//
//  GestureRecognizerService.swift
//  TestProductdummy
//
//  Created by GitHub Copilot on 12/16/25.
//

import Foundation
import AVFoundation
import UIKit
import MediaPipeTasksVision

/// Service class to handle MediaPipe gesture recognition
class GestureRecognizerService: NSObject {
    
    // MARK: - Properties
    var gestureRecognizer: GestureRecognizer?
    weak var delegate: GestureRecognizerServiceDelegate?
    
    // MARK: - Configuration
    private let modelPath: String
    private let runningMode: RunningMode
    private let minHandDetectionConfidence: Float = 0.5
    private let minHandPresenceConfidence: Float = 0.5
    private let minTrackingConfidence: Float = 0.5
    private let numHands: Int = 2
    
    // MARK: - Initialization
    init(modelPath: String, runningMode: RunningMode = .image) {
        self.modelPath = modelPath
        self.runningMode = runningMode
        super.init()
        setupGestureRecognizer()
    }
    
    // MARK: - Setup
    private func setupGestureRecognizer() {
        guard let modelPath = Bundle.main.path(forResource: "gesture_recognizer", ofType: "task") else {
            print("Failed to load model file.")
            return
        }
        
        let options = GestureRecognizerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = runningMode
        options.minHandDetectionConfidence = minHandDetectionConfidence
        options.minHandPresenceConfidence = minHandPresenceConfidence
        options.minTrackingConfidence = minTrackingConfidence
        options.numHands = numHands
        
        // Set up delegate for live stream mode
        if runningMode == .liveStream {
            options.gestureRecognizerLiveStreamDelegate = self
        }
        
        do {
            gestureRecognizer = try GestureRecognizer(options: options)
        } catch {
            print("❌ Failed to create gesture recognizer: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Recognition Methods
    
    /// Recognize gestures in a still image
    func recognizeImage(_ image: UIImage) -> GestureRecognizerResult? {
        guard let mpImage = try? MPImage(uiImage: image) else {
            print("Failed to convert UIImage to MPImage")
            return nil
        }
        
        do {
            let result = try gestureRecognizer?.recognize(image: mpImage)
            return result
        } catch {
            print("Failed to recognize gestures: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Recognize gestures in a video frame
    func recognizeVideoFrame(_ image: UIImage, timestampMs: Int) -> GestureRecognizerResult? {
        guard let mpImage = try? MPImage(uiImage: image) else {
            print("Failed to convert UIImage to MPImage")
            return nil
        }
        
        do {
            let result = try gestureRecognizer?.recognize(videoFrame: mpImage, timestampInMilliseconds: timestampMs)
            return result
        } catch {
            print("Failed to recognize gestures in video: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Recognize gestures in a live stream (async)
    func recognizeAsync(sampleBuffer: CMSampleBuffer, timestampMs: Int) {
        guard let recognizer = gestureRecognizer else { 
            return 
        }
        guard let mpImage = try? MPImage(sampleBuffer: sampleBuffer) else { 
            return 
        }
        
        do {
            try recognizer.recognizeAsync(image: mpImage, timestampInMilliseconds: timestampMs)
        } catch {
            print("Failed to recognize gestures: \(error.localizedDescription)")
        }
    }
}

// MARK: - GestureRecognizerLiveStreamDelegate
extension GestureRecognizerService: GestureRecognizerLiveStreamDelegate {
    public func gestureRecognizer(_ gestureRecognizer: GestureRecognizer, 
                                  didFinishGestureRecognition result: GestureRecognizerResult?, 
                                  timestampInMilliseconds: Int, 
                                  error: Error?) {
        if let error = error {
            delegate?.gestureRecognizerService(self, didFailWithError: error)
            return
        }
        
        if let result = result {
            delegate?.gestureRecognizerService(self, didRecognizeGestures: result, worldLandmarks: result.worldLandmarks)
        }
    }
}

// MARK: - Delegate Protocol
protocol GestureRecognizerServiceDelegate: AnyObject {
    func gestureRecognizerService(_ service: GestureRecognizerService, didRecognizeGestures result: GestureRecognizerResult, worldLandmarks: [[Landmark]])
    func gestureRecognizerService(_ service: GestureRecognizerService, didFailWithError error: Error)
}
