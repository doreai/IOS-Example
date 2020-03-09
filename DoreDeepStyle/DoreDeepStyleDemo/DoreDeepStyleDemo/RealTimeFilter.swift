//
//  RealTimeFilter.swift
//  DoreDeepStyle
//
//  Copyright © 2020 dore. All rights reserved.
//

import Foundation
import UIKit
//===DoreAI Framework====
import DoreCoreAI
import DoreDeepStyle
//======================
import AVFoundation


class RealTimeFilter : UIViewController, CameraFeedManagerDelegate, DoreDeepStyleLoadDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    
    
    let reuseIdentifier = "vCell"
    @IBOutlet weak var cameraView: CaptureView!
    @IBOutlet weak var maskoutView: UIImageView!
    
    private var modelManager: DeepStyleManager?
    
    private var isStyleLoaded = false
    @IBOutlet weak var colView: UICollectionView!
    private var isBackCam = false
    
    public lazy var cameraCapture = CameraFeedManager(previewView: cameraView, CameraPosition: AVCaptureDevice.Position.back )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        colView.dataSource = self;
        colView.delegate = self;
        
        //camerasession delegate
        cameraCapture.delegate = self
        modelManager = DeepStyleManager()
        modelManager?.delegate = self
        //load license
        let isValid:Bool = (modelManager?.init_data(licKey: HomePage.lickey) ?? false)
        
        if(!isValid){
            print("Lic not valid")
        }
        
        //cameraView.isHidden = true
         //modelManager?.load_style(styleID: "s1")
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraCapture.checkCameraConfigurationAndStartSession()
        
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraCapture.stopSession()
    }
    
    func onDeepStyleLoadSuccess(_ info: String) {
        isStyleLoaded = true
        
    }
    
    func onDeepStyleLoadFailure(_ error: String) {
        print(error)
    }
    
    func onDeepStyleLoadProgressUpdate(_ progress: String) {
        print(progress)
    }
    
    func onDeepStyleLoadDownloadSpeed(_ dps: String) {
        print(dps)
    }
    
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //switch camera
    @IBAction func btnSwitchCamera_Action(_ sender: Any) {
        if(isBackCam){
            isBackCam = false
            cameraCapture = CameraFeedManager(previewView: cameraView, CameraPosition: AVCaptureDevice.Position.front )
        }else {
            isBackCam = true
            cameraCapture = CameraFeedManager(previewView: cameraView, CameraPosition: AVCaptureDevice.Position.back )
        }
        cameraCapture.delegate = self
        cameraCapture.checkCameraConfigurationAndStartSession()
    }
    
    func didOutput(pixelBuffer: CVPixelBuffer) {
        
        
        if(isStyleLoaded) {
            
            //run model and get result
           let result:TextureOut  = TextureOut ( features: (self.modelManager?.run_model(onFrame: pixelBuffer))! )
            
            DispatchQueue.main.async {
                
                let ciImage = CIImage(cvPixelBuffer: (result.semanticPredictions))
                let context = CIContext()
                guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return  }
                let setImage = UIImage(cgImage: cgImage)
                let finalImage = setImage.resized(to: CGSize(width: self.maskoutView.frame.width, height: self.maskoutView.frame.height))
                self.maskoutView.image = finalImage
            }
            
            
        }
        
        
        
        
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 189
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! ColCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        cell.lbName.text = "Style-" + String(indexPath.item + 1)
        
       
        
        let bundle = Bundle(for: RealTimeFilter.self)
        guard let thumbimage = UIImage(named: String(indexPath.item + 1) + ".png", in: bundle, compatibleWith: nil) else {
          fatalError("Missing MyImage...")
        }
        cell.thumbImage.image = thumbimage

        //cell.backgroundColor = UIColor.blue // make cell more visible in our example project
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        print("You selected cell #\(indexPath.item)!")
        modelManager?.load_style(styleID: "s" + String((indexPath.item + 1)) )
        
        //---load style from your server url---
        //modelManager?.load_stylebyURL(URLPath: "https://xxx/deepstyle/ios/", styleID: "s" + String((indexPath.item + 1)))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 119, height: 118)
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




