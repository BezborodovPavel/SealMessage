//
//  MapViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 30.08.2022.
//

import UIKit
import MapKit

protocol childrenMapMessageVC: childrenMessageVC {
    var modelLocation: ModelLocation! {get set}
}

class MapViewController: UIViewController, childrenMapMessageVC, CLLocationManagerDelegate, MKMapViewDelegate {
   
    var modelLocation: ModelLocation!
    var model: ModelSealMessage!

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var onOffSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateNotification(withNotification:)),
            name: NSNotification.Name(rawValue: "model updated"),
            object: nil)
        
        setupUI()
        updateUI()
    }
    
    @IBAction func onOffSwitchChanged() {
        
        if onOffSwitch.isOn, !modelLocation.enabled {
            onOffSwitch.isOn = false
        }
        
        if onOffSwitch.isOn {
            if let region  = modelLocation.region {
                mapView.setRegion(region, animated: true)
                updateAddresDescription()
            }
            
            mapView.delegate = self
        } else {
            mapView.delegate = nil
            model.location = Location()
            sendNotification()
        }
        updateUI()
    }
 
    @objc private func updateNotification(withNotification notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let modelFromNotification = userInfo["model"] as? ModelSealMessage
            else { fatalError() }
        
        model = modelFromNotification
        updateUI()
    }
    
    private func setupUI() {
    
        if !model.location.isEmpty() {
            modelLocation.currentLocation = CLLocationCoordinate2D(
                latitude: model.location.latitude,
                longitude: model.location.longitude)
            
            guard let region = modelLocation.region else {return}
            mapView.setRegion(region, animated: false)
        }
    }
    
    private func updateUI() {
        
        onOffSwitch.isEnabled = !model.didSend
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

    private func updateAddresDescription() {
        
        guard let location = modelLocation.currentLocation else {return}
        let newLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        DispatchQueue.global().async { // не уверен что так надо, но при тестировании и проблем с сетью тормозил пользовтальский интерфейс
            CLGeocoder().reverseGeocodeLocation(newLocation) { (placemarks, error) in
                guard error == nil else {
                    return
                }
                
                if let firstPlacemark = placemarks?.first {
                    let description =  "\(firstPlacemark.locality ?? "") \(firstPlacemark.thoroughfare ?? "") \(firstPlacemark.subThoroughfare ?? "")"
                    
                    self.model.location = Location(
                        latitude: newLocation.coordinate.latitude,
                        longitude: newLocation.coordinate.longitude,
                        description: description)

                    self.sendNotification()
                }
            }
        }
    }

}

// MARK: MapKit
extension MapViewController {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        modelLocation.currentLocation = CLLocationCoordinate2D(
            latitude: mapView.region.center.latitude,
            longitude: mapView.region.center.longitude)
        
        updateAddresDescription()
    }
}

