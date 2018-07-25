//
//  RemoteServiceManager.swift
//  MacMote Client
//
//  Created by Griffin Prechter on 4/9/18.
//  Copyright © 2018 Griffin Prechter. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class RemoteBackendServiceManager: NSObject, StreamDelegate  {
    
    private let SERVICE_TYPE = "macmote-backend"
    private let peerId = MCPeerID(displayName: UIDevice.current.name + "-backend")
    
    private let backendServiceBrowser : MCNearbyServiceBrowser
    var delegate : RemoteBackendServiceManagerDelegate?
    
    override init() {
        self.backendServiceBrowser = MCNearbyServiceBrowser(peer: peerId, serviceType: SERVICE_TYPE)
        super.init()
    
        self.backendServiceBrowser.delegate = self
        self.backendServiceBrowser.startBrowsingForPeers()
    }
    
    deinit {
    }
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.peerId, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }()
    
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

}

extension RemoteBackendServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "Service Browser did not start browsing for peers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "Service Browser found peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "Service Browser lost peer: \(peerID.displayName)")
    }
    
}

extension RemoteBackendServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("RECIEVING RESOURCE")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("RECIEVED RESOURCE")
        print(localURL)
        DispatchQueue.main.async {
            self.delegate!.sendDesktopImage(for: peerID, url: localURL!)
        }
    }
    
}




protocol RemoteBackendServiceManagerDelegate {
    func sendDesktopImage(for peer: MCPeerID, url: URL)
    
}
