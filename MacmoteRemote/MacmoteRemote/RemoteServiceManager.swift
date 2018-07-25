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
    
    enum PeerState: Int {
        case notConnected = 0
        case connecting = 1
        case connected = 2
    }
    
    private let SERVICE_TYPE = "macmote"
    private let peerId = MCPeerID(displayName: UIDevice.current.name)
    
    private let serviceBrowser : MCNearbyServiceBrowser
    var outputStream : OutputStream?
    
    var accessiblePeers : [MCPeerID] = []
    
    var delegate : RemoteServiceManagerDelegate?
    
    override init() {
        self.serviceBrowser = MCNearbyServiceBrowser(peer: peerId, serviceType: SERVICE_TYPE)
        super.init()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        outputStream?.close()
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
            let str = message + String(repeating: " ", count: 16 - message.count)
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
    
    func connectToPeer(_ peer: MCPeerID) -> Bool {
        if self.accessiblePeers.contains(peer) {
            self.serviceBrowser.invitePeer(peer, to: self.session, withContext: nil, timeout: 10)
            print("Inviting peer")
            return true
        } else {
            print("Cannot connect to peer")
        }
        return false
    }
}

extension RemoteServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "Service Browser did not start browsing for peers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "Service Browser found peer: \(peerID.displayName)")
        if info!["deviceType"] == "SERVER" {
            self.accessiblePeers.append(peerID)
        }
        //browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
        //NSLog("%@", "Service Browser invited peer: \(peerID.displayName) to its session")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "Service Browser lost peer: \(peerID.displayName)")
        if let index = self.accessiblePeers.index(of: peerID) {
            self.accessiblePeers.remove(at: index)
            self.delegate!.disconnectedFromPeer(peer: peerID)
        }
    }
    
}

extension RemoteServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state.rawValue == PeerState.connected.rawValue {
            NSLog("%@", "Peer: \(peerID.displayName) connected to the session")
            DispatchQueue.main.async {
                self.delegate?.connectedToPeer(peer: peerID)
            }
        } else if state.rawValue == PeerState.connecting.rawValue {
            NSLog("%@", "Peer: \(peerID.displayName) is connecting to the session")
        } else {
            NSLog("%@", "Peer: \(peerID.displayName) disconnected from the session")
            self.delegate?.disconnectedFromPeer(peer: peerID)
            if let stream = self.outputStream {
                stream.close()
                NSLog("%@", "Stream with peer: \(peerID.displayName) was disconnected")
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
    }
    
}

protocol RemoteServiceManagerDelegate {
    
    func pushCode(manager : RemoteServiceManager, codeRecieved: String)
    func connectedDevicesChanged(manager : RemoteServiceManager, connectedDevices: [String])
    
    func connectedToPeer(peer: MCPeerID)
    func disconnectedFromPeer(peer: MCPeerID)
    
    func recievedResource(from:MCPeerID, url: URL?)
}
