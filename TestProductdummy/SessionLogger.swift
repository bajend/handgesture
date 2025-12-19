//
//  SessionLogger.swift
//  GestureScope
//
//  Created by GitHub Copilot on 12/19/25.
//

import Foundation

class SessionLogger {
    private var fileURL: URL?

    func startNewSession() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "session_log_\(Int(Date().timeIntervalSince1970)).csv"
        fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        let header = "Timestamp,Accuracy,StabilityX,StabilityY\n"
        do {
            try header.write(to: fileURL!, atomically: true, encoding: .utf8)
            print("📝 Started logging to: \(fileURL!.path)")
        } catch {
            print("❌ Failed to create log file: \(error)")
        }
    }

    func logFrame(timestamp: Double, accuracy: Float, stabilityX: Float, stabilityY: Float) {
        guard let fileURL = fileURL else { return }

        let logEntry = String(format: "%.3f,%.4f,%.4f,%.4f\n", timestamp, accuracy, stabilityX, stabilityY)
        
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
