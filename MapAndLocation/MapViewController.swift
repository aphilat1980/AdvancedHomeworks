//
//  ViewController.swift
//  MapAndLocation
//
//  Created by Александр Филатов on 26.08.2023.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    
    let mapView = MKMapView()
    let locationManager = CLLocationManager()
    var userPins: [MKPointAnnotation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        comfigureMapView()
        checkUserLocationPermissions()
    
    }
    
    func setupView () {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        navigationController?.navigationBar.backgroundColor = .systemGray4
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(systemName:"pin"), style: .done, target: self, action: #selector(addPin(_:))), UIBarButtonItem(image: UIImage(systemName:"location.north.line.fill"), style: .done, target: self, action: #selector(addRoute(_:))), UIBarButtonItem(image: UIImage(systemName:"delete.left"), style: .done, target: self, action: #selector(deleteAllPins(_:)))]
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        
        ])
    }
    
    func comfigureMapView () {
        //mapView.mapType = .standard
        
        mapView.showsCompass = true
        
        mapView.preferredConfiguration.elevationStyle = .realistic
        mapView.showsScale = true
        
        
        guard let coordinates = locationManager.location?.coordinate else {return}
        mapView.setCenter(coordinates, animated: false)
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(region, animated: false)
    }
    
    
    func checkUserLocationPermissions() {
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            mapView.showsUserLocation = true
            locationManager.delegate = self
            locationManager.desiredAccuracy = 100
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print ("please on your location")
        @unknown default:
            fatalError("unuse status")
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else {return}
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(region, animated: true)
        }
    
    
    @objc func addPin(_: Any) {
        
        let alert = UIAlertController (title: "Введите координаты точки", message: nil, preferredStyle: .alert)
        alert.addTextField()
        alert.addTextField()
        alert.textFields![0].placeholder = "широта"
        alert.textFields![1].placeholder = "долгота"
        let action = UIAlertAction(title: "Ок", style: .default, handler: {_ in
            
            let stringLat = alert.textFields![0].text!
            let stringLon = alert.textFields![1].text!
            
            if let lat = Double(stringLat), let lon = Double(stringLon) {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                self.userPins.append(annotation)
                annotation.title = "\(self.userPins.count)"
                self.mapView.addAnnotation(annotation)
                
                let region = MKCoordinateRegion(center: self.locationManager.location!.coordinate, latitudinalMeters: (self.locationManager.location?.coordinate.distanceTo(coordinate: annotation.coordinate))!*2, longitudinalMeters: (self.locationManager.location?.coordinate.distanceTo(coordinate: annotation.coordinate))!*2)
                
                self.mapView.setRegion(region, animated: true)
                
            }
            else {
                print("cannot convert textfields data to coordinates")
            }
        })
        alert.addAction(action)
        self.present(alert, animated: true)
        
    }
    
    
    @objc func deleteAllPins(_: Any) {
        
        for annotation in userPins {
            mapView.removeAnnotation(annotation)
        }
        mapView.removeOverlays(mapView.overlays)
        self.userPins = []
        let region = MKCoordinateRegion(center: locationManager.location!.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(region, animated: true)
    }
    
    
    @objc func addRoute (_: Any) {
        
        if userPins.count == 0 {
            print ("There is no pins")
            return}
        
        let alert = UIAlertController (title: "Введите номер точки пользователя, до которой хотите построить маршрут", message: nil, preferredStyle: .alert)
        alert.addTextField()
        alert.textFields![0].placeholder = "введите число до \(userPins.count)"
    
        let action = UIAlertAction(title: "Ок", style: .default, handler: {_ in
            
            let stringIndex = alert.textFields![0].text!
            
            if let index = Int(stringIndex) {
                
                if index > self.userPins.count {
                    print ("index out of range, try again")
                    return}
                let directionRequest = MKDirections.Request()
                let sourcePlacemark = MKPlacemark(coordinate: self.locationManager.location!.coordinate)
                directionRequest.source = MKMapItem(placemark: sourcePlacemark)
                let destinationPlacemark = MKPlacemark(coordinate:
                                                        self.userPins[index-1].coordinate)
                directionRequest.transportType = .automobile
                directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
                let directions = MKDirections(request: directionRequest)
                directions.calculate { responce, error in
                    
                    guard let route = responce?.routes.first else {return}
                    self.mapView.delegate = self
                    self.mapView.addOverlay(route.polyline)
                }
            }
            else {
                print("mistake")
            }
        })
        alert.addAction(action)
        self.present(alert, animated: true)
    }


    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .red
        renderer.lineWidth = 3
        return renderer
    }
}

extension CLLocationCoordinate2D {
     func distanceTo(coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
            let thisLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
            let otherLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
         return thisLocation.distance(from: otherLocation)
      }
}
