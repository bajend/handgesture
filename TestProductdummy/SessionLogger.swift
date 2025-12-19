//
//  SessionLogger.swift
//  GestureScope
//
//  Created by GitHub Copilot on 12/19/25.
//

import Foundation

class SessionLogger {
    private var fileURL: URL?

    func startNewSession(subjectID: String, group: String, targetGestureName: String, isTestMode: Bool, limitFrames: Int?) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Int(Date().timeIntervalSince1970)
        let modeString = isTestMode ? "TestMode" : "Overlay"
        let limitString = limitFrames != nil ? "\(limitFrames!)Frames" : "NoLimit"
        let fileName = "StudyData_\(subjectID)_\(group)_\(modeString)_\(limitString)_\(timestamp).csv"
        fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        let header = "Timestamp,TargetGesture,Accuracy,StabilityX,StabilityY\n"
        do {
            try header.write(to: fileURL!, atomically: true, encoding: .utf8)
            print("📝 Started logging to: \(fileURL!.path)")
        } catch {
            print("❌ Failed to create log file: \(error)")
        }
    }

    func logFrame(timestamp: Double, targetGestureName: String, accuracy: Float, stabilityX: Float, stabilityY: Float) {
        guard let fileURL = fileURL else { return }

        let logEntry = String(format: "%.3f,%@,%.4f,%.4f,%.4f\n", timestamp, targetGestureName, accuracy, stabilityX, stabilityY)
        
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            if let data = logEntry.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        }
    }
    
    func stopSession() {
        fileURL = nil
        print("🛑 Stopped logging")
    }
}
