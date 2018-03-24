//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Swifta on 3/22/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class TravelLocationMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    var latitude: Double!
    var longitude: Double!
    let annotation = MKPointAnnotation()
    var appDelegate: AppDelegate!
    var locationObjectId: String!
  
    var context : NSManagedObjectContext!
    
    var apiClient: ApiClient!
    var pins = [PinEntity]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
        loadPin()
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(action(gestureRecognizer:)))
        mapView.addGestureRecognizer(longGesture)
    }
    
    func loadPin() {
        let fetchRequest: NSFetchRequest<PinEntity> = PinEntity.fetchRequest()
        let pins = try! PersistenceService.context.fetch(fetchRequest)
        self.pins = pins
        if (self.pins.count > 0) {
            performUIUpdatesOnMain {
                for pin in self.pins {
                    let locationCordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = locationCordinate
                    self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(locationCordinate, 1500, 1500), animated: true)
                    let _pin = PinAnnotation(pin: pin, coordinate: annotation.coordinate)
                    self.mapView.addAnnotation(_pin)
                    print(annotation.coordinate)
                }
            }
        }
    }
    
    @objc func action(gestureRecognizer:UIGestureRecognizer){
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        latitude = annotation.coordinate.latitude
        longitude = annotation.coordinate.longitude
        let pin = PinEntity(context: PersistenceService.context)
        pin.latitude = latitude
        pin.longitude = longitude
        PersistenceService.saveContext()
        let _pin = PinAnnotation(pin: pin, coordinate: annotation.coordinate)
        self.mapView.addAnnotation(_pin)
        getImages(pin)
    }
    //start downloading images
    fileprivate func getImages(_ pin: PinEntity) {
        apiClient = ApiClient()
        apiClient.getFlickrImages(pin.latitude, pin.longitude, completionHandler: {result in
            switch result {
            case .success(let res):
                print(res)
                if (res.count > 0) {
                    print("Images available")
                    for _res in res {
                        let photoDictionary = _res as [String: AnyObject]
                        let photoTitle = photoDictionary[Constants.FlickrResponseKeys.Title] as? String
                        if let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String {
                            let imageURL = URL(string: imageUrlString)
                            if let imageData = try? Data(contentsOf: imageURL!) {
                                let photo = PhotoEntity(context: PersistenceService.context)
                                photo.image = imageData as NSData
                                photo.title = photoTitle
                                photo.medialUrl = imageUrlString
                                photo.pin = pin
                                performUIUpdatesOnMain {
                                    PersistenceService.saveContext()
                                }
                            }
                        }
                    }
                } else {
                    print("Images not available")
                }
                
            case .failure(let err):
                print(err)
            }
        })
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
            let annotation = view.annotation as? PinAnnotation
            var controller: PhotoAlbumViewController!
            controller = self.storyboard?.instantiateViewController(withIdentifier: "photo") as! PhotoAlbumViewController
            controller.pin = annotation?.pin
            present(controller, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(center, 1500, 1500), animated: true)
        self.locationManager.stopUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errors " + error.localizedDescription)
    }
    
    fileprivate func savePin(_ latitude: Double, _ longitude: Double) {
        let pin = PinEntity(context: PersistenceService.context)
        pin.latitude = latitude
        pin.longitude = longitude
        PersistenceService.saveContext()
        let _pin = PinAnnotation(pin: pin, coordinate: annotation.coordinate)
        self.mapView.addAnnotation(_pin)
    }
}
