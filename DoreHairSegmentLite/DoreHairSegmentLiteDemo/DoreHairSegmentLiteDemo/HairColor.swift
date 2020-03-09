//
//  HairColor.swift
//  DoreHairSegmentDemo
//
//  Copyright © 2020 dore. All rights reserved.
//

import Foundation
import UIKit
//===DoreAI Framework====
import DoreCoreAI
import DoreHairSegmentLite
//======================
import AVFoundation


class HairColor : UIViewController, CameraFeedManagerDelegate, HairSegmentLiteDelegate {
    
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var cameraView: CaptureView!
    @IBOutlet weak var maskoutView: UIImageView!
    
    private var modelManager: HairSegmentLiteManager?
    
    public var RGBCode:[Int] = [155, 77, 243]
    
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
        
        modelManager = HairSegmentLiteManager()
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
    
    
    //===DoreHairSegmentLiteDelegate===
    func onHairSegmentLiteSuccess(_ info: String) {
        
        self.alertView.dismiss(animated: true, completion: nil)
        
        
        //DoreHairSegment Library files downloaded successfully...! Ready to run segment
        cameraCapture.checkCameraConfigurationAndStartSession()
    }
    
    func onHairSegmentLiteFailure(_ error: String) {
        
        self.alertView.dismiss(animated: true, completion: nil)
        
        
        //DoreHairSegment Library files downloading failed..!
        print(error)
    }
    
    func onHairSegmentLiteProgressUpdate(_ progress: String) {
        //DoreHairSegment Library files downloading...!
        print(progress)
        self.progressView!.progress = Float(progress)!
    }
    
    func onHairSegmentLiteDownloadSpeed(_ dps: String) {
        print(dps)
    }
    //==============================
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraCapture.stopSession()
    }
    
    
    func didOutput(pixelBuffer: CVPixelBuffer) {
        
        
        //run model and get result
        let result:segmentOut  = segmentOut ( features: (self.modelManager?.run_model(onFrame: pixelBuffer))! )
        
        //get color mask (you can adjust RGBA value)
        let ciImage:UIImage = getColorMask(result.semanticPredictions,R: RGBCode[0], G: RGBCode[1], B: RGBCode[2], A: 255)!
        
        let rgbCIimage:CIImage = CIImage.init(cvPixelBuffer: pixelBuffer)
        let img:UIImage = convertCItoUIimage(cmage: rgbCIimage)
        
        //you can change BlendMode and adjust alpha value (0.1 to 1)
        let outputImage:UIImage = maskblendImage(backgroundImage: img, maskImage: ciImage, maskblendMode: CGBlendMode.multiply, blendAlpha: 0.8)!
        
        
        DispatchQueue.main.async {
            self.maskoutView.image = outputImage
        }
        
        
    }
    
    
    
    
    
    @IBAction func btnChangeColor_Action(_ sender: Any) {
        
        
        
        var randomColor: UIColor {
            let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
            let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
            let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
            
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
        }
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        randomColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        RGBCode[0] = Int(red * 256)
        RGBCode[1] = Int(green * 256)
        RGBCode[2] = Int(blue * 256)
        
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


extension UIImage {
    /**
     Creates a new UIImage from an array of RGBA bytes.
     */
    
    
    @nonobjc class func fromByteArray(_ bytes: [UInt8],
                                      width: Int,
                                      height: Int,
                                      scale: CGFloat,
                                      orientation: UIImage.Orientation,
                                      bytesPerRow: Int,
                                      colorSpace: CGColorSpace,
                                      alphaInfo: CGImageAlphaInfo) -> UIImage? {
        var image: UIImage?
        bytes.withUnsafeBytes { ptr in
            if let context = CGContext(data: UnsafeMutableRawPointer(mutating: ptr.baseAddress!),
                                       width: width,
                                       height: height,
                                       bitsPerComponent: 8,
                                       bytesPerRow: bytesPerRow,
                                       space: colorSpace,
                                       bitmapInfo: alphaInfo.rawValue),
                let cgImage = context.makeImage() {
                image = UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
            }
        }
        return image
    }
    
}

