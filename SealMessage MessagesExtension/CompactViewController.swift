//
//  CompactViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 02.09.2022.
//

import UIKit

class CompactViewController: UIViewController {
    
    var delegate: MessagesViewControllerDelegate?
    @IBOutlet weak var messsageTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super .touchesBegan(touches, with: event)
        delegate?.expandedVC()
    }

}
