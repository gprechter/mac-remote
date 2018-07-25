//
//  ViewController.swift
//  MacmoteServer
//
//  Created by Griffin Prechter on 4/9/18.
//  Copyright © 2018 Griffin Prechter. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    let remoteService = RemoteServiceManager()
    var myApplication : NSApplication?
    var myAppDelegate : NSApplicationDelegate?
    
    @IBOutlet weak var peersLabel: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        remoteService.delegate = self
        // Do any additional setup after loading the view.
        self.myApplication = NSApp as! NSApplication
        self.myAppDelegate = self.myApplication!.delegate
    }
    
    var forcePress = false
    var dragging = false
    
    func change(x : Int, y: Int) {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y
        var mouseWarpLocation = CGPoint(x: mouseLoc.x+CGFloat(x), y: mouseLoc.y+CGFloat(y))
        if dragging {
            print("Dragging")
            let eventDrag = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: mouseWarpLocation, mouseButton: .left)
            eventDrag!.setIntegerValueField(.mouseEventPressure, value: 1)
            eventDrag!.type = .leftMouseDragged
            eventDrag!.post(tap: .cghidEventTap)
            //CGAssociateMouseAndMouseCursorPosition(1)
            /*CGWarpMouseCursorPosition(mouseWarpLocation);*/
        }
        if mouseWarpLocation.y >= NSScreen.screens[0].frame.height {
            mouseWarpLocation.y = NSScreen.screens[0].frame.height
        } else if mouseWarpLocation.x >= NSScreen.screens[0].frame.width {
            mouseWarpLocation.x = NSScreen.screens[0].frame.width
        } else if mouseWarpLocation.y <= 0 {
            mouseWarpLocation.y = 0
        } else if mouseWarpLocation.x <= 0 {
            mouseWarpLocation.x = 0
        }
            let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: mouseWarpLocation, mouseButton: .center)
            //event!.setIntegerValueField(.mouseEventDeltaX, value: Int64(x))
            //event!.setIntegerValueField(.mouseEventDeltaY, value: Int64(y))
            event!.post(tap: .cghidEventTap)
    }
    
    func scroll(x : Int, y: Int) {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y
        let mouseWarpLocation = CGPoint(x: mouseLoc.x+CGFloat(x), y: mouseLoc.y+CGFloat(y))
        print("SCROLLING")
        let event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: Int32(y/8), wheel2: 1, wheel3: 1)
        event!.post(tap: .cghidEventTap)
        //createScrollWheelEvent(Int32(mouseWarpLocation.y) * -10)
    }
    
    func click(type: Int) {
        var mousePosition: CGPoint = NSEvent.mouseLocation
        mousePosition.y = NSHeight(NSScreen.screens[0].frame) - mousePosition.y
        let leftMouseDownEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: mousePosition, mouseButton: .left)
        let leftMouseUpEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: mousePosition, mouseButton: .left)
        let rightMouseDownEvent = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: mousePosition, mouseButton: .right)
        let rightMouseUpEvent = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: mousePosition, mouseButton: .right)
        if self.dragging {
            self.dragging = false
            leftMouseUpEvent?.post(tap: .cghidEventTap)
            return
        }
        if type == 1 {
            leftMouseDownEvent?.post(tap: .cghidEventTap)
            leftMouseUpEvent?.post(tap: .cghidEventTap)
        } else if type == 2 {
            leftMouseDownEvent?.post(tap: .cghidEventTap)
            leftMouseUpEvent?.post(tap: .cghidEventTap)
            doubleClick(clickCount: 2)
        } else if type == 3 {
            rightMouseDownEvent?.post(tap: .cghidEventTap)
            rightMouseUpEvent?.post(tap: .cghidEventTap)
        }
    }
    
    func endDrag() {
        var mousePosition: CGPoint = NSEvent.mouseLocation
        mousePosition.y = NSHeight(NSScreen.screens[0].frame) - mousePosition.y
        let leftMouseUpEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: mousePosition, mouseButton: .left)
        if self.dragging {
            self.dragging = false
            leftMouseUpEvent?.post(tap: .cghidEventTap)
            return
        }
    }
    
    func doubleClick(clickCount: Int) {
        var mousePosition: CGPoint = NSEvent.mouseLocation
        mousePosition.y = NSHeight(NSScreen.screens[0].frame) - mousePosition.y
        print("double clicked")
        if let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: mousePosition, mouseButton: .left) {
            event.setIntegerValueField(CGEventField.mouseEventClickState, value: 2)
            event.post(tap: .cghidEventTap)
            event.type = .leftMouseUp
            event.post(tap: .cghidEventTap)
            event.type = .leftMouseDown
            event.post(tap: .cghidEventTap)
            event.type = .leftMouseUp
            event.post(tap: .cghidEventTap)
        }
        /*CGEventSetType(theEvent, kCGEventLeftMouseUp)
        CGEventPost(kCGHIDEventTap, theEvent)
        CGEventSetType(theEvent, kCGEventLeftMouseDown)
        CGEventPost(kCGHIDEventTap, theEvent)
        CGEventSetType(theEvent, kCGEventLeftMouseUp)
        CGEventPost(kCGHIDEventTap, theEvent)
        CFRelease(theEvent)*/
    }
    
    func beginDragging() {
        var mousePosition: CGPoint = NSEvent.mouseLocation
        mousePosition.y = NSHeight(NSScreen.screens[0].frame) - mousePosition.y
        self.click(type: 1)
        print("Dragging Began")
        if let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: mousePosition, mouseButton: .left) {
            event.setIntegerValueField(.mouseEventPressure, value: 1)
            event.type = .leftMouseUp
            event.post(tap: .cghidEventTap)
            event.type = .leftMouseDown
            event.post(tap: .cghidEventTap)
        }
        self.dragging = true
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func keyPress(key: String) {
        if key == "return" {
            let eventSource = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
            let keyDownEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: 36, keyDown: true)
            let keyUpEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: 36, keyDown: false)
            keyDownEvent!.post(tap: .cghidEventTap)
            keyUpEvent!.post(tap: .cghidEventTap)
        } else {
            var utf16Chars = Array(key.utf16)
            if key == "backwards" {
                utf16Chars = Array([UInt16(8)])
            }
            let eventSource = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
            let keyDownEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true)
            let keyUpEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false)
            keyDownEvent!.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
            keyDownEvent!.post(tap: .cghidEventTap)
            keyUpEvent!.post(tap: .cghidEventTap)
        }
    }
}
extension ViewController : RemoteServiceManagerDelegate {
    
