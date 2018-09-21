//
//  Remote.swift
//  MacmoteRemote
//
//  Created by Griffin Prechter on 9/20/18.
//  Copyright © 2018 Griffin Prechter. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Remote {

    var availableDevices = [Device]()
    var device: Device?
    var remoteService = RemoteServiceManager()
    var delegate: RemoteDelegate?
    init() {
        remoteService.delegate = self
    }
    
    func service(remote: Device) {
        if let currentDevice = device {
            if let stream = remoteService.outputStream {
                stream.close()
                NSLog("%@", "Stream with peer: \(currentDevice.peerID!.displayName) was disconnected")
            }
        }
        if remoteService.openStream(with: remote.peerID!) {
            device = remote
            delegate?.serviceBegan(with: device!)
        }
    }
    
    func send(string: String) {
        if remoteService.outputStream?.streamStatus == .open {
            remoteService.stream(string)
        }
    }
    
}

extension Remote: RemoteServiceManagerDelegate {
    func receivedData(_ data: Data) {
        
    }
    
    func connectedToPeer(peer: MCPeerID) {
        if !availableDevices.contains(where: {$0.peerID == peer}) {
            availableDevices.append(Device(withID: peer))
            delegate?.stateUpdated()
        }
    }
    
    func disconnectedFromPeer(peer: MCPeerID) {
        if availableDevices.contains(where: {$0.peerID == peer}) {
            print(availableDevices)
            availableDevices.removeAll(where: {$0.peerID == peer})
            print(availableDevices)
            delegate?.stateUpdated()
        }
    }
    
    func recievedResource(for resource: String, from peer: MCPeerID, at url: URL?) {
        if resource == "backgroundImage" {
            if availableDevices.contains(where: {$0.peerID == peer}), let url = url {
                availableDevices.first(where: {$0.peerID == peer})?.setImage(from: url)
                delegate?.stateUpdated()
            }
        }
    }
}

protocol RemoteDelegate {
    func serviceBegan(with device: Device)
    func stateUpdated()
    func recieved(data: Data)
}

class Device {
    var peerID: MCPeerID?
    var image: UIImage?
    
    init(withID peerID: MCPeerID) {
        self.peerID = peerID
    }
    
    func setImage(from url: URL) {
        self.image = UIImage(data: try! Data(contentsOf: url))
    }
}
