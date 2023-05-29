//
//  MaskView.swift
//  DoreHairSegmentDemo
//
//  Copyright © 2020 dore. All rights reserved.
//

import UIKit
import Foundation
//===DoreAI Framework====
import DoreCoreAI
import DoreFaceSegment
//======================
import AVFoundation


class MaskView: UIViewController, CameraFeedManagerDelegate {
    
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func btnSegBody(_ sender: Any) {
        facesegType = FaceSegmentManager.FaceSegmentType.BODY
        
    }
    @IBAction func btnSegFace(_ sender: Any) {
        facesegType = FaceSegmentManager.FaceSegmentType.FACE
    }
    
    @IBAction func btnSegHair(_ sender: Any) {
        facesegType = FaceSegmentManager.FaceSegmentType.HAIR
    }
    
    @IBAction func btnSegSkin(_ sender: Any) {
        facesegType = FaceSegmentManager.FaceSegmentType.SKIN
    }
    
    
    @IBOutlet weak var cameraView: CaptureView!
    @IBOutlet weak var segmentView: UIImageView!
    
    
    private var modelManager: FaceSegmentManager?
    
    private var facesegType : FaceSegmentManager.FaceSegmentType = FaceSegmentManager.FaceSegmentType.FACE
    
    //init front camera
    public lazy var cameraCapture = CameraFeedManager(previewView: cameraView, CameraPosition: AVCaptureDevice.Position.front )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //camerasession delegate
        cameraCapture.delegate = self
        
        modelManager = FaceSegmentManager()
        
        //load license
        let isValid:Bool = (modelManager?.init_data(licKey: HomePage.lickey) ?? false)
        
        if(!isValid){
            print("Lic not valid")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cameraCapture.checkCameraConfigurationAndStartSession()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraCapture.stopSession()
    }
    
    
    func didOutput(pixelBuffer: CVPixelBuffer) {
        
        
        //run model and get result
        let inputimage:UIImage = UIImage(pixelBuffer: pixelBuffer)!
        //run model and get result
        let outImage:CGImage = (self.modelManager?.run_model(onFrame: inputimage, faceSegmentType: facesegType))!
                
        
        
        DispatchQueue.main.async {
            self.segmentView.image = UIImage(cgImage: outImage)
        }
        
    }
    
    
    // MARK: Session Handling Alerts
    func sessionWasInterrupted(canResumeManually resumeManually: Bool) {
        
        
    }
    
    func sessionInterruptionEnded() {
        
    }
    
    func sessionRunTimeErrorOccured() {
        
    }
    
    func presentCameraPermissionsDeniedAlert() {
        let alertController = UIAlertController(title: "Camera Permissions Denied", message: "Camera permissions have been denied for this app. You can change this by going to Settings", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentVideoConfigurationErrorAlert() {
        let alert = UIAlertController(title: "Camera Configuration Failed", message: "There was an error while configuring camera.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    
    
}







