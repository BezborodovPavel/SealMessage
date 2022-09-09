//
//  ModelLocation.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 09.09.2022.
//

import Foundation
import CoreLocation
import MapKit

class ModelLocation {
    var currentLocation: CLLocationCoordinate2D?
    var enabled = false
    var locationInTargetRegion = false
    
    var region: MKCoordinateRegion? {
        if let location = currentLocation{
        return MKCoordinateRegion(center: location, latitudinalMeters: 300, longitudinalMeters: 300)
        } else {
            return nil
        }
    }
}
