//
//  ViewController.swift
//  MacmoteRemote
//
//  Created by Griffin Prechter on 4/10/18.
//  Copyright © 2018 Griffin Prechter. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass
import MultipeerConnectivity

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var peersLabel: UILabel!
    var isDragging = false
    var remoteService : RemoteServiceManager = RemoteServiceManager()
    var timer: Timer?
    var timer2: Timer?
    let lightImpact = UIImpactFeedbackGenerator(style: .light)
    let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    var mouseLowerLimit : CGFloat = 0.0
    var scrollDivider : CGFloat = 0.0
    var keyBoardUp = true
    
    var backgroundImages : [String:URL]?
    @IBAction func keyboardPress(_ sender: Any) {
        if keyBoardUp {
            self.keyboard.dismissKeyboard()
        } else {
            self.keyboard.becomeFirstResponder()
        }
        keyBoardUp = !keyBoardUp
    }
    @IBOutlet var panSpace: UIPanGestureRecognizer!
    @IBOutlet var gestureRec: UICustomGestureRecognizer!
    @IBOutlet var mediumPress: UILongPressGestureRecognizer!
    @IBOutlet var tapOnce: UITapGestureRecognizer!
    @IBOutlet var tapTwice: UITapGestureRecognizer!
    @IBOutlet weak var keyboard: CustomTextField!
    var connectedDeviceName : String = ""
    var server : MCPeerID?
    var peerData : Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        remoteService.delegate = self
        self.keyboard.keyDelegate = self
        self.keyboard.autocorrectionType = .no
        self.keyboard.delegate = self
        self.keyboard.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.keyboard.addTarget(self, action: #selector(enterPressed), for: .editingDidEndOnExit)
        tapOnce.require(toFail: tapTwice)
        self.mouseLowerLimit = self.view.frame.height / 2
        self.scrollDivider = self.view.frame.width - self.view.frame.width / 14
        // Do any additional setup after loading the view, typically from a nib.
        addLine(fromPoint: CGPoint(x: 0, y: self.mouseLowerLimit), toPoint: CGPoint(x: self.view.frame.width, y: self.mouseLowerLimit))
        addLine(fromPoint: CGPoint(x:  self.scrollDivider, y: self.mouseLowerLimit), toPoint: CGPoint(x: self.scrollDivider, y: 0))
        self.keyboard.becomeFirstResponder()
        self.peersLabel.text = connectedDeviceName

    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        print(textField.text!)
        print("SOMETHING HAPPENED")
        remoteService.send("k"+textField.text!, to: self.server!)
        textField.text = ""
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "toServerSelector" {
                if let dest = segue.destination as? ServerSelectionViewController {
                    dest.backgroundImages = self.backgroundImages!
                }
            }
        }
    }
    
    func mouseTouchWithinRange(with gesture: UIGestureRecognizer) -> Bool {
        return (gesture.location(in: self.view).y < self.mouseLowerLimit)
    }
    
    func addLine(fromPoint start: CGPoint, toPoint end:CGPoint) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        line.path = linePath.cgPath
        line.strokeColor = UIColor.blue.cgColor
        line.lineWidth = 1
        line.lineJoin = kCALineJoinRound
        self.view.layer.addSublayer(line)
    }
    
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        print("Thing")
    }
    
    @IBAction func panned(_ sender: UIPanGestureRecognizer) {
        if self.mouseTouchWithinRange(with: sender) {
            if sender.location(in: self.view).x < self.scrollDivider {
                if sender.numberOfTouches == 1 {
                    let velocity = sender.velocity(in: self.view)
                    print("VELOCITY: x:" + String(velocity.x.description) + " y: " + String(velocity.y.description))
                    let xVal = Int(velocity.x.rounded())
                    let yVal = Int(velocity.y.rounded())
                    print("Sending")
                    remoteService.stream("mx"+String(xVal / (8))+"y"+String(yVal / (8)))
                } else if sender.numberOfTouches == 2 {
                    let velocity = sender.velocity(in: self.view)
                    print("VELOCITY: x:" + String(velocity.x.description) + " y: " + String(velocity.y.description))
                    let xVal = Int(velocity.x.rounded())
                    let yVal = Int(velocity.y.rounded())
                    print("Sending")
                    remoteService.stream("sx"+String(xVal / (8))+"y"+String(yVal / (8)))
                }
            } else {
                let velocity = sender.velocity(in: self.view)
                print("VELOCITY: x:" + String(velocity.x.description) + " y: " + String(velocity.y.description))
                let xVal = Int(velocity.x.rounded())
                let yVal = Int(velocity.y.rounded())
                print("Sending")
                remoteService.stream("sx"+String(xVal / (8))+"y"+String(yVal / (8)))
            }
            
        }
        if sender.state == UIGestureRecognizerState.ended {
            print("ended pan")
            remoteService.stream("d1")
            isDragging = false
        }
    }
    
    @IBAction func tappedTwice(_ sender: UITapGestureRecognizer) {
        print("CLICKED Twice")
        if self.mouseTouchWithinRange(with: sender) {
            if !isDragging {
                lightImpact.impactOccurred()
                remoteService.stream("c2")
            }
        }
    }
    
    @IBAction func tapped(_ sender: UITapGestureRecognizer) {
        print("CLICKED Once")
        if self.mouseTouchWithinRange(with: sender) {
            if !isDragging {
                lightImpact.impactOccurred()
                remoteService.stream("c1")
            }
        }
    }
    
    @objc func reconnectionService(){
        self.remoteService.connectToPeer(self.server!)
        if self.peersLabel.text == "Reconnecting...." {
            self.peersLabel.text? = "Reconnecting"
        } else {
            self.peersLabel.text?.append(".")
        }
    }
    
    @objc func endReconnectionService(){
        self.timer?.invalidate()
        self.performSegue(withIdentifier: "toServerSelector", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //self.view.endEditing(true)
        /*if let force = touches.first?.force {
            if force > CGFloat(0) {
                remoteService.send(code: "c3")
            } else {
                //remoteService.send(code: "c1")
            }
        }*/
        print("Deteched touch: ",  touches.count)
    }
    @IBAction func gestured(_ sender: UIGestureRecognizer) {
        print("recognized")
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            if touch.location(in: self.view).y < self.mouseLowerLimit {
                if #available(iOS 9.0, *) {
                    if traitCollection.forceTouchCapability == UIForceTouchCapability.available {
                        if touch.force >= touch.maximumPossibleForce {
                        } else if touch.force >= 4 && !isDragging {
                            remoteService.stream("d0")
                            isDragging = true
                            heavyImpact.impactOccurred()
                            mediumPress.state = UIGestureRecognizerState.cancelled
                            //print("moving")
                        }
                    }
                }
            }
        }
    }
    @IBAction func longTouch(_ sender: UILongPressGestureRecognizer) {
        if self.mouseTouchWithinRange(with: sender) {
            if sender.state == UIGestureRecognizerState.began && !isDragging {
                remoteService.stream("c3")
                mediumImpact.impactOccurred()
                mediumPress.state = UIGestureRecognizerState.ended
            }
        }
    }
    
    @objc func enterPressed(_ textField: UITextField) -> Bool {
        remoteService.send("kreturn", to: self.server!)
        return false
    }
    
    
}

