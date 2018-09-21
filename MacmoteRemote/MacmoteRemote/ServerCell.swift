//
//  ServerCell.swift
//  MacmoteRemote
//
//  Created by Griffin Prechter on 4/21/18.
//  Copyright © 2018 Griffin Prechter. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ServerCell : UITableViewCell {
    
    @IBOutlet weak var serverNameLabel: UILabel!
    
    @IBOutlet weak var desktopImage: UIImageView!
    var device : Device!
}
