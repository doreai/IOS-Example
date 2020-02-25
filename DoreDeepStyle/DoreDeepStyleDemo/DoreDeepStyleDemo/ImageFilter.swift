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
import DoreDeepStyle
//======================
import CoreML
import AVFoundation


class ImageFilter: UIViewController, DoreDeepStyleLoadDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    let reuseIdentifier = "vCell"
    @IBOutlet weak var segmentView: UIImageView!
    
    
    @IBOutlet weak var colView: UICollectionView!
    private var modelManager: DeepStyleManager?
    
    private var isStyleLoaded = false
    private var curPixelBuffr:CVPixelBuffer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //camerasession delegate
        
        colView.dataSource = self;
        colView.delegate = self;
        
        modelManager = DeepStyleManager()
        modelManager?.delegate = self
        //load license
        let isValid:Bool = (modelManager?.init_data(licKey: HomePage.lickey) ?? false)
        
        if(!isValid){
            print("Lic not valid")
        }
        
        curPixelBuffr = ImagetoPixelbuffer(from: segmentView.image!)!
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    func onDeepStyleLoadSuccess(_ info: String) {
        run_filter()
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
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 189
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! ColCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        cell.lbName.text = "Style-" + String(indexPath.item + 1)
        //cell.backgroundColor = UIColor.blue // make cell more visible in our example project
        
        return cell
    }
    
    func run_filter(){
        
        
        
        let result:TextureOut  = TextureOut ( features: (modelManager?.run_model(onFrame: curPixelBuffr))! )
        let ciImage = CIImage(cvPixelBuffer: (result.semanticPredictions))
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return  }
        let setImage = UIImage(cgImage: cgImage)
        
        
        DispatchQueue.main.async {
            self.segmentView.image = setImage
        }
        
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        print("You selected cell #\(indexPath.item)!")
        modelManager?.load_style(styleID: "s" + String((indexPath.item + 1)) )
        
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 119, height: 118)
    }
    
    
    
    
    @IBAction func btnGallery_Action(_ sender: Any) {
        let imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
extension ImageFilter: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.segmentView.image = pickedImage.resize(size: CGSize(width: 1200, height: 1200 * (pickedImage.size.height / pickedImage.size.width)))
            
            curPixelBuffr = ImagetoPixelbuffer(from: segmentView.image!)!
        }
        
        picker.dismiss(animated: true, completion: nil)
        
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
