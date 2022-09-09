//
//  MapViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 30.08.2022.
//

import UIKit
import MapKit

class MapViewController: UIViewController, childrenMessageVC, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var model: ModelSealMessage!
    var currentLocation: MKCoordinateRegion?

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var onOffSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    
    private var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
            self.locationManager.delegate = self
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateNotification(withNotification:)),
            name: NSNotification.Name(rawValue: "model updated"),
            object: nil)
        
        setupUI()
        updateUI()
    }
    
    @IBAction func onOffSwitchChanged() {
        
        if onOffSwitch.isOn, !checkLocationEnable() {
            onOffSwitch.isOn = false
        }
        
        if onOffSwitch.isOn {
            if let region  = currentLocation {
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
            currentLocation = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: model.location.latitude,
                    longitude: model.location.longitude),
                latitudinalMeters: 300,
                longitudinalMeters: 300)
            mapView.setRegion(currentLocation!, animated: false)
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

    private func showAlert(with title: String) {
        
        let alert = UIAlertController(title: title, message: "Вы можете изменить разрешение в настройках", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion:nil)
    }
    
    private func updateAddresDescription() {
        
        guard let region = currentLocation else {return}
        let location = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        
        DispatchQueue.global().async { // не уверен что так надо, но при тестировании и проблем с сетью тормозил пользовтальский интерфейс
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                guard error == nil else {
                    return
                }
                
                if let firstPlacemark = placemarks?.first {
                    let description =  "\(firstPlacemark.locality ?? "") \(firstPlacemark.thoroughfare ?? "") \(firstPlacemark.subThoroughfare ?? "")"
                    
                    self.model.location = Location(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
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
        
        currentLocation = mapView.region
        updateAddresDescription()
    }
}

// MARK: Core Location
extension MapViewController {
    
    private func checkLocationEnable() -> Bool {
        if CLLocationManager.locationServicesEnabled(), CLLocationManager.significantLocationChangeMonitoringAvailable() {
            setupLocationManager()
            return true
        } else {
            showAlert(with: "Служба геолокации недоступна")
            return false
        }
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last?.coordinate {
            if currentLocation == nil {
                currentLocation = MKCoordinateRegion(center: location, latitudinalMeters: 300, longitudinalMeters: 300)
                mapView.setRegion(currentLocation!, animated: true)
            }
        }
        locationManager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .denied:
            self.showAlert(with: "Вы запретили использование местоположения!")
        case .authorizedAlways:
            self.locationManager.startUpdatingLocation()
        case .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
}