extension ViewController : RemoteServiceManagerDelegate {
    func connectedToPeer(peer: MCPeerID) {
        if self.remoteService.openStream(with: peer) {
            self.server = peer
            self.timer?.invalidate()
            self.timer2?.invalidate()
            DispatchQueue.main.async {
                self.peersLabel.text = peer.displayName
            }
            
        }
    }
    
    func disconnectedFromPeer(peer: MCPeerID) {
        self.remoteService.session.disconnect()
        self.remoteService = RemoteServiceManager()
        self.remoteService.delegate = self
        DispatchQueue.main.async {
            self.peersLabel.text = "Reconnecting"
            self.timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(self.reconnectionService), userInfo: nil, repeats: true)
            self.timer2 = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.endReconnectionService), userInfo: nil, repeats: false)
        }
    
        
    }
    
    
    func pushCode(manager: RemoteServiceManager, codeRecieved: String) {
        OperationQueue.main.addOperation {
            
        }
    }
    
    func connectedDevicesChanged(manager: RemoteServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            //self.peersLabel.text = "Connections: \(connectedDevices)"
        }
    }
    
    func lostPeer(manager: RemoteServiceManager, peer: MCPeerID) {
    }
    
    func recievedResource(from: MCPeerID, url: URL?) {
        
        //self.image.image = UIImage(data: try! Data(contentsOf: url!))
    }
    
}

extension ViewController : KeyboardDelegate {
    
    func keyPress(string: String) {
        print("Sending: ", string)
        remoteService.send("k" + string, to: self.server!)
    }
}



