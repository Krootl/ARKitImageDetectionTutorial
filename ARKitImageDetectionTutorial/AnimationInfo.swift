//
//  AnimationInfo.swift
//  ARKitImageDetectionTutorial
//
//  Created by Ivan Nesterenko on 4/6/18.
//  Copyright © 2018 Ivan Nesterenko. All rights reserved.
//

import Foundation
import SceneKit

struct AnimationInfo {
    var startTime: TimeInterval
    var duration: TimeInterval
    var initialModelPosition: simd_float3
    var finalModelPosition: simd_float3
    var initialModelOrientation: simd_quatf
    var finalModelOrientation: simd_quatf
}
