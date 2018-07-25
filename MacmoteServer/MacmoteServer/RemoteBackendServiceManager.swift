
//  ColorServiceManager.swift
//  ConnectedColors
//
//  Created by Griffin Prechter on 4/6/18.
//  Copyright © 2018 Example. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class RemoteBackendServiceManager : NSObject {
    
    private let SERVICE_TYPE = "macmote-backend"
    private let myPeerId = MCPeerID(displayName: Host.current().localizedName ?? "" + "-backend")
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    
    var delegate : RemoteBackendServiceManagerDelegate?
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: ["deviceType": "SERVER"], serviceType: SERVICE_TYPE)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
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

extension RemoteBackendServiceManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
    
}

extension RemoteBackendServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state)")
        switch state {
        case .connected:
            self.session.sendResource(at: NSWorkspace.shared.desktopImageURL(for: NSScreen.main!)!, withName: "desktopImage", toPeer: peerID, withCompletionHandler: nil)
        case .connecting:
            print("Connecting")
        case .notConnected:
            print("Disconnected")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {

    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
}

protocol RemoteBackendServiceManagerDelegate {

}
