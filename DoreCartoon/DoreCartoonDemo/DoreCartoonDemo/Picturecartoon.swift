//
//  ImageSegment.swift
//  DoreCartoonDemo
//
//  Copyright © 2020 dore. All rights reserved.
//

import Foundation
import UIKit
//===DoreAI Framework====
import DoreCoreAI
import DoreCartoon
//======================
import AVFoundation


class Picturecartoon: UIViewController {
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var segmentView: UIImageView!
    @IBOutlet weak var btnSegment: UIBarButtonItem!
    
    private var modelManager: CartoonManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modelManager = CartoonManager()
        
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
        
        
        let result  =  (self.modelManager?.run_model(onFrame: pixelBuffer,variantType: CartoonManager.CartoonVariantType.Standard)!)!
        //run model and get result
       
        
       // mask image White - bacground, Black - foreground
        let ciImage:UIImage = result.GeneratedImage(Width: Int(segmentView.image?.size.width ?? 0), Height: Int(segmentView.image?.size.height ?? 0))
        
        
        
        
        DispatchQueue.main.async {
            self.segmentView.image = ciImage
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
extension Picturecartoon: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
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