    func pushCode(manager: RemoteServiceManager, code: String) {
        //OperationQueue.main.addOperation {
            print("MOVE MOUSE: ",code)
            if code.prefix(1) == "m" {
                if let xIndex = code.index(of: "x") {
                    if let yIndex = code.index(of: "y") {
                        if let xAmm = Int(code.suffix(from: code.index(after: xIndex)).prefix(upTo: yIndex)){
                            if let yAmm = Int(code.suffix(from: code.index(after: yIndex)).prefix(upTo: code.index(of: " ")!)) {
                                self.change(x: xAmm, y: yAmm)
                                print(xAmm, "   ", yAmm)
                            }
                        }
                        
                    }
                }
            } else if code.prefix(1) == "c" {
                print("CLICK")
                if let clickType = Int(code.suffix(from: code.index(after: code.index(of: "c")!)).prefix(1)) {
                    if clickType == 1 {
                        self.click(type: 1)
                        self.forcePress = false
                    } else if clickType == 2 {
                        self.click(type: 2)
                    } else if clickType == 3 {
                        self.click(type: 3)
                    }
                }
            } else if code.prefix(1) == "d" {
                print("DRAG")
                if let clickType = Int(code.suffix(from: code.index(after: code.index(of: "d")!)).prefix(1)) {
                    if clickType == 0 {
                        self.beginDragging()
                    } else if clickType == 1 {
                        self.endDrag()
                    }
                }
            } else if code.prefix(1) == "s" {
                print("SCROLL")
                if let xIndex = code.index(of: "x") {
                    if let yIndex = code.index(of: "y") {
                        if let xAmm = Int(code.suffix(from: code.index(after: xIndex)).prefix(upTo: yIndex)){
                            if let yAmm = Int(code.suffix(from: code.index(after: yIndex)).prefix(upTo: code.index(of: " ")!)) {
                                self.scroll(x: xAmm, y: yAmm)
                                print(xAmm, "   ", yAmm)
                            }
                        }
                        
                    }
                }
            } else if code.prefix(1) == "k" {
                print("KEYPRESS")
                let key = String(code.suffix(from: code.index(after: code.index(of: "k")!)))
                self.keyPress(key: key)
                
            }
            
        //}
    }
    
    func connectedDevicesChanged(manager: RemoteServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            self.peersLabel.stringValue = "Connections: \(connectedDevices)"
        }
    }
    
}


