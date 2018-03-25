//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Swifta on 3/22/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionBtn: UIButton!
    var apiClient: ApiClient!
    var photos: [PhotoEntity]!
    var photo: PhotoEntity!
    
    var pin: PinEntity!
    var photoResults: [[String: AnyObject]] = [[String: AnyObject]]()
    var resultCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        let locationCordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = locationCordinate
        self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(locationCordinate, 1500, 1500), animated: true)
        self.mapView.addAnnotation(annotation)
        let fetchRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let photos = try! PersistenceService.context.fetch(fetchRequest)
        self.photos = photos
        self.resultCount = self.photos.count
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (self.photos.count < 1) {
            print("count is\(self.photos.count)")
            if (InternetConnection.isConnectedToNetwork()){
                getImages()
            }
            else {
                showAlert(title: "Message", message: "No internet connection")
            }
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoResults.count > 0 ? self.photoResults.count : self.photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photocell", for: indexPath as IndexPath) as? PhotoCollectionViewCell else {
            return UICollectionViewCell()
        }
        if self.photoResults.count > 0 {
            cell.updateUI(photoRes: self.photoResults[indexPath.row], pin: pin)
        }
        else {
            cell.image.image = UIImage(data: self.photos[indexPath.row].image! as Data)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
                if self.photoResults.count > 0 {
                    self.photoResults.remove(at: indexPath.row)
                     photoCollectionView.reloadData()
                }
                else {
                    self.photos.remove(at: indexPath.row)
                    self.resultCount = self.photos.count
                    self.photoCollectionView.deleteItems(at: [indexPath])
                    let photoToDelete = self.photos[indexPath.row]
                    PersistenceService.context.delete(photoToDelete)
                    PersistenceService.saveContext()
                    photoCollectionView.reloadData()
         }
    }
    
    fileprivate func configureCellSize() {
        // Do any additional setup after loading the view.
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    fileprivate func getImages() {
        performUIUpdatesOnMain {
            self.collectionBtn.isEnabled = false
        }
        apiClient = ApiClient()
        apiClient.getFlickrImages(pin.latitude, pin.longitude, completionHandler: {result in
            switch result {
            case .success(let res):
                print(res)
                if res.count > 0 {
                    for _res in res {
                        self.photoResults.append(_res)
                    }
                    self.resultCount = self.photoResults.count
                    performUIUpdatesOnMain {
                        self.collectionBtn.isEnabled = true
                        self.photoCollectionView.reloadData()
                    }
                    print("Images available")
                }
                    
                else {
                    print("Images not available")
                }
            case .failure(let err):
                print(err)
                performUIUpdatesOnMain {
                    self.collectionBtn.isEnabled = true
                }
            }
        })
    }
    
    @IBAction func getNewCollection(_ sender: Any) {
        let fetchRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let photos = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        do {
            try PersistenceService.context.execute(photos)
        }
        catch {
            print(error)
        }
        self.photoResults.removeAll()//remove data from array if available
        if (InternetConnection.isConnectedToNetwork()){
            getImages()
        }
        else {
            showAlert(title: "Message", message: "No internet connection")
        }
    }
    
    func showAlert(title: String, message: String)  {
        let actionSheetController = UIAlertController (title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        actionSheetController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
}

