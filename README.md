# iOS Hand Gesture Recognition

A real-time iOS application that detects hands and visualizes hand landmarks using Google's MediaPipe Tasks Vision framework. Built with SwiftUI and AVFoundation.

## 📱 Features

- **Real-time Hand Tracking**: Detects hands and gestures instantly from the camera feed.
- **Landmark Visualization**: Draws skeletal overlays on detected hands (21 landmarks per hand).
- **Multi-Hand Support**: Capable of tracking multiple hands simultaneously (configured for up to 2).
- **SwiftUI Interface**: Modern, declarative UI with a custom `Canvas` overlay for high-performance rendering.
- **Front Camera Support**: Optimized for selfie-mode interaction with correct mirroring and coordinate transformation.

## 🛠 Tech Stack

- **Language**: Swift 5
- **UI Framework**: SwiftUI
- **Camera**: AVFoundation
- **ML Engine**: [MediaPipe Tasks Vision](https://developers.google.com/mediapipe/solutions/vision/gesture_recognizer)
- **Dependency Manager**: CocoaPods

## 📋 Requirements

- iOS 15.0+
- Xcode 13.0+
- Physical iOS device (Camera access is required)

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/bajend/handgesture.git
   cd handgesture
   ```

2. **Install Dependencies**
   This project uses CocoaPods to manage the MediaPipe dependency.
   ```bash
   pod install
   ```

3. **Open the Workspace**
   ⚠️ **Important**: Always open the `.xcworkspace` file, not the `.xcodeproj`.
   ```bash
   open TestProductdummy.xcworkspace
   ```

4. **Build and Run**
   - Select your physical iOS device in Xcode.
   - Build and run (Cmd + R).
   - Grant camera permissions when prompted.

## 🧩 Project Structure

- **`ContentView.swift`**: The main entry point. Orchestrates the `CameraView` and the `HandLandmarksOverlayView`.
- **`CameraManager.swift`**: Manages the `AVCaptureSession`, camera permissions, and video output.
- **`GestureRecognizerService.swift`**: The core logic wrapper for MediaPipe. Handles model loading and asynchronous image processing.
- **`HandLandmarksOverlayView.swift`**: A SwiftUI View that uses `Canvas` to draw lines and dots corresponding to hand joints.
- **`gesture_recognizer.task`**: The pre-trained MediaPipe model file.

## 🔧 Implementation Details

The app captures video frames, converts them to `MPImage`, and passes them to the MediaPipe Gesture Recognizer. The results (landmarks) are then transformed from normalized coordinates (0-1) to screen coordinates, accounting for:
- Device rotation
- Video aspect ratio (Aspect Fill)
- Front camera mirroring

## 📄 License

This project uses the MediaPipe framework which is subject to the Apache 2.0 License.
