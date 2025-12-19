//
//  HandLandmarksOverlayView.swift
//  TestProductdummy
//
//  Created by GitHub Copilot on 12/16/25.
//

import SwiftUI
import MediaPipeTasksVision

struct HandLandmarksOverlayView: View {
    let landmarks: [[NormalizedLandmark]]
    let imageSize: CGSize
    let viewSize: CGSize
    var landmarkErrors: [Float]? = nil

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for (index, handLandmarks) in landmarks.enumerated() {
                    // Draw connections between landmarks
                    drawConnections(context: context, landmarks: handLandmarks)

                    // Draw landmark points
                    // Only apply errors to the first hand detected for now
                    let errors = index == 0 ? landmarkErrors : nil
                    drawLandmarks(context: context, landmarks: handLandmarks, errors: errors)
                }
            }
        }
    }

    private func drawConnections(context: GraphicsContext, landmarks: [NormalizedLandmark]) {
        let connections: [(Int, Int)] = [
            // Thumb
            (0, 1), (1, 2), (2, 3), (3, 4),
            // Index finger
            (0, 5), (5, 6), (6, 7), (7, 8),
            // Middle finger
            (0, 9), (9, 10), (10, 11), (11, 12),
            // Ring finger
            (0, 13), (13, 14), (14, 15), (15, 16),
            // Pinky
            (0, 17), (17, 18), (18, 19), (19, 20),
            // Palm
            (5, 9), (9, 13), (13, 17)
        ]
        
        var path = Path()
        
        for (start, end) in connections {
            guard start < landmarks.count, end < landmarks.count else { continue }
            
            let startPoint = convertLandmarkToPoint(landmarks[start], index: start)
            let endPoint = convertLandmarkToPoint(landmarks[end], index: end)
            
            path.move(to: startPoint)
            path.addLine(to: endPoint)
        }
        
        context.stroke(
            path,
            with: .color(.green),
            lineWidth: 4
        )
    }
    
    private func drawLandmarks(context: GraphicsContext, landmarks: [NormalizedLandmark], errors: [Float]? = nil) {
        for (index, landmark) in landmarks.enumerated() {
            let point = convertLandmarkToPoint(landmark, index: index)
            
            // Determine color based on error if available, otherwise use default coloring
            let color: Color
            if let errors = errors, index < errors.count {
                let error = errors[index]
                if error < 0.03 {
                    color = .green
                } else if error > 0.05 {
                    color = .red
                } else {
                    color = .yellow
                }
            } else {
                switch index {
                case 0: color = .red // Wrist
                case 1...4: color = .blue // Thumb
                case 5...8: color = .green // Index
                case 9...12: color = .yellow // Middle
                case 13...16: color = .orange // Ring
                case 17...20: color = .purple // Pinky
                default: color = .white
                }
            }
            
            let circle = Circle()
                .path(in: CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16))
            
            context.fill(circle, with: .color(color))
            context.stroke(circle, with: .color(.white), lineWidth: 2)
        }
    }
    
    private func convertLandmarkToPoint(_ landmark: NormalizedLandmark, index: Int) -> CGPoint {
        // 1. Defensively handle zero-size (wait for first frame)
        guard imageSize.width > 0 && imageSize.height > 0 else { return .zero }
        
        // 2. Check orientation
        // Most phone cameras capture in Landscape (Width > Height) even in Portrait mode.
        // If image is Landscape but View is Portrait, we must swap axes.
        let isRotated = imageSize.width > imageSize.height && viewSize.width < viewSize.height
        
        // 3. Determine the "Effective" video dimensions relative to the View
        // If rotated, the video's Width maps to the View's Height.
        let videoWidth = isRotated ? imageSize.height : imageSize.width
        let videoHeight = isRotated ? imageSize.width : imageSize.height
        
        // 4. Calculate Scale (Aspect Fill)
        let widthScale = viewSize.width / videoWidth
        let heightScale = viewSize.height / videoHeight
        let scale = max(widthScale, heightScale)
        
        // 5. Apply the Rotation to the Normalized Landmark
        // Standard Portrait Mode Transformation:
        // (x, y) -> (1-y, x)
        // This rotates the landscape coordinates 90 degrees to stand upright.
        let normX: CGFloat = isRotated ? 1.0 - CGFloat(landmark.y) : CGFloat(landmark.x)
        let normY: CGFloat = isRotated ? CGFloat(landmark.x) : CGFloat(landmark.y)
        
        // 6. Project to scaled screen coordinates
        // We treat the "video" as if it has already been rotated to match the screen
        let scaledX = normX * videoWidth * scale
        let scaledY = normY * videoHeight * scale
        
        // 7. Center the result (Offset)
        let offsetX = (viewSize.width - (videoWidth * scale)) / 2
        let offsetY = (viewSize.height - (videoHeight * scale)) / 2
        
        var finalX = scaledX + offsetX
        let finalY = scaledY + offsetY
        
        // 8. Mirroring (Front Camera only)
        // Front camera is usually mirrored. Flip X across the view width.
        // Note: Adjust this boolean based on which camera is active
        let isFrontCamera = true 
        if isFrontCamera {
            finalX = viewSize.width - finalX
        }
        
        return CGPoint(x: finalX, y: finalY)
    }
}
