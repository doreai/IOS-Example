//
//  RealtimeTrack.swift
//  DoreEmotionRecognitionDemo
//
//  Copyright © 2020 dore. All rights reserved.
//

import Foundation
import UIKit
//===DoreAI Framework====
import DoreCoreAI
import DoreEmotionRecognition
//======================
import AVFoundation


class RealtimeTrack: UIViewController, EmotionRecoDelegate {
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var cameraView: CaptureView!
    
    @IBOutlet weak var lbStatus: UILabel!
    
    private var modelManager: EmotionRecognitionManager?
     
    var screenHeight: Double?
    var screenWidth: Double?
    
    public lazy var cameraCapture = CameraFeedManager(previewView: cameraView, CameraPosition: AVCaptureDevice.Position.front )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //camerasession delegate
        cameraCapture.delegate = self
        modelManager = EmotionRecognitionManager()
            modelManager?.delegate = self
        let isValid:Bool = (modelManager?.init_data(licKey: HomePage.lickey))!
            if(!isValid){
                print("Dore : Lic not valid")
        }
        
      
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cameraCapture.checkCameraConfigurationAndStartSession()
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraCapture.stopSession()
    }
    
    func onEmotionRecoReceived(_ info: EmotionData) {
           
        
        DispatchQueue.main.async {
            self.lbStatus.text = info.eTxt
        }
           
    }
    
    
}

extension RealtimeTrack: CameraFeedManagerDelegate {
    
    
    func didOutput(pixelBuffer: CVPixelBuffer) {
        
      self.modelManager?.run_model(onFrame: pixelBuffer)
        
        
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





