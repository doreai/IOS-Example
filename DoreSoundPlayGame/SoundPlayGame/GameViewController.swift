 

import Foundation
import UIKit
import QuartzCore
import SceneKit
//===DoreAI Framework====
import DoreCoreAI
import DoreSoundPlay
//======================
import AVKit
import SoundAnalysis



class GameViewController: UIViewController, SCNSceneRendererDelegate, SoundPlayDelegate {
    
    var gameView : SCNView!
    var gameScene : SCNScene!
    var cameraNode : SCNNode!
    var targetCreationTime : TimeInterval = 0
    
    
    private var modelManager: SoundPlayManager?
       private let audioEngine = AVAudioEngine()
       var inputFormat: AVAudioFormat!
       var analyzer: SNAudioStreamAnalyzer!
       let analysisQueue = DispatchQueue(label: "com.custom.AnalysisQueue")
       
    
    var scoretext = SCNTextNode(text: "Whistle : 0 , Clap: 0", width: 1.0, isWrapped: false, font: UIFont(name: "Helvetica", size: 2.5),  depth: 0.05)
    
        var lbListening = SCNTextNode(text: "Listening...", width: 1.0, isWrapped: false, font: UIFont(name: "Helvetica", size: 2.5),  depth: 0.05)
    
    var whistleScore: Int = 0
    var clapScore: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        initScene()
        initCamera()
        
      modelManager = SoundPlayManager()
             modelManager?.delegate = self
             
             let isValid:Bool = (modelManager?.init_data(licKey: "YUY+TaHBdUwLJwMxEDBIgummu9q7xPBTNqcUptjjYeVDfGjpCKS3pa8Xie/A3E79ZeBunzaM4yFzjggDNCncKTWouFKggaiGY7BNbG3IBY3Z8LEguv3dyVRKs1NozzmFJ1Kscraze2ZL65FpQXY73FoS9ockjUdqeGcyJCf9g+idwsqJT0rRfnOco9u/5WCr6dhEajHtxbinNNah7/Bteg== "))!
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
            if(info == "idle"){
                    self.lbListening.getText()?.string = "Listening..."
            }else{
                self.lbListening.getText()?.string = info
                if(info == "whistle" || info == "clap") {
                    self.shoot_node(nodename: info)
                }
                
                
            }
              
          }
      }
    
    public func shoot_node(nodename: String){
        for node in gameScene.rootNode.childNodes {
            if  node.name == nodename {
                if node.presentation.position.y > 3 {
                    
                    DispatchQueue.main.async {
                        node.removeFromParentNode()
                        if(nodename == "whistle"){ self.whistleScore += 1}
                        if(nodename == "clap"){ self.clapScore += 1}
                        self.scoretext.getText()?.string = "Whistle : " + String(self.whistleScore) + " , Clap : " + String(self.clapScore)
                    }
                    return
                }
            }
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
      
      
      
    
    func createTarget(){
        
          DispatchQueue.global().async {
            
            let randomNumInt     = Int.random(in: 1..<3)
        
            let modelscn = SCNScene(named: "model" + String(randomNumInt) + ".scn")!
            
        
 
        
            let geometryNode = modelscn.rootNode.childNode(withName: "Model", recursively: true)
       
            
            DispatchQueue.main.async {
                
                
                
                geometryNode?.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
                
                if(randomNumInt == 1){
                    geometryNode?.name = "whistle"
                }else{
                    geometryNode?.name = "clap"
                }
                
 
        
                self.gameScene.rootNode.addChildNode((geometryNode! ))
                
                let randomDir:Float = arc4random_uniform(2) == 0 ? -1.0 : 1.0
                let force = SCNVector3Make(randomDir, 15, 0)
                
                geometryNode?.physicsBody?.applyForce(force, at: SCNVector3Make(0.05, 0.05, 0.05), asImpulse: true)
                    
            }
        
        }
      
        
        
    }
    
    func initView() {
        gameView = self.view as? SCNView
        gameView.allowsCameraControl = false
        gameView.autoenablesDefaultLighting = true
        
        gameView.delegate = self
    }
    
    func initScene(){
        gameScene = SCNScene()
        gameView.scene = gameScene
         
        gameView.isPlaying = true
        
        
         scoretext.firstMaterial!.diffuse.contents =  UIColor.blue
         scoretext.firstMaterial!.specular.contents = UIColor.blue
         scoretext.position =  SCNVector3Make(1, 0, -1)
         scoretext.scale = SCNVector3Make(0.1, 0.1, 0.1)
         gameScene.rootNode.addChildNode(scoretext)
        
        
                lbListening.firstMaterial!.diffuse.contents =  UIColor.green
                lbListening.firstMaterial!.specular.contents = UIColor.yellow
                lbListening.position =  SCNVector3Make(-2, 0, -1)
                lbListening.scale = SCNVector3Make(0.2, 0.2, 0.2)
                gameScene.rootNode.addChildNode(lbListening)
         
        
        
    }
    
    func initCamera(){
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        
        cameraNode.position = SCNVector3(x: 0, y: 6, z: 10)
        
        gameScene.rootNode.addChildNode(cameraNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if time > targetCreationTime {
            createTarget()
            targetCreationTime = time + 1.5
        }
        
        cleanUp()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
     //   let touch = touches.first!
        
//        let location = touch.location(in: gameView)
//
//        let hitList = gameView.hitTest(location, options: nil)
//
//        if let hitObject = hitList.first {
//            let node = hitObject.node
//
//            if node.name == "whistle" {
//                node.removeFromParentNode()
//                self.gameView.backgroundColor = UIColor.white
//            }else{
//                node.removeFromParentNode()
//                self.gameView.backgroundColor = UIColor.red
//            }
//        }
    }
    
    func cleanUp(){
        
        DispatchQueue.main.async {
            for node in self.gameScene.rootNode.childNodes {
                if node.presentation.position.y < -5 {
                    node.removeFromParentNode()
                }
            }
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
