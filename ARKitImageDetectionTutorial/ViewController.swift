//
//  ViewController.swift
//  ARKitImageDetectionTutorial
//
//  Created by Ivan Nesterenko on 28/5/18.
//  Copyright © 2018 Ivan Nesterenko. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    private var planeNode: SCNNode?
    private var imageNode: SCNNode?
    private var animationInfo: AnimationInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Load reference images to look for from "AR Resources" folder
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Add previously loaded images to ARScene configuration as detectionImages
        configuration.detectionImages = referenceImages
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else {
            return
        }
        
        // 1. Load plane's scene.
        let planeScene = SCNScene(named: "art.scnassets/plane.scn")!
        let planeNode = planeScene.rootNode.childNode(withName: "planeRootNode", recursively: true)!
        
        // 2. Calculate size based on planeNode's bounding box.
        let (min, max) = planeNode.boundingBox
        let size = SCNVector3Make(max.x - min.x, max.y - min.y, max.z - min.z)
        
        // 3. Calculate the ratio of difference between real image and object size.
        // Ignore Y axis because it will be pointed out of the image.
        let widthRatio = Float(imageAnchor.referenceImage.physicalSize.width)/size.x
        let heightRatio = Float(imageAnchor.referenceImage.physicalSize.height)/size.z
        // Pick smallest value to be sure that object fits into the image.
        let finalRatio = [widthRatio, heightRatio].min()!
        
        // 4. Set transform from imageAnchor data.
        planeNode.transform = SCNMatrix4(imageAnchor.transform)
        
        // 5. Animate appearance by scaling model from 0 to previously calculated value.
        let appearanceAction = SCNAction.scale(to: CGFloat(finalRatio), duration: 0.4)
        appearanceAction.timingMode = .easeOut
        // Set initial scale to 0.
        planeNode.scale = SCNVector3Make(0.001, 0.001, 0.001)
        // Add to root node.
        sceneView.scene.rootNode.addChildNode(planeNode)
        // Run the appearance animation.
        planeNode.runAction(appearanceAction)
        
        self.planeNode = planeNode
        self.imageNode = node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let imageNode = imageNode, let planeNode = planeNode else {
            return
        }
        
        // 1. Unwrap animationInfo. Calculate animationInfo if it is nil.
        guard let animationInfo = animationInfo else {
            refreshAnimationVariables(startTime: time,
                                      initialPosition: planeNode.simdWorldPosition,
                                      finalPosition: imageNode.simdWorldPosition,
                                      initialOrientation: planeNode.simdWorldOrientation,
                                      finalOrientation: imageNode.simdWorldOrientation)
            return
        }
        
        // 2. Calculate new animationInfo if image position or orientation changed.
        if !simd_equal(animationInfo.finalModelPosition, imageNode.simdWorldPosition) || animationInfo.finalModelOrientation != imageNode.simdWorldOrientation {
            
            refreshAnimationVariables(startTime: time,
                                      initialPosition: planeNode.simdWorldPosition,
                                      finalPosition: imageNode.simdWorldPosition,
                                      initialOrientation: planeNode.simdWorldOrientation,
                                      finalOrientation: imageNode.simdWorldOrientation)
        }
        
        // 3. Calculate interpolation based on passedTime/totalTime ratio.
        let passedTime = time - animationInfo.startTime
        var t = min(Float(passedTime/animationInfo.duration), 1)
        // Applying curve function to time parameter to achieve "ease out" timing
        t = sin(t * .pi * 0.5)
        
        // 4. Calculate and set new model position and orientation.
        let f3t = simd_make_float3(t, t, t)
        planeNode.simdWorldPosition = simd_mix(animationInfo.initialModelPosition, animationInfo.finalModelPosition, f3t)
        planeNode.simdWorldOrientation = simd_slerp(animationInfo.initialModelOrientation, animationInfo.finalModelOrientation, t)
        //planeNode.simdWorldOrientation = imageNode.simdWorldOrientation
    }
    
    func refreshAnimationVariables(startTime: TimeInterval, initialPosition: float3, finalPosition: float3, initialOrientation: simd_quatf, finalOrientation: simd_quatf) {
        let distance = simd_distance(initialPosition, finalPosition)
        // Average speed of movement is 0.15 m/s.
        let speed = Float(0.15)
        // Total time is calculated as distance/speed. Min time is set to 0.1s and max is set to 2s.
        let animationDuration = Double(min(max(0.1, distance/speed), 2))
        // Store animation information for later usage.
        animationInfo = AnimationInfo(startTime: startTime,
                                      duration: animationDuration,
                                      initialModelPosition: initialPosition,
                                      finalModelPosition: finalPosition,
                                      initialModelOrientation: initialOrientation,
                                      finalModelOrientation: finalOrientation)
    }
    
}
