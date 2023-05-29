//
//  ImageSegment.swift
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


class ImageSegment: UIViewController {
    
    @IBOutlet weak var segmentView: UIImageView!
    @IBOutlet weak var btnSegment: UIBarButtonItem!
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private var modelManager: FaceSegmentManager?
    private var imgpixelBuffer:CVPixelBuffer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modelManager = FaceSegmentManager()
        
        //load license
        let isValid:Bool = (modelManager?.init_data(licKey: HomePage.lickey) ?? false)
        if(!isValid){
            print("Lic not valid")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
         imgpixelBuffer = buffer(from: segmentView.image!)!
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    func run_segment() {
        
        
        let inputimage:UIImage = UIImage(pixelBuffer: imgpixelBuffer!)!
        //run model and get result
        let outImage:CGImage = (self.modelManager?.run_model(onFrame: inputimage, faceSegmentType: FaceSegmentManager.FaceSegmentType.FACE))!
        
                
        //get random color
        var RGBCode:[Int] = [155, 77, 243]
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
        
        let maskImage:UIImage = UIImage(cgImage: outImage)
        
         
        
        let ciImage:UIImage = ColorMask(maskImage.preprocess(image: maskImage)!,R: RGBCode[0], G: RGBCode[1], B: RGBCode[2], A: 255)!

        let rgbCIimage:CIImage = CIImage.init(cvPixelBuffer: imgpixelBuffer!)
        let img:UIImage = convertCItoUIimage(cmage: rgbCIimage)

        //you can change BlendMode and adjust alpha value (0.1 to 1)
        let outputImage:UIImage = maskblendImage(backgroundImage: img, maskImage: ciImage, maskblendMode: CGBlendMode.multiply, blendAlpha: 0.8)!

        DispatchQueue.main.async {
            self.segmentView.image = outputImage

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
        //let RGBCode:[Int] = [155, 77, 243]
        run_segment()
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
             imgpixelBuffer = buffer(from: segmentView.image!)!
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
    
    func resize(to newSize: CGSize) -> UIImage {
                    UIGraphicsBeginImageContextWithOptions(CGSize(width: newSize.width, height: newSize.height), true, 1.0)
            self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            return resizedImage
    }
    
    func pixelData() -> [UInt8]? {
            let dataSize = size.width * size.height * 4
            var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: &pixelData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 4 * Int(size.width), space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            
            guard let cgImage = self.cgImage else { return nil }
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            
            return pixelData
    }
    func preprocess(image: UIImage) -> MLMultiArray? {
        let size = CGSize(width: 224, height: 224)
        
        
        guard let pixels = image.resize(to: size).pixelData()?.map({ (Double($0) / 255.0 - 0.5) * 2 }) else {
            return nil
        }

        guard let array = try? MLMultiArray(shape: [3, 224, 224], dataType: .double) else {
            return nil
        }
        
        let r = pixels.enumerated().filter { $0.offset % 4 == 0 }.map { $0.element }
        let g = pixels.enumerated().filter { $0.offset % 4 == 1 }.map { $0.element }
        let b = pixels.enumerated().filter { $0.offset % 4 == 2 }.map { $0.element }

        let combination = r + g + b
        for (index, element) in combination.enumerated() {
            array[index] = NSNumber(value: element)
        }

        return array
    }
    
}
