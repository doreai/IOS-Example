//
//  ImageSegment.swift
//  DorePetSegmentDemo
//
//  Copyright © 2020 dore. All rights reserved.
//

import Foundation
import UIKit
//===DoreAI Framework====
import DoreCoreAI
import DorePetSegment
//======================
import AVFoundation


class ImageSegment: UIViewController {
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var segmentView: UIImageView!
    @IBOutlet weak var btnSegment: UIBarButtonItem!
    
    private var modelManager: PetSegmentManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modelManager = PetSegmentManager()
        
        //load license
        let isValid:Bool = (modelManager?.init_data(licKey: HomePage.lickey) ?? false)
        if(!isValid){
            print("Lic not valid")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    func run_segment() {
        
        let pixelBuffer:CVPixelBuffer = ImagetoPixelbuffer(from: segmentView.image!)!
        
        
        //run model and get result
        let result:segmentOut  = segmentOut ( features: (self.modelManager?.run_model(onFrame: pixelBuffer))! )
        
        //mask image White - bacground, Black - foreground
        let ciImage:UIImage = getMaskWB(result.semanticPredictions)!
        
        //extract image
        let rgbCIimage:CIImage = CIImage.init(cvPixelBuffer: pixelBuffer)
        let rgbImage:UIImage = convertCItoUIimage(cmage: rgbCIimage)
        let finalImage:UIImage = cutoutmaskImage(image: rgbImage, mask: ciImage)
        
        
        DispatchQueue.main.async {
            self.segmentView.image = finalImage
            self.segmentView.contentMode = .scaleAspectFit
            self.btnSegment.isEnabled = false
        }
        
    }
    
    
    @IBAction func btnSegment_Action(_ sender: Any) {
        
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
