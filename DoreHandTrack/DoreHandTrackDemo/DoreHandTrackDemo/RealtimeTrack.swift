//
//  RealtimeTrack.swift
//  DoreHandTrack
//
//  Copyright © 2020 dore. All rights reserved.
//

import Foundation
import UIKit
//===DoreAI Framework====
import DoreCoreAI
import DoreHandTrack
//======================
import AVFoundation


class RealtimeTrack: UIViewController {
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var cameraView: CaptureView!
    @IBOutlet weak var maskoutView: UIImageView!
    
    private var modelManager: HandTrackManager?
    
    
    public var trace:DrawTrace!
    
    var screenHeight: Double?
    var screenWidth: Double?
    
    public lazy var cameraCapture = CameraFeedManager(previewView: cameraView, CameraPosition: AVCaptureDevice.Position.back )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //camerasession delegate
        cameraCapture.delegate = self
        modelManager = HandTrackManager()
        
        screenWidth = Double(cameraView.frame.width)
        screenHeight = Double(cameraView.frame.height)
        
        trace = DrawTrace(frame: view.frame)
        trace.backgroundColor = .clear
        view.addSubview(trace)
        
        
        //load license
        let isValid:Bool = (modelManager?.init_data(sWidth: Float(cameraView.frame.width), sHeight: Float(cameraView.frame.height)))!
        
        
        if(!isValid){
            print("Lic not valid")
        }
        maskoutView.isHidden = true
        
        
        
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cameraCapture.checkCameraConfigurationAndStartSession()
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraCapture.stopSession()
    }
    
}

extension RealtimeTrack: CameraFeedManagerDelegate {
    func didOutput(pixelBuffer: CVPixelBuffer) {
        
      
        let result:HandTrackOut  = (self.modelManager?.run_model(onFrame: pixelBuffer)!)!
        
      
        DispatchQueue.main.async {
            if(result.handflag > 0.05 ){
                self.trace.isHidden = false
                self.trace.points =  result.trackpoint
            }else{
                self.trace.isHidden = true
            }
            
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





