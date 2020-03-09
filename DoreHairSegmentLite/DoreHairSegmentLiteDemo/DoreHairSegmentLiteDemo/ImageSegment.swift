//
//  ImageSegment.swift
//  DoreHairSegmentLiteDemo
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


class ImageSegment: UIViewController, HairSegmentLiteDelegate {
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var segmentView: UIImageView!
    @IBOutlet weak var btnSegment: UIBarButtonItem!
    
    private var modelManager: HairSegmentLiteManager?
    
    public var alertView:UIAlertController!
    public var progressView:UIProgressView!
    
    private var isLibLoaded:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnSegment.isEnabled = false
        
        //Just create your alert for downloading library files (don't worry.. download time will be few seconds..!)
        alertView = UIAlertController(title: "Loading", message: "Please Wait...!", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if(isLibLoaded) { return }
        
        modelManager = HairSegmentLiteManager()
        modelManager?.delegate = self
        
        
        
        //Show it to your users
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
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    //===DoreHairSegmentLiteDelegate===
    func onHairSegmentLiteSuccess(_ info: String) {
        self.alertView.dismiss(animated: true, completion: nil)
        //DoreHairSegment Library files downloaded successfully...! Ready to run segment
        self.btnSegment.isEnabled = true
        self.isLibLoaded = true
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
    
    func run_segment(RGBCode:[Int]) {
        
        let pixelBuffer:CVPixelBuffer = buffer(from: segmentView.image!)!
        
        
        
        //run model and get result
        let result:segmentOut  = segmentOut ( features: (self.modelManager?.run_model(onFrame: pixelBuffer))! )
        let ciImage:UIImage = getColorMask(result.semanticPredictions,R: RGBCode[0], G: RGBCode[1], B: RGBCode[2], A: 255)!
        
        let rgbCIimage:CIImage = CIImage.init(cvPixelBuffer: pixelBuffer)
        let img:UIImage = convertCItoUIimage(cmage: rgbCIimage)
        
        //you can change BlendMode and adjust alpha value (0.1 to 1)
        let outputImage:UIImage = maskblendImage(backgroundImage: img, maskImage: ciImage, maskblendMode: CGBlendMode.multiply, blendAlpha: 0.8)!
        
        DispatchQueue.main.async {
            self.segmentView.image = outputImage
            self.btnSegment.isEnabled = false
        }
        
    }
    
    func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    
    
    @IBAction func btnSegment_Action(_ sender: Any) {
        let RGBCode:[Int] = [155, 77, 243]
        run_segment(RGBCode: RGBCode)
    }
    
    @IBAction func btnGallery_Action(_ sender: Any) {
        let imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
}
extension ImageSegment: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.segmentView.image = pickedImage.resize(size: CGSize(width: 1200, height: 1200 * (pickedImage.size.height / pickedImage.size.width)))
        }
        
        picker.dismiss(animated: true, completion: nil)
        self.btnSegment.isEnabled = true
    }
    
}

extension UIImage {
    
    func resize(size: CGSize!) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        self.draw(in:rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
    
}
