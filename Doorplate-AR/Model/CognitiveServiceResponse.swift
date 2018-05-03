//
//  CognitiveServiceResponse.swift
//  Doorplate-AR
//
//  Created by Robin Wiegand on 03.05.18.
//  Copyright © 2018 Jonas Wisplinghoff. All rights reserved.
//

import Foundation

struct Welcome: Codable {
    let language, orientation: String
    let textAngle: Double
    let regions: [Region]
}

struct Region: Codable {
    let boundingBox: String
    let lines: [Line]
}

struct Line: Codable {
    let boundingBox: String
    let words: [Word]
}

struct Word: Codable {
    let boundingBox, text: String
}

