//
//  ServerSelectionViewController.swift
//  MacmoteRemote
//
//  Created by Griffin Prechter on 4/20/18.
//  Copyright © 2018 Griffin Prechter. All rights reserved.
//

import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass
import MultipeerConnectivity

class ServerSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var peerTable: UITableView!
    var isDragging = false
    var remoteService : RemoteServiceManager?
    var timer = Timer()
    var currentDevice : MCPeerID?
    
    var backgroundImages : [String:URL] = [:]
    
    var backendManager = RemoteBackendServiceManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backendManager.delegate = self
        peerTable.delegate = self
        peerTable.dataSource = self
        self.remoteService = RemoteServiceManager()
        remoteService!.delegate = self
        scheduledTimerWithTimeInterval()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "presentMouse" {
                if let dest = segue.destination as? ViewController {
                    dest.remoteService = self.remoteService!
                    dest.server = self.currentDevice!
                    dest.connectedDeviceName = self.currentDevice!.displayName
                    dest.backgroundImages = self.backgroundImages
                    self.remoteService = nil
                }
            }
        }
    }
    
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    
    @objc func updateCounting(){
        self.peerTable.reloadData()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("LOADING TABLE VIEW")
        if let service = remoteService {
            return service.accessiblePeers.count
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("loading table view")
        let peerID = self.remoteService!.accessiblePeers[indexPath.row]
        if (self.backgroundImages.keys.contains(peerID.displayName)) {
            print("Loading image")
            let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath) as! ServerCell
            cell.peerID = peerID
            cell.serverNameLabel.text = cell.peerID.displayName
            cell.serverNameLabel.textColor = .white
            cell.desktopImage.image = UIImage(data: try! Data(contentsOf: self.backgroundImages[peerID.displayName]!))
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath) as! ServerCell
            cell.peerID = peerID
            cell.serverNameLabel.text = cell.peerID.displayName
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.remoteService!.connectToPeer((tableView.cellForRow(at: indexPath) as! ServerCell).peerID)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ServerSelectionViewController : RemoteServiceManagerDelegate {
    
    
    func pushCode(manager: RemoteServiceManager, codeRecieved: String) {
        OperationQueue.main.addOperation {
            
        }
    }
    
    func connectedDevicesChanged(manager: RemoteServiceManager, connectedDevices: [String]) {
    }
    
    func connectedToPeer(peer: MCPeerID) {
        if self.remoteService!.openStream(with: peer) {
            self.currentDevice = peer
            performSegue(withIdentifier: "presentMouse", sender: self)
        }
    }
    
    func disconnectedFromPeer(peer: MCPeerID) {
    }
    
    func recievedResource(from: MCPeerID, url: URL?) {
    }
    
}

extension ServerSelectionViewController : RemoteBackendServiceManagerDelegate {
    func sendDesktopImage(for peer: MCPeerID, url: URL) {
        self.backgroundImages[peer.displayName] = url
        NSLog("%@", "Recieved resource from: \(peer.displayName)")
    }
}



