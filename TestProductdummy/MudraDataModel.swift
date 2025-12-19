//
//  MudraDataModel.swift
//  TestProductdummy
//
//  Created by GitHub Copilot on 12/19/25.
//

import Foundation

struct Landmark3D: Codable {
    let x: Float
    let y: Float
    let z: Float
}

struct MudraPose: Codable {
    let name: String
    let landmarks: [Landmark3D]
}
