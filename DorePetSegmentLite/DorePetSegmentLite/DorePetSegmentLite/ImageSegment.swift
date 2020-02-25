//
//  ImageSegment.swift
//  DoreSegmentDemo
//
//  Copyright © 2020 dore. All rights reserved.
//

import Foundation
import UIKit
//===DoreAI Framework====
import DoreCoreAI
import DorePetSegmentLite
//======================
import CoreML
import AVFoundation


class ImageSegment: UIViewController, PetSegmentLiteDelegate {
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var segmentView: UIImageView!
    @IBOutlet weak var btnSegment: UIBarButtonItem!
    
    private var modelManager: PetSegmentLiteManager!
    
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
        
        modelManager = PetSegmentLiteManager()
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
    
    
    
    //===DoreSegmentLiteDelegate===
    func onPetSegmentLiteSuccess(_ info: String) {
        self.alertView.dismiss(animated: true, completion: nil)
        //DoreSegment Library files downloaded successfully...! Ready to run segment
        self.btnSegment.isEnabled = true
        self.isLibLoaded = true
    }
    
    func onPetSegmentLiteFailure(_ error: String) {
        self.alertView.dismiss(animated: true, completion: nil)
        //DoreSegment Library files downloading failed..!
        print(error)
    }
    
    func onPetSegmentLiteProgressUpdate(_ progress: String) {
        //DoreSegment Library files downloading...!
        print(progress)
        self.progressView!.progress = Float(progress)!
    }
    
    func onPetSegmentLiteDownloadSpeed(_ dps: String) {
        print(dps)
    }
    //==============================
    
    
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
