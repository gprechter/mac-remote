//
//  RemoteController.swift
//  MacmoteServer
//
//  Created by Griffin Prechter on 9/21/18.
//  Copyright © 2018 Griffin Prechter. All rights reserved.
//

import Foundation

class RemoteController {
    private let remoteService = RemoteServiceManager()
    
    init() {
        remoteService.delegate = self
    }
}

extension RemoteController: RemoteServiceManagerDelegate {
    func pushCode(manager: RemoteServiceManager, code: String) {
        
    }
    
    func connectedDevicesChanged(manager: RemoteServiceManager, connectedDevices: [String]) {
        
    }
    
    
}

protocol RemoteControllerDelegate {
    func stateChanged()
}
