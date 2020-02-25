//
//  VideoSegment.swift
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
import AVKit
import MobileCoreServices

class VideoSegment: UIViewController {
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var segmentView: UIImageView!
    
    @IBOutlet weak var videoView: UIView!
    
    private var modelManager: SegmentManager?
    
    let playerController = AVPlayerViewController()
    var renderer = UIGraphicsImageRenderer()
    var playTimer: Timer?
    var  player:AVPlayer = AVPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modelManager = SegmentManager()
        
        //load license
        let isValid:Bool = (modelManager?.init_data(licKey: HomePage.lickey) ?? false)
        if(!isValid){
            print("License not valid")
        }
        
        
        guard let path = Bundle.main.path(forResource: "video2", ofType:"mp4") else {
            debugPrint("video not found")
            return
        }
        
        
        player = AVPlayer(url: URL(fileURLWithPath: path))
        playerController.player = player
        videoView.addSubview(playerController.view)
        playerController.view.frame = videoView.bounds
        renderer = UIGraphicsImageRenderer(size: videoView.bounds.size)
        
        
        
        
        
    }
    
    @objc func runTimedCode(){
        
        let timetoAdd:CMTime? = CMTimeMakeWithSeconds(-0.1, preferredTimescale: 1)
        
        
        var videoImage = UIImage()
        
        if let url = (playerController.player?.currentItem?.asset as? AVURLAsset)?.url {
            
            let asset = AVAsset(url: url)
            
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.requestedTimeToleranceAfter = CMTime.zero
            imageGenerator.requestedTimeToleranceBefore = CMTime.zero
            let sTime = CMTimeAdd((playerController.player?.currentTime())!, timetoAdd!)
            
            if let thumb: CGImage = try? imageGenerator.copyCGImage(at: (sTime), actualTime: nil) {
                //print("video img successful")
                videoImage = UIImage(cgImage: thumb)
            }
            
        }
        
        //saveImage(imageName: "001.jpg", image: image)
        run_segment(videoImage)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playerController.player?.play()
        playTimer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
        
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        playerController.player?.pause()
        playTimer?.invalidate()
    }
    
    
    
    func run_segment(_ inputImage: UIImage ) {
        
        let pixelBuffer:CVPixelBuffer = ImagetoPixelbuffer(from: inputImage)!
        
       
        
        //run model and get result
        let result:segmentOut  = segmentOut ( features: (self.modelManager?.run_model(onFrame: pixelBuffer))! )
        
        //mask image White - bacground, Black - foreground
        let ciImage:UIImage = getMaskWB(result.semanticPredictions)!
        
        //extract image
        let rgbCIimage:CIImage = CIImage.init(cvPixelBuffer: pixelBuffer)
        let rgbImage:UIImage = convertCItoUIimage(cmage: rgbCIimage)
        var finalImage:UIImage = cutoutmaskImage(image: rgbImage, mask: ciImage)
        finalImage = finalImage.resized(to: inputImage.size)
        
        DispatchQueue.main.async {
            self.segmentView.image = finalImage
            self.segmentView.contentMode = .scaleAspectFit
            //self.btnSegment.isEnabled = false
        }
        
    }
    
    @IBAction func btnBrowse_Action(_ sender: Any) {
        
        let imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    
}
extension VideoSegment: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let  videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL
        player = AVPlayer(url:  videoURL!)
        playerController.player = player
        playerController.player?.play()
        
        //        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
        //            self.segmentView.image = pickedImage.resize(size: CGSize(width: 1200, height: 1200 * (pickedImage.size.height / pickedImage.size.width)))
        //        }
        //
        picker.dismiss(animated: true, completion: nil)
        // self.btnSegment.isEnabled = true
    }
    
}


