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
    @IBOutlet var mediumPress: UILongPressGestureRecognizer!
    @IBOutlet var tapOnce: UITapGestureRecognizer!
    @IBOutlet var tapTwice: UITapGestureRecognizer!
    @IBOutlet weak var keyboard: CustomTextField!
    var connectedDeviceName : String = ""
    var remote: Remote?
    var peerData : Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.keyboard.keyDelegate = self
        self.keyboard.autocorrectionType = .no
        self.keyboard.delegate = self
        self.keyboard.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.keyboard.addTarget(self, action: #selector(enterPressed), for: .editingDidEndOnExit)
        tapOnce.require(toFail: tapTwice)
        self.mouseLowerLimit = self.view.frame.height / 2
        self.scrollDivider = self.view.frame.width - self.view.frame.width / 14
        addLine(fromPoint: CGPoint(x: 0, y: self.mouseLowerLimit), toPoint: CGPoint(x: self.view.frame.width, y: self.mouseLowerLimit))
        addLine(fromPoint: CGPoint(x:  self.scrollDivider, y: self.mouseLowerLimit), toPoint: CGPoint(x: self.scrollDivider, y: 0))
        self.keyboard.becomeFirstResponder()
        self.peersLabel.text = connectedDeviceName

    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        remote?.send(string: "k"+textField.text!)
        textField.text = ""
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "toServerSelector" {
                if let dest = segue.destination as? ViewController {
                    dest.remote = self.remote
                    remote?.delegate = dest
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
    
    @IBAction func panned(_ sender: UIPanGestureRecognizer) {
        if self.mouseTouchWithinRange(with: sender) {
            if sender.location(in: self.view).x < self.scrollDivider {
                if sender.numberOfTouches == 1 {
                    let velocity = sender.velocity(in: self.view)
                    let xVal = Int(velocity.x.rounded())
                    let yVal = Int(velocity.y.rounded())
                    remote?.send(string: "mx"+String(xVal / (8))+"y"+String(yVal / (8)))
                } else if sender.numberOfTouches == 2 {
                    let velocity = sender.velocity(in: self.view)
                    let xVal = Int(velocity.x.rounded())
                    let yVal = Int(velocity.y.rounded())
                    remote?.send(string: "sx"+String(xVal / (8))+"y"+String(yVal / (8)))
                }
            } else {
                let velocity = sender.velocity(in: self.view)
                let xVal = Int(velocity.x.rounded())
                let yVal = Int(velocity.y.rounded())
                remote?.send(string: "sx"+String(xVal / (8))+"y"+String(yVal / (8)))
            }
            
        }
        if sender.state == UIGestureRecognizerState.ended {
            remote?.send(string: "d1")
            isDragging = false
        }
    }
    
    @IBAction func tappedTwice(_ sender: UITapGestureRecognizer) {
        if self.mouseTouchWithinRange(with: sender) {
            if !isDragging {
                lightImpact.impactOccurred()
                remote?.send(string: "c2")
            }
        }
    }
    
    @IBAction func tapped(_ sender: UITapGestureRecognizer) {
        if self.mouseTouchWithinRange(with: sender) {
            if !isDragging {
                lightImpact.impactOccurred()
                remote?.send(string: "c1")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func gestured(_ sender: UIGestureRecognizer) {
        
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            if touch.location(in: self.view).y < self.mouseLowerLimit {
                if #available(iOS 9.0, *) {
                    if traitCollection.forceTouchCapability == UIForceTouchCapability.available {
                        if touch.force >= touch.maximumPossibleForce {
                        } else if touch.force >= 4 && !isDragging {
                            remote?.send(string: "d0")
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
                remote?.send(string: "c3")
                mediumImpact.impactOccurred()
                mediumPress.state = UIGestureRecognizerState.ended
            }
        }
    }
    
    @objc func enterPressed(_ textField: UITextField) -> Bool {
        remote?.send(string: "kreturn")
        return false
    }
    
    
}

extension ViewController : RemoteDelegate {
    func serviceBegan(with device: Device) {
    }
    
    func stateUpdated() {
        if let isAvailable = remote?.availableDevices.contains(where: {$0.peerID == remote?.device?.peerID}), !isAvailable {
            self.performSegue(withIdentifier: "toServerSelector", sender: self)
        }
    }
    
    func recieved(data: Data) {
        
    }
}

extension ViewController : KeyboardDelegate {
    func keyPress(string: String) {
        remote?.send(string: "k" + string)
    }
}



