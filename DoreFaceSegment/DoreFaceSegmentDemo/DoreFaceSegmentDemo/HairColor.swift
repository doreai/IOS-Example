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
import DoreFaceSegment
//======================
import AVFoundation
import CoreML


class HairColor : UIViewController, CameraFeedManagerDelegate {
    
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var cameraView: CaptureView!
    @IBOutlet weak var maskoutView: UIImageView!
    
    private var modelManager: FaceSegmentManager?
    
    public var RGBCode:[Int] = [155, 77, 243]
    
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
      
        let inputimage:UIImage = UIImage(pixelBuffer: pixelBuffer)!
        //run model and get result
        let outImage:CGImage = (self.modelManager?.run_model(onFrame: inputimage, faceSegmentType: FaceSegmentManager.FaceSegmentType.FACE))!
        let maskImage:UIImage = UIImage(cgImage: outImage)
         
       
        
        let ciImage:UIImage = ColorMask(maskImage.preprocess(image: maskImage)!,R: RGBCode[0], G: RGBCode[1], B: RGBCode[2], A: 255)!

        let rgbCIimage:CIImage = CIImage.init(cvPixelBuffer: pixelBuffer)
        let img:UIImage = convertCItoUIimage(cmage: rgbCIimage)

        //you can change BlendMode and adjust alpha value (0.1 to 1)
        let outputImage:UIImage = maskblendImage(backgroundImage: img, maskImage: ciImage , maskblendMode: CGBlendMode.multiply, blendAlpha: 0.8)!


        DispatchQueue.main.async {
            self.maskoutView.image = outputImage
        }
        
        
    }
    
    
    func ColorMask(_ softmax: MLMultiArray, R:Int, G:Int, B:Int, A:Int)-> UIImage?  {
                
            let label_map = [
                0:  [R, G, B, A],
                1:  [0, 0, 0, 0]
            ]
        
        let codes = MultiArray<Double>(softmax)
        // get the shape information from the probs
        let height = codes.shape[1]
        let width = codes.shape[2]
            // initialize some bytes to store the image in
            var bytes = [UInt8](repeating: 255, count: height * width * 4 )
            // iterate over the pixels in the output probs
            for h in 0 ..< height {
                for w in 0 ..< width {
                    let offset = h * width * 4 + w  * 4
                    let pCode1:Double =  (codes[0, h, w])
                    
                    var rgb = label_map[0]
                    if(pCode1 < 0.5){
                       rgb = label_map[1]
                    }
                    // set the bytes to the RGB value and alpha of 1.0 (255)
                    bytes[offset + 0] =  UInt8(rgb![0])
                    bytes[offset + 1] =  UInt8(rgb![1])
                    bytes[offset + 2] =  UInt8(rgb![2])
                    bytes[offset + 3] = UInt8(rgb![3])
                }
            }
            // create a UIImage from the byte array
            return UIImage.fromByteArray(bytes, width: width, height: height,
                                         scale: 0, orientation: .up,
                                         bytesPerRow: width * 4,
                                         colorSpace: CGColorSpaceCreateDeviceRGB(),
                                         alphaInfo: .premultipliedLast)

    }
    
    
    func ipMaskedImageNamed(image:UIImage, color:UIColor) -> UIImage {
        
        let rect:CGRect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: image.size.width, height: image.size.height))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        let c:CGContext = UIGraphicsGetCurrentContext()!
        image.draw(in: rect)
        c.setFillColor(color.cgColor)
        c.setBlendMode(CGBlendMode.multiply)
        c.fill(rect)
        let result:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return result
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

