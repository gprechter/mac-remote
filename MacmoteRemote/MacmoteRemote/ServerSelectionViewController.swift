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
    
    @IBOutlet weak var deviceTable: UITableView!
    var remote = Remote()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceTable.delegate = self
        deviceTable.dataSource = self
        remote.delegate = self
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "presentMouse" {
                if let dest = segue.destination as? ViewController {
                    dest.remote = self.remote
                    remote.delegate = dest
                }
            }
        }
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return remote.availableDevices.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = self.remote.availableDevices[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath) as! ServerCell
        cell.serverNameLabel.text = device.peerID?.displayName
        if let image = device.image {
            cell.serverNameLabel.textColor = .white
            cell.desktopImage.image = image
        }
        cell.device = device
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.remote.service(remote: (tableView.cellForRow(at: indexPath) as! ServerCell).device)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ServerSelectionViewController : RemoteDelegate {
    func serviceBegan(with device: Device) {
        performSegue(withIdentifier: "presentMouse", sender: self)
    }
    
    func stateUpdated() {
        self.deviceTable.reloadData()
    }
    
    func recieved(data: Data) {
        
    }
}



