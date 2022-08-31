//
//  MapViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 30.08.2022.
//

import UIKit
import MapKit

class MapViewController: UIViewController, childrenMessageVC {
    
    var model: ModelSealMessage!

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var onOffSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        update()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateNotification(withNotification:)),
            name: NSNotification.Name(rawValue: "model updated"),
            object: nil)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onOffSwitchChanged() {
        update()
    }
 
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @objc private func updateNotification(withNotification notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let modelFromNotification = userInfo["model"] as? ModelSealMessage
            else { fatalError() }
        
        model = modelFromNotification
        update()
    }
    
    private func update() {
        mapView.alpha = onOffSwitch.isOn ? 1 : 0.5
        mapView.isUserInteractionEnabled = onOffSwitch.isOn
        titleLabel.alpha = onOffSwitch.isOn ? 1 : 0.5
    }

    private func sendNotification() {
        
        NotificationCenter.default.post(
            name: NSNotification.Name("main view need updated"),
            object: self,
            userInfo: ["model": model!]
        )
    }
}
