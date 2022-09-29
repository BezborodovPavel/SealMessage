//
//  ViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 02.09.2022.q
//

import UIKit

extension UIViewController {

    func removeAllChildViewControllers() {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }

}
