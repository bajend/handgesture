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
    
    @State private var isDeveloperMode = false
    @State private var isBlindMode = false
    @State private var showSaveAlert = false
    @State private var showSaveResultAlert = false
    @State private var mudraName = ""
    @State private var saveMessage = ""
    
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
                                viewModel.listSavedMudras()
                            }
                        
                        // Hand landmarks overlay
                        if !viewModel.handLandmarks.isEmpty && !isBlindMode {
                            HandLandmarksOverlayView(
                                landmarks: viewModel.handLandmarks,
                                imageSize: cameraManager.videoDimensions,
                                viewSize: geometry.size,
                                landmarkErrors: viewModel.currentLandmarkErrors
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
                .ignoresSafeArea()
                
                // Sophisticated Overlay Panel
                if !isBlindMode {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            // Header: Target Mudra Selector
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Target: \(viewModel.targetMudraName)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Random Test Button
                                    Button(action: {
                                        if let randomMudra = viewModel.availableMudras.randomElement() {
                                            viewModel.loadReferenceMudra(named: randomMudra)
                                        }
                                    }) {
                                        Image(systemName: "shuffle")
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.purple.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                    .disabled(viewModel.availableMudras.isEmpty)
                                    
                                    // Developer Mode Toggle
                                    Toggle(isOn: $isDeveloperMode) {
                                        Text("Dev")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                                    .frame(width: 80)
                                }
                                
                                // Horizontal Mudra Selector
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(Array(viewModel.availableMudras.enumerated()), id: \.element) { index, mudra in
                                            Button(action: {
                                                viewModel.loadReferenceMudra(named: mudra)
                                            }) {
                                                Text(mudra)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(viewModel.targetMudraName == mudra ? Color.blue : Color.gray.opacity(0.5))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(15)
                                            }
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    viewModel.deleteMudra(at: IndexSet(integer: index))
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(height: 35)
                            }
                            
                            // Accuracy Score
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Accuracy Score")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    if viewModel.currentLandmarkErrors != nil {
                                        Text("\(Int(viewModel.accuracyScore * 100))%")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(hue: Double(viewModel.accuracyScore) * 0.3, saturation: 1.0, brightness: 1.0))
                                    }
                                }
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .frame(width: geo.size.width, height: 8)
                                            .opacity(0.3)
                                            .foregroundColor(.gray)
                                        
                                        Rectangle()
                                            .frame(width: geo.size.width * CGFloat(viewModel.accuracyScore), height: 8)
                                            .foregroundColor(Color(hue: Double(viewModel.accuracyScore) * 0.3, saturation: 1.0, brightness: 1.0))
                                    }
                                    .cornerRadius(4)
                                }
                                .frame(height: 8)
                                
                                Text("\(Int(viewModel.accuracyScore * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            
                            // Stability
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Stability (X)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(String(format: "%.4f", viewModel.stability.x))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Stability (Y)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(String(format: "%.4f", viewModel.stability.y))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Developer Controls
                            if isDeveloperMode {
                                HStack {
                                    Button(action: {
                                        mudraName = ""
                                        showSaveAlert = true
                                    }) {
                                        Text("Save")
                                            .frame(maxWidth: .infinity)
                                            .padding(8)
                                            .background(Color.blue.opacity(0.8))
                                            .cornerRadius(8)
                                            .foregroundColor(.white)
                                    }
                                    .disabled(viewModel.worldLandmarks.isEmpty)
                                    
                                    // Recording Toggle
                                    Button(action: {
                                        viewModel.toggleRecording()
                                    }) {
                                        HStack {
                                            Image(systemName: viewModel.isRecordingSession ? "stop.circle.fill" : "record.circle")
                                            Text(viewModel.isRecordingSession ? "Stop Log" : "Log Data")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(8)
                                        .background(viewModel.isRecordingSession ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(16)
                        .padding()
                    }
                } else {
                    // Blind Mode UI (Minimal)
                    VStack {
                        Spacer()
                        HStack {
                            Text("Blind Mode Active")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.7))
                                .cornerRadius(10)
                            
                            Spacer()
                            
                            // Recording Toggle (Visible in Blind Mode for Control)
                            Button(action: {
                                viewModel.toggleRecording()
                            }) {
                                Image(systemName: viewModel.isRecordingSession ? "stop.circle.fill" : "record.circle")
                                    .font(.title)
                                    .foregroundColor(viewModel.isRecordingSession ? .red : .green)
                            }
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                        }
                        .padding()
                    }
                }
                
                // Global Toggle for Blind Mode (Top Left)
                VStack {
                    HStack {
                        Toggle(isOn: $isBlindMode) {
                            Text("Blind Mode")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                        .frame(width: 120)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding()
                        
                        Spacer()
                    }
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
        .alert("Save Mudra", isPresented: $showSaveAlert) {
            TextField("Mudra Name", text: $mudraName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveMudra()
            }
        } message: {
            Text("Enter a name for this mudra pose.")
        }
        .alert("Save Result", isPresented: $showSaveResultAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveMessage)
        }
    }
    
    private func saveMudra() {
        guard let mudraPose = viewModel.createMudraPose(name: mudraName) else {
            saveMessage = "No hand landmarks detected."
            showSaveResultAlert = true
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(mudraPose)
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "\(mudraName.replacingOccurrences(of: " ", with: "_")).json"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            
            print("📁 Mudra saved to: \(fileURL.path)")
            
            // Auto-load
            DispatchQueue.main.async {
                self.viewModel.loadTargetMudra(url: fileURL)
                print("🔄 Auto-loaded reference: \(fileName)")
                self.viewModel.listSavedMudras()
            }
            
            saveMessage = "Saved \(fileName) successfully!"
            showSaveResultAlert = true
        } catch {
            saveMessage = "Failed to save: \(error.localizedDescription)"
            showSaveResultAlert = true
        }
    }
}

// MARK: - View Model
class GestureRecognitionViewModel: NSObject, ObservableObject {
    @Published var handLandmarks: [[NormalizedLandmark]] = []
    @Published var worldLandmarks: [[Landmark]] = []
    @Published var detectedGesture: String?
    @Published var handedness: String?
    @Published var confidence: Float?
    
    // Assessment Metrics
    @Published var accuracyScore: Float = 0.0
    @Published var stability: (x: Float, y: Float) = (0, 0)
    @Published var targetMudraName: String = "None"
    @Published var currentLandmarkErrors: [Float]? = nil
    @Published var availableMudras: [String] = []
    @Published var isRecordingSession: Bool = false
    
    var viewSize: CGSize = .zero
    weak var cameraManager: CameraManager?
    
    private var gestureRecognizerService: GestureRecognizerService?
    private var lastProcessedTime: Int = 0
    private let processingInterval = 33 // Process every 33ms (~30 FPS)
    
    private let tremorAnalyzer = TremorAnalyzer()
    private let sessionLogger = SessionLogger()
    private var targetMudra: MudraPose?
    
    override init() {
        super.init()
        listSavedMudras()
    }
    
    func toggleRecording() {
        isRecordingSession.toggle()
        if isRecordingSession {
            sessionLogger.startNewSession()
        } else {
            sessionLogger.stopSession()
        }
    }
    
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
    
    /// Converts the current world landmarks of the first detected hand into a MudraPose
    func createMudraPose(name: String) -> MudraPose? {
        guard let firstHandLandmarks = worldLandmarks.first else {
            return nil
        }
        
        let landmarks3D = firstHandLandmarks.map { landmark in
            Landmark3D(x: landmark.x, y: landmark.y, z: landmark.z)
        }
        
        return MudraPose(name: name, landmarks: landmarks3D)
    }
    
    func loadTargetMudra(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let mudra = try decoder.decode(MudraPose.self, from: data)
            self.targetMudra = mudra
            self.targetMudraName = mudra.name
            print("✅ Loaded reference: \(mudra.name)")
        } catch {
            print("Failed to load mudra: \(error)")
        }
    }
    
    func loadReferenceMudra(named filename: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(filename).appendingPathExtension("json")
        loadTargetMudra(url: fileURL)
    }
    
    func listSavedMudras() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = fileURLs.filter { $0.pathExtension == "json" }
            self.availableMudras = jsonFiles.map { $0.deletingPathExtension().lastPathComponent }.sorted()
        } catch {
            print("Error listing mudras: \(error)")
            self.availableMudras = []
        }
    }
    
    func deleteMudra(at offsets: IndexSet) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        offsets.forEach { index in
            let mudraName = availableMudras[index]
            let fileURL = documentsDirectory.appendingPathComponent(mudraName).appendingPathExtension("json")
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Error deleting file: \(error)")
            }
        }
        
        availableMudras.remove(atOffsets: offsets)
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
                                 didRecognizeGestures result: GestureRecognizerResult,
                                 worldLandmarks: [[Landmark]]) {
        DispatchQueue.main.async {
            // Update hand landmarks for visualization
            self.handLandmarks = result.landmarks
            self.worldLandmarks = worldLandmarks
            
            // Process first detected hand
            if let firstHandWorldLandmarks = worldLandmarks.first {
                // 1. Update Tremor Analyzer
                // Assuming index 0 is the wrist
                if let wrist = firstHandWorldLandmarks.first {
                    let wrist3D = Landmark3D(x: wrist.x, y: wrist.y, z: wrist.z)
                    self.tremorAnalyzer.addFrame(wristPosition: wrist3D, timestamp: Date().timeIntervalSince1970)
                    let stabilityResult = self.tremorAnalyzer.calculateStability()
                    self.stability = (x: stabilityResult.stdDevX, y: stabilityResult.stdDevY)
                }
                
                // 2. Calculate Accuracy if target is loaded
                if let target = self.targetMudra {
                    let currentPose = firstHandWorldLandmarks.map { Landmark3D(x: $0.x, y: $0.y, z: $0.z) }
                    
                    // Calculate average error
                    let error = AssessmentEngine.calculatePoseError(userPose: currentPose, referencePose: target.landmarks)
                    
                    // Calculate individual errors for visualization
                    self.currentLandmarkErrors = AssessmentEngine.calculateLandmarkErrors(userPose: currentPose, referencePose: target.landmarks)
                    
                    // Convert error to accuracy score (0.0 to 1.0)
                    // Assuming error > 0.2 is 0 accuracy, error 0 is 1.0 accuracy
                    // This is a heuristic, tune as needed
                    let maxError: Float = 0.2
                    self.accuracyScore = max(0.0, 1.0 - (error / maxError))
                    
                    // Log data if recording
                    if self.isRecordingSession {
                        self.sessionLogger.logFrame(
                            timestamp: Date().timeIntervalSince1970,
                            accuracy: self.accuracyScore,
                            stabilityX: self.stability.x,
                            stabilityY: self.stability.y
                        )
                    }
                } else {
                    self.accuracyScore = 0.0
                    self.currentLandmarkErrors = nil
                }
            } else {
                self.currentLandmarkErrors = nil
            }
            
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
