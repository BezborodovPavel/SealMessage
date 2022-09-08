//
//  MapViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 30.08.2022.
//

import UIKit
import MapKit

class MapViewController: UIViewController, childrenMessageVC, CLLocationManagerDelegate {
    
    var model: ModelSealMessage!
    var locationManager: CLLocationManager!

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var onOffSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
//        }
        update()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateNotification(withNotification:)),
            name: NSNotification.Name(rawValue: "model updated"),
            object: nil)
        // Do any additional setup after loading the view.
    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        checkLocationEnable()
//    }
    
    @IBAction func onOffSwitchChanged() {
        
        if onOffSwitch.isOn, !checkLocationEnable() {
            onOffSwitch.isOn = false
        }
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
    
    func checkLocationEnable() -> Bool {
        if CLLocationManager.locationServicesEnabled(), CLLocationManager.significantLocationChangeMonitoringAvailable() {
            setupLocationManager()
            return true
        } else {
            showAlert(with: "Служба геолокации недоступна")
            return false
        }
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    }
    
    private func showAlert(with title: String) {
        
        let alert = UIAlertController(title: title, message: "Вы можете включить её в настройках", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion:nil)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last?.coordinate {
            let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.5))
            mapView.setRegion(region, animated: true)
        }
        locationManager.stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        DispatchQueue.main.async {

            switch manager.authorizationStatus {
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
            case .restricted:
                break
            case .denied:
                self.showAlert(with: "Вы запретили использование местоположения!")
            case .authorizedAlways:
                self.mapView.showsUserLocation = true
                self.locationManager.startUpdatingLocation()
            case .authorizedWhenInUse:
                self.mapView.showsUserLocation = true
                self.locationManager.startUpdatingLocation()
            @unknown default:
                break
            }
//        }
    }
}

