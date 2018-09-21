//
//  RemoteServiceManager.swift
//  MacMote Client
//
//  Created by Griffin Prechter on 4/9/18.
//  Copyright © 2018 Griffin Prechter. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class RemoteServiceManager: NSObject, StreamDelegate  {
    
    private let SERVICE_TYPE = "macmote"
    private let peerId = MCPeerID(displayName: UIDevice.current.name)
    
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    var outputStream : OutputStream?
    
    var accessiblePeers : [MCPeerID] = []
    
    var delegate : RemoteServiceManagerDelegate?
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: peerId, discoveryInfo: ["deviceType": "REMOTE"], serviceType: SERVICE_TYPE)
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
    }
    
    deinit {
        outputStream?.close()
        self.serviceAdvertiser.stopAdvertisingPeer()
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
    
    func stream(_ message: String) {
        if let output = self.outputStream {
            let str = message + "_" + String(repeating: " ", count: 16 - message.count - 1)
            print(str.count)
            output.write(Array(str.data(using: .utf8)!), maxLength: str.count)
            NSLog("%@", "Streaming message: \(str)")
        }
    }
    
    func openStream(with peer: MCPeerID) -> Bool {
        do {
            try self.outputStream = self.session.startStream(withName: "macmote", toPeer: peer)
            if let stream = self.outputStream {
                stream.delegate = self
                stream.schedule(in: RunLoop.main, forMode:RunLoopMode.defaultRunLoopMode)
                stream.open()
                NSLog("%@", "Stream Successfully opened with peer: \(peer)")
                return true
            }
        } catch {
            NSLog("%@", "Stream failed to open with peer: \(peer)")
        }
        return false
    }
}

extension RemoteServiceManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        if let context = context, let deviceContext = String(data: context, encoding: .utf8), deviceContext == "SERVER" {
            invitationHandler(true, self.session)
        }
    }
    
}

extension RemoteServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            NSLog("%@", "Peer: \(self.peerId) is connected to the peer: \(peerID.displayName)")
            DispatchQueue.main.async {
                self.delegate?.connectedToPeer(peer: peerID)
            }
        case MCSessionState.connecting:
            NSLog("%@", "Peer: \(self.peerId) is connecting to the peer: \(peerID.displayName)")

        case MCSessionState.notConnected:
            DispatchQueue.main.async {
                NSLog("%@", "Peer: \(self.peerId) is disconnected from the peer: \(peerID.displayName)")
                self.delegate?.disconnectedFromPeer(peer: peerID)
                if let stream = self.outputStream {
                    stream.close()
                    NSLog("%@", "Stream with peer: \(peerID.displayName) was disconnected")
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        DispatchQueue.main.async {
            self.delegate?.recievedResource(for: resourceName, from: peerID, at: localURL)
        }
    }
    
}

protocol RemoteServiceManagerDelegate {
    
    func receivedData(_ data: Data)
    func connectedToPeer(peer: MCPeerID)
    func disconnectedFromPeer(peer: MCPeerID)
    func recievedResource(for resource: String, from peer: MCPeerID, at url: URL?)
}
