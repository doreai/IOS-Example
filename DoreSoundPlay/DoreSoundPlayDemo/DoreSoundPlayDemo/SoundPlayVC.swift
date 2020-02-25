//
//  VideoBackGround.swift
//  DoreSoundPlayDemo
//
//  Copyright © 2020 dore. All rights reserved.
//

import Foundation
import UIKit
//===DoreAI Framework====
import DoreCoreAI
import DoreSoundPlay
//======================
import CoreML
import AVFoundation
import AVKit
import SoundAnalysis


class SoundPlayVC : UIViewController,  SoundPlayDelegate {
    
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var lbResult: UILabel!
    
    private var modelManager: SoundPlayManager?
    private let audioEngine = AVAudioEngine()
    var inputFormat: AVAudioFormat!
    var analyzer: SNAudioStreamAnalyzer!
    let analysisQueue = DispatchQueue(label: "com.custom.AnalysisQueue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modelManager = SoundPlayManager()
        modelManager?.delegate = self
        
        let isValid:Bool = (modelManager?.init_data(licKey: HomePage.lickey))!
        if(!isValid){
            print("Dore : Lic not valid")
            return
        }
        
        
        start_audio()
        
        
    }
    
    func start_audio(){
        inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        analyzer = SNAudioStreamAnalyzer(format: inputFormat)
        
    }
    
    func onSoundPlayReceived(_ info: String) {
        DispatchQueue.main.async {
            self.lbResult.text = info
            
        
            
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAudioEngine()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    private func startAudioEngine() {
        
        modelManager?.soundplay_model(analyzer: analyzer)
        
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 8000, format: inputFormat) { buffer, time in
            self.analysisQueue.async {
                self.analyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
        
        do{
            try audioEngine.start()
        }catch( _){
            print("error in starting the Audio Engin")
        }
    }
    
    
    
    
    
    
    
    
    
}


