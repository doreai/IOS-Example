//
//  ViewController.swift
//  DoreSegmentDemo
//
//  Copyright © 2020 dore. All rights reserved.
//

import UIKit
import Foundation
//===DoreAI Framework====
import DoreCoreAI
import DoreSegmentLite
//======================
import CoreML
import AVFoundation


class MaskView: UIViewController, CameraFeedManagerDelegate,  SegmentLiteDelegate   {
    
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var cameraView: CaptureView!
    @IBOutlet weak var segmentView: UIImageView!
    
    
    private var modelManager: SegmentLiteManager?
    
    
    //init front camera
    public lazy var cameraCapture = CameraFeedManager(previewView: cameraView, CameraPosition: AVCaptureDevice.Position.front )
    
    public var alertView:UIAlertController!
    public var progressView:UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //camerasession delegate
        cameraCapture.delegate = self
        
        
        
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        modelManager = SegmentLiteManager()
        modelManager?.delegate = self
        
        
        //  Just create your alert for downloading library files
        alertView = UIAlertController(title: "Loading", message: "Please Wait...!", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        //  Show it to your users
        present(alertView, animated: true, completion: {
            //  Add your progressbar after alert is shown (and measured)
            let margin:CGFloat = 8.0
            let rect = CGRect(x: margin, y: 72.0, width: self.alertView.view.frame.width - margin * 2.0 , height: 2.0)
            self.progressView = UIProgressView(frame: rect)
            self.progressView!.progress = 0.0
            self.progressView!.tintColor = self.view.tintColor
            self.alertView.view.addSubview(self.progressView!)
            
            //Load license / start initiating
            self.modelManager?.init_data(licKey: HomePage.lickey)
        })
        
        
    }
    
    
    //===DoreSegmentLiteDelegate===
    func onSegmentLiteSuccess(_ info: String) {
        
        self.alertView.dismiss(animated: true, completion: nil)
        
        
        //DoreSegment Library files downloaded successfully...! Ready to run segment
        cameraCapture.checkCameraConfigurationAndStartSession()
    }
    
    func onSegmentLiteFailure(_ error: String) {
        
        self.alertView.dismiss(animated: true, completion: nil)
        
        
        //DoreSegment Library files downloading failed..!
        print(error)
    }
    
    func onSegmentLiteProgressUpdate(_ progress: String) {
        //DoreSegment Library files downloading...!
        print(progress)
        self.progressView!.progress = Float(progress)!
    }
    
    func onSegmentLiteDownloadSpeed(_ dps: String) {
        print(dps)
    }
    //==============================
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraCapture.stopSession()
    }
    
    
    func didOutput(pixelBuffer: CVPixelBuffer) {
        
        
        
        //run model and get result
        let result:segmentOut  = segmentOut ( features: (self.modelManager?.run_model(onFrame: pixelBuffer))! )
        
        
        //mask image Black - bacground, White - foreground
        let ciImage:UIImage = getMaskBW(result.semanticPredictions)!
        
        
        DispatchQueue.main.async {
            
            self.segmentView.image =  ciImage
            
            
            
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







