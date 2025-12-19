//
//  AssessmentEngine.swift
//  TestProductdummy
//
//  Created by GitHub Copilot on 12/19/25.
//

import Foundation

struct AssessmentEngine {
    
    /// Calculates the average Euclidean distance between two sets of 3D landmarks.
    /// Returns Float.infinity if the arrays have different lengths or are empty.
    static func calculatePoseError(userPose: [Landmark3D], referencePose: [Landmark3D]) -> Float {
        // Ensure arrays are valid for comparison
        guard !userPose.isEmpty, 
              !referencePose.isEmpty, 
              userPose.count == referencePose.count else {
            return Float.infinity
        }
        
        // Normalize poses by translating wrist (index 0) to origin (0,0,0)
        let normalizedUserPose = normalizePose(userPose)
        let normalizedReferencePose = normalizePose(referencePose)
        
        var totalDistance: Float = 0.0
        
        for i in 0..<normalizedUserPose.count {
            let u = normalizedUserPose[i]
            let r = normalizedReferencePose[i]
            
            let dx = u.x - r.x
            let dy = u.y - r.y
            let dz = u.z - r.z
            
            let distance = sqrt(dx*dx + dy*dy + dz*dz)
            totalDistance += distance
        }
        
        let averageError = totalDistance / Float(normalizedUserPose.count)
        print("Avg Error: \(averageError)")
        return averageError
    }
    
    /// Calculates the Euclidean distance for each landmark between two sets of 3D landmarks.
    static func calculateLandmarkErrors(userPose: [Landmark3D], referencePose: [Landmark3D]) -> [Float]? {
        guard !userPose.isEmpty, 
              !referencePose.isEmpty, 
              userPose.count == referencePose.count else {
            return nil
        }
        
        // Normalize poses by translating wrist (index 0) to origin (0,0,0)
        let normalizedUserPose = normalizePose(userPose)
        let normalizedReferencePose = normalizePose(referencePose)
        
        var errors: [Float] = []
        
        for i in 0..<normalizedUserPose.count {
            let u = normalizedUserPose[i]
            let r = normalizedReferencePose[i]
            
            let dx = u.x - r.x
            let dy = u.y - r.y
            let dz = u.z - r.z
            
            let distance = sqrt(dx*dx + dy*dy + dz*dz)
            errors.append(distance)
        }
        
        return errors
    }
    
    /// Normalizes a pose by translating the wrist (index 0) to (0,0,0)
    private static func normalizePose(_ pose: [Landmark3D]) -> [Landmark3D] {
        guard let wrist = pose.first else { return pose }
        
        return pose.map { landmark in
            Landmark3D(
                x: landmark.x - wrist.x,
                y: landmark.y - wrist.y,
                z: landmark.z - wrist.z
            )
        }
    }
}

class TremorAnalyzer {
    private struct FrameData {
        let timestamp: Double
        let position: Landmark3D
    }
    
    private var buffer: [FrameData] = []
    private let windowDuration: Double = 2.0
    
    func addFrame(wristPosition: Landmark3D, timestamp: Double) {
        buffer.append(FrameData(timestamp: timestamp, position: wristPosition))
        
        // Remove old frames
        let cutoffTime = timestamp - windowDuration
        if let firstIndex = buffer.firstIndex(where: { $0.timestamp >= cutoffTime }) {
            if firstIndex > 0 {
                buffer.removeFirst(firstIndex)
            }
        } else {
            // If no frames are within the window (unlikely if we just appended), clear all except the new one?
            // Actually if firstIndex is nil, it means NO element satisfies the condition (all are older).
            // But we just appended one that is definitely >= timestamp - 2.0 (since it is timestamp).
            // So firstIndex should be found.
            // However, if the buffer was empty, we appended one.
            // If we are adding frames out of order? Assuming monotonic time.
            // Let's stick to a simpler filter for safety or removeFirst logic.
            buffer = buffer.filter { $0.timestamp >= cutoffTime }
        }
    }
    
    /// Computes the standard deviation of the wrist's X and Y coordinates within the buffer.
    /// Returns a tuple containing the standard deviation for X and Y.
    /// Note: Lower values indicate higher stability (less tremor/movement).
    func calculateStability() -> (stdDevX: Float, stdDevY: Float) {
        guard buffer.count > 1 else { return (0.0, 0.0) }
        
        let count = Float(buffer.count)
        
        // Calculate Means
        let sumX = buffer.reduce(0) { $0 + $1.position.x }
        let sumY = buffer.reduce(0) { $0 + $1.position.y }
        let meanX = sumX / count
        let meanY = sumY / count
        
        // Calculate Variances
        let sumSquaredDiffX = buffer.reduce(0) { $0 + pow($1.position.x - meanX, 2) }
        let sumSquaredDiffY = buffer.reduce(0) { $0 + pow($1.position.y - meanY, 2) }
        
        let stdDevX = sqrt(sumSquaredDiffX / count)
        let stdDevY = sqrt(sumSquaredDiffY / count)
        
        return (stdDevX, stdDevY)
    }
}
