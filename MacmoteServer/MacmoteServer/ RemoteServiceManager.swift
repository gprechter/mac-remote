//
//  ColorServiceManager.swift
//  ConnectedColors
//
//  Created by Griffin Prechter on 4/6/18.
//  Copyright © 2018 Example. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class RemoteServiceManager : NSObject {
    
    private let SERVICE_TYPE = "macmote"
    private let myPeerId = MCPeerID(displayName: Host.current().localizedName ?? "")
    private let serviceBrowser : MCNearbyServiceBrowser
    
    var delegate : RemoteServiceManagerDelegate?
    
    override init() {
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: SERVICE_TYPE)
        
        super.init()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    func send(_ message: String, to peer: MCPeerID) {
        if self.session.connectedPeers.contains(peer) {
            do {
                try self.session.send(message.data(using: .utf8)!, toPeers: [peer], with: .reliable)
                NSLog("%@", "Sending message: \(message) to \(peer.displayName)")
            } catch let error {
                NSLog("%@", "Session encountered an error when sending message: \(error)")
            }
        }
    }
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        session.delegate = self
        return session
    }()
    
}

extension RemoteServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: "SERVER".data(using: .utf8)!, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
    
}

extension RemoteServiceManager : StreamDelegate {
    func stream(_ stream: Stream, handle eventCode: Stream.Event)
    {
        if let inputStream = stream as? InputStream, eventCode == Stream.Event.hasBytesAvailable
        {
            print("RECIEVED STREAM")
            var buffer = [UInt8](repeating: 0, count: 1024)
            let numberBytes = inputStream.read(&buffer, maxLength: 16)
            let dataString = NSData(bytes: &buffer, length: numberBytes)
            if let message = String(data: dataString as Data, encoding: .utf8) {
                print("RECIEVED: \'" + message + "\' from STREAM")
                DispatchQueue.main.async {
                    self.delegate?.pushCode(manager: self, code: message)
                }
                if message != "" {
                   // self.stream(stream, handle: eventCode)
                }
            }
        }
    }
}

extension RemoteServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state)")
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
        switch state {
        case .connected:
            self.session.sendResource(at: NSWorkspace.shared.desktopImageURL(for: NSScreen.main!)!, withName: "backgroundImage", toPeer: peerID, withCompletionHandler: nil)
        case .connecting:
            print("Connecting")
        case .notConnected:
            print("Disconnected")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        //NSLog("%@", "didReceiveData: \(data)")
        let str = String(data: data, encoding: .utf8)!
        //NSLog("%@", str)
        self.delegate?.pushCode(manager: self, code: str)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        stream.delegate = self
        stream.schedule(in: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        stream.open()
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
}

protocol RemoteServiceManagerDelegate {

    func pushCode(manager : RemoteServiceManager, code: String)
    func connectedDevicesChanged(manager : RemoteServiceManager, connectedDevices: [String])
    
}
