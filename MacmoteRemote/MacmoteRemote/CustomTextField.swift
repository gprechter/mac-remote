//
//  CustomTextField.swift
//  MacmoteRemote
//
//  Created by Griffin Prechter on 4/19/18.
//  Copyright © 2018 Griffin Prechter. All rights reserved.
//

import Foundation
import UIKit

class CustomTextField: UITextField {
    var keyDelegate : KeyboardDelegate?
    override func deleteBackward() {
        super.deleteBackward()
        print("BACKWARDS")
        self.keyDelegate?.keyPress(string: "backwards")
    }
    
    override func endEditing(_ force: Bool) -> Bool {
        return false
    }
    
    override func resignFirstResponder() -> Bool {
        return false
    }
    
    func dismissKeyboard() -> Bool {
        return super.resignFirstResponder()
    }
    
}

protocol KeyboardDelegate {
    func keyPress(string: String)
}
