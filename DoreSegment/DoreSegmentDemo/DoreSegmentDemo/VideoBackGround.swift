//
//  VideoBackGround.swift
//  DoreSegmentDemo
//
//  Copyright © 2020 dore. All rights reserved.
//

import Foundation
import UIKit
//===DoreAI Framework====
import DoreCoreAI
import DoreSegment
//======================
import CoreML
import AVFoundation


class VideoBackGround: UIViewController, CameraFeedManagerDelegate {
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var cameraView: CaptureView!
    @IBOutlet weak var maskoutView: UIImageView!
    
    private var modelManager: SegmentManager?
    
    private var player:AVPlayer!
    
    //init front camera
    public lazy var cameraCapture = CameraFeedManager(previewView: cameraView, CameraPosition: AVCaptureDevice.Position.front )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //camerasession delegate
        cameraCapture.delegate = self
        modelManager = SegmentManager()
        //load license
        let isValid:Bool = (modelManager?.init_data(licKey: HomePage.lickey) ?? false)
        
        if(!isValid){
            print("Lic not valid")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cameraCapture.checkCameraConfigurationAndStartSession()
        
        //play video
        let vpath = Bundle.main.path(forResource: "video1", ofType:"mp4")
        player = AVPlayer(url: URL(fileURLWithPath: vpath!))
        player.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoView.bounds
        videoView.layer.addSublayer(playerLayer)
        player.play()
        
        
        
    }
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            player.pause()
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
            player.play()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraCapture.stopSession()
    }
    
    
    func didOutput(pixelBuffer: CVPixelBuffer) {
        
       
        //run model and get result
        let result:segmentOut  = segmentOut ( features: (self.modelManager?.run_model(onFrame: pixelBuffer))! )
        
        //mask image White - bacground, Black - foreground
        let ciImage:UIImage = getMaskWB(result.semanticPredictions)!
        
        
        //extract image
        let rgbCIimage:CIImage = CIImage.init(cvPixelBuffer: pixelBuffer)
        let rgbImage:UIImage = convertCItoUIimage(cmage: rgbCIimage)
        let finalImage:UIImage = cutoutmaskImage(image: rgbImage, mask: ciImage)
        
        
        DispatchQueue.main.async {
            self.maskoutView.image = finalImage
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

