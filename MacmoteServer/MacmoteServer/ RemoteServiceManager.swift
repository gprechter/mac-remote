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
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    var backendManager = RemoteBackendServiceManager()
    
    var delegate : RemoteServiceManagerDelegate?
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: ["deviceType": "SERVER", "password": "hidukens"], serviceType: SERVICE_TYPE)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: SERVICE_TYPE)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
    }
    
    func send(code : String) {
        if session.connectedPeers.count > 0 {
            do {
                try self.session.send(code.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
        
    }
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        session.delegate = self
        return session
    }()
    
}

extension RemoteServiceManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
    
}

extension RemoteServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        //browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
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
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        //NSLog("%@", "didReceiveData: \(data)")
        let str = String(data: data, encoding: .utf8)!
        //NSLog("%@", str)
        self.delegate?.pushCode(manager: self, code: str)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("ESTABLISHED STREAM")
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
