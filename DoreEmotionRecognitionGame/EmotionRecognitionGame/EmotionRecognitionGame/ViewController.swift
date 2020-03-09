 

import UIKit
import Foundation
//===DoreAI Framework====
 import DoreCoreAI
 import DoreEmotionRecognition
//======================
import AVFoundation

class ViewController: UIViewController, EmotionRecoDelegate {
//variables
    var score = 0
    var timer = Timer()
    var counter = 0
    var emArray = [UIImageView]()
    var colArray = [String]()
    var lastEmotionScore = [Int](arrayLiteral: 0,0,0,0)
    var hideTimer = Timer()
    var highScore = 0
//views
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var highScoreLabel: UILabel!
    
    @IBOutlet weak var eHappy: UIImageView!
    @IBOutlet weak var eSad: UIImageView!
    @IBOutlet weak var eSurprise: UIImageView!
  
    @IBOutlet weak var eAngry: UIImageView!
    
    @IBOutlet weak var lbEmotion: UILabel!
    
    @IBOutlet weak var btnCorrect: FaveButton!
    @IBOutlet weak var cameraView: CaptureView!
    
    private var modelManager: EmotionRecognitionManager?
    var screenHeight: Double?
    var screenWidth: Double?
    
    var curIndex : Int = 0
    
      public lazy var cameraCapture = CameraFeedManager(previewView: cameraView, CameraPosition: AVCaptureDevice.Position.front )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //camerasession delegate
               cameraCapture.delegate = self
               modelManager = EmotionRecognitionManager()
                   modelManager?.delegate = self
               let isValid:Bool = (modelManager?.init_data(licKey: "RqqqFMXGWoQ8BXc4ytJGRQuGJOzvT2s586Z5YrKkEeMweaEMNXL92F27xXqw+quJlf3LKQEiemWRcL1b2RogBPD/3MxzOgZc5ggLXXNNs8B+HN8SpnO0hhoEmXDWErdyzwUa1w3WQ60YpHR1ggA/WI12CEQYCdRXdFitWwShlo7kVWa1zIKTsqa+UxfFNss1tnX0DRa6DKmnZPP+pcb5fOvAcWjLlepvfxK9QC0oCHM="))!
                   if(!isValid){
                       print("Dore : Lic not valid")
               }
   
        scoreLabel.text = "Score: \(score)"
        
        //HighScore Check
        let  storedHighScore = UserDefaults.standard.object(forKey: "highScore")
        
        if storedHighScore == nil{
            highScore = 0
            highScoreLabel.text = "HighScore : \(highScore)"
        }
        
        if let newScore = storedHighScore as? Int{
            highScore = newScore
            highScoreLabel.text =  "HighScore : \(highScore)"
        }
        
            
        
       
        emArray = [eSad,eHappy] //,eAngry,eSurprise]
        colArray = ["Sad","Happy"] //,"Angry","Surprise"]
        
       
        //Timers
        counter = 100
        timeLabel.text = String(counter)
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countDown), userInfo: nil, repeats: true)
        hideTimer = Timer.scheduledTimer(timeInterval: 3.5, target: self, selector: #selector(hideEmotion), userInfo: nil, repeats: true)
       
        hideEmotion()
                              
               
    }
    
    override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         
         cameraCapture.checkCameraConfigurationAndStartSession()
         
         
     }
     
     override func viewWillDisappear(_ animated: Bool) {
         cameraCapture.stopSession()
     }
     
     func onEmotionRecoReceived(_ info: EmotionData) {
            
         
         DispatchQueue.main.async {
            
             self.lbEmotion.text = info.eTxt
            if(info.eTxt == self.colArray[self.curIndex]){
                self.lbEmotion.textColor = UIColor.green
                if(self.lastEmotionScore[self.curIndex] > 10) {
                    self.increaseScore()
                    self.hideEmotion()
                    self.btnCorrect.setSelected(selected: true, animated: true)
                    self.lastEmotionScore[self.curIndex] = 0
                }else{
                    self.lastEmotionScore[self.curIndex] += 1
                }
            }else{
                self.lbEmotion.textColor = UIColor.red
                self.btnCorrect.setSelected(selected: false, animated: true)
                self.lastEmotionScore[0] = 0
                self.lastEmotionScore[1] = 0
                self.lastEmotionScore[2] = 0
                self.lastEmotionScore[3] = 0
            }
         }
            
     }
    
   @objc func hideEmotion() {
        for kenny in emArray{
            kenny.isHidden = true
        }
        let random = Int(arc4random_uniform(UInt32(emArray.count)))
        emArray[random].isHidden = false
        curIndex = random
    }
    

    @objc func increaseScore(){
        score += 1
        scoreLabel.text = "Score: \(score)"
    }
    @objc func countDown() {
        counter -= 1
        timeLabel.text = String(counter)
        if counter == 0 {
            timer.invalidate()
            hideTimer.invalidate()
            for kenny in emArray{
                kenny.isHidden = true
            }
                
            
            //HighScore
            if self.score > self.highScore {
                self.highScore = self.score
                highScoreLabel.text = "HighScore: \(self.highScore)"
                UserDefaults.standard.set(self.highScore,forKey: "highScore")
            }
            
            //Alert
            let alert = UIAlertController(title: "Time is up!", message: "Do you want to play again?", preferredStyle: UIAlertController.Style.alert)
            let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            let replayButton = UIAlertAction(title: "Replay", style: UIAlertAction.Style.default) { (UIAlertAction) in
                //replay function
                self.score = 0
                self.scoreLabel.text = "Score: \(self.score)"
                self.counter = 100
                self.timeLabel.text = String(self.counter)
                self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.countDown), userInfo: nil, repeats: true)
                self.hideTimer = Timer.scheduledTimer(timeInterval: 3.5, target: self, selector: #selector(self.hideEmotion), userInfo: nil, repeats: true)
                
                
            }
           
            alert.addAction(okButton)
            alert.addAction(replayButton)
            self.present(alert, animated: true, completion: nil)
        }
        
    }
}

 extension ViewController: CameraFeedManagerDelegate {
     
     
     func didOutput(pixelBuffer: CVPixelBuffer) {
         
       self.modelManager?.run_model(onFrame: pixelBuffer)
         
         
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
