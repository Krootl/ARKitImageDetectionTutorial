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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
    }
    
}
