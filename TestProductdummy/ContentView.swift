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
import AudioToolbox

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var viewModel = GestureRecognitionViewModel()
    
    @State private var activePanel: String = "none" // "none", "setup", "save"
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
                                    
                                    // Mode Selector
                                    HStack(spacing: 0) {
                                        Button(action: { activePanel = (activePanel == "setup" ? "none" : "setup") }) {
                                            Text("Setup Exp.")
                                                .font(.caption).bold()
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(activePanel == "setup" ? Color.blue : Color.gray.opacity(0.5))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Button(action: { activePanel = (activePanel == "save" ? "none" : "save") }) {
                                            Text("Save Gesture")
                                                .font(.caption).bold()
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(activePanel == "save" ? Color.blue : Color.gray.opacity(0.5))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                
                                // Horizontal Mudra Selector
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(Array(viewModel.currentList.enumerated()), id: \.element) { index, mudra in
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
                                                if viewModel.studyGroup == "Control" {
                                                    Button(role: .destructive) {
                                                        viewModel.deleteMudra(at: IndexSet(integer: index))
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
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
                            
                            // Recording Toggle (Visible only when no panel is active)
                            if activePanel == "none" {
                                VStack(spacing: 8) {
                                    if viewModel.isRecordingSession {
                                        Text("Data Points: \(viewModel.recordedFrames) / \(viewModel.targetFrameCount ?? 0)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(4)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        if !viewModel.isRecordingSession {
                                            Button(action: {
                                                viewModel.toggleRecording(isTestMode: isBlindMode, limitFrames: 100)
                                            }) {
                                                VStack(spacing: 2) {
                                                    Text("100 Frames")
                                                        .font(.headline)
                                                    Text("Test (~3s)")
                                                        .font(.caption)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(8)
                                                .background(Color.orange)
                                                .cornerRadius(8)
                                                .foregroundColor(.white)
                                            }
                                            
                                            Button(action: {
                                                viewModel.toggleRecording(isTestMode: isBlindMode, limitFrames: 300)
                                            }) {
                                                VStack(spacing: 2) {
                                                    Text("300 Frames")
                                                        .font(.headline)
                                                    Text("Train (~10s)")
                                                        .font(.caption)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(8)
                                                .background(Color.green)
                                                .cornerRadius(8)
                                                .foregroundColor(.white)
                                            }
                                        } else {
                                            Button(action: {
                                                viewModel.toggleRecording(isTestMode: isBlindMode)
                                            }) {
                                                HStack {
                                                    Image(systemName: "stop.circle.fill")
                                                    Text("Stop Log")
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(12)
                                                .background(Color.red)
                                                .cornerRadius(8)
                                                .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Setup Panel
                            if activePanel == "setup" {
                                VStack(spacing: 12) {
                                    Text("Experiment Setup")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Subject ID")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        TextField("Enter Subject ID", text: $viewModel.subjectID)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Group")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Picker("Group", selection: $viewModel.studyGroup) {
                                            Text("Mudra").tag("Mudra")
                                            Text("Natural").tag("Natural")
                                            Text("Control").tag("Control")
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            
                            // Save Gesture Panel
                            if activePanel == "save" {
                                VStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("New Reference Gesture")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                        
                                        Text("1. Perform the gesture in front of the camera.\n2. Ensure the skeleton is stable.\n3. Tap 'Capture' to save.")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Button(action: {
                                        mudraName = ""
                                        showSaveAlert = true
                                    }) {
                                        HStack {
                                            Image(systemName: "camera.shutter.button")
                                            Text("Capture Gesture")
                                        }
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(12)
                                        .background(viewModel.worldLandmarks.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                    .disabled(viewModel.worldLandmarks.isEmpty)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
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
                            Text("Test Mode Active")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.7))
                                .cornerRadius(10)
                            
                            Spacer()
                            
                            // Recording Toggle (Visible in Blind Mode for Control)
                            if viewModel.isRecordingSession {
                                Button(action: {
                                    viewModel.toggleRecording(isTestMode: isBlindMode)
                                }) {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.red)
                                }
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                            } else {
                                HStack(spacing: 20) {
                                    Button(action: {
                                        viewModel.toggleRecording(isTestMode: isBlindMode, limitFrames: 100)
                                    }) {
                                        Text("100")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(12)
                                            .background(Color.orange)
                                            .clipShape(Circle())
                                    }
                                    
                                    Button(action: {
                                        viewModel.toggleRecording(isTestMode: isBlindMode, limitFrames: 300)
                                    }) {
                                        Text("300")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(12)
                                            .background(Color.green)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // Global Toggle for Blind Mode (Top Left)
                VStack {
                    HStack {
                        Toggle(isOn: $isBlindMode) {
                            Text("Test Mode (No Overlay)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                        .frame(width: 180)
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
    @Published var subjectID: String = ""
    @Published var studyGroup: String = "Control"
    @Published var currentLandmarkErrors: [Float]? = nil
    @Published var availableMudras: [String] = []
    @Published var isRecordingSession: Bool = false
    @Published var recordedFrames: Int = 0
    @Published var targetFrameCount: Int? = nil
    
    let mudraGestures = ["Pataakam", "Tripataakam", "Mayura", "Kartari_Mukham"]
    let naturalGestures = ["Large_Diameter", "Tip_Pinch", "Power_Disk", "Lateral_Tripod"]
    
    var currentList: [String] {
        switch studyGroup {
        case "Mudra": return mudraGestures
        case "Natural": return naturalGestures
        default: return availableMudras
        }
    }
    
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
    
    func toggleRecording(isTestMode: Bool, limitFrames: Int? = nil) {
        isRecordingSession.toggle()
        if isRecordingSession {
            self.targetFrameCount = limitFrames
            self.recordedFrames = 0
            sessionLogger.startNewSession(subjectID: subjectID, group: studyGroup, targetGestureName: targetMudraName, isTestMode: isTestMode, limitFrames: limitFrames)
        } else {
            sessionLogger.stopSession()
            self.targetFrameCount = nil
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
                        self.recordedFrames += 1
                        
                        self.sessionLogger.logFrame(
                            timestamp: Date().timeIntervalSince1970,
                            targetGestureName: self.targetMudraName,
                            accuracy: self.accuracyScore,
                            stabilityX: self.stability.x,
                            stabilityY: self.stability.y
                        )
                        
                        if let target = self.targetFrameCount, self.recordedFrames >= target {
                            self.toggleRecording(isTestMode: false) // Mode doesn't matter when stopping
                            AudioServicesPlaySystemSound(1052)
                        }
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
