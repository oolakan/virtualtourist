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
class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource{
    @IBOutlet weak var flowLayoutMeme: UICollectionViewFlowLayout!
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    var apiClient: ApiClient!
    var photos: [PhotoEntity]!
    
    var pin: PinEntity!
    
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
        return self.photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photocell", for: indexPath as IndexPath) as? PhotoCollectionViewCell else {
            return UICollectionViewCell()
        }
        let photo = self.photos[indexPath.row].image
        cell.image.image = UIImage(data: photo! as Data)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected")
        self.photos.remove(at: indexPath.row)
        self.photoCollectionView.deleteItems(at: [indexPath])
        let photoToDelete = self.photos[indexPath.row]
        PersistenceService.context.delete(photoToDelete)
        PersistenceService.saveContext()
        photoCollectionView.reloadData()
    }

    fileprivate func configureCellSize() {
        // Do any additional setup after loading the view.
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        flowLayoutMeme.minimumInteritemSpacing = space
        flowLayoutMeme.minimumLineSpacing = space
        flowLayoutMeme.itemSize = CGSize(width: dimension, height: dimension)
    }

    fileprivate func getImages() {
        self.displayOverlay()
        apiClient = ApiClient()
        apiClient.getFlickrImages(pin.latitude, pin.longitude, completionHandler: {result in
            switch result {
            case .success(let res):
                print(res)
                 self.dismiss(animated: true, completion: nil)
                performUIUpdatesOnMain {
                    if (res.count > 0) {
                        print("Images available")
                        for _res in res {
                            let photoDictionary = _res as [String: AnyObject]
                            let photoTitle = photoDictionary[Constants.FlickrResponseKeys.Title] as? String
                            /* GUARD: Does our photo have a key for 'url_m'? */
                            if let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String {
                                // if an image exists at the url, set the image and title
                                let imageURL = URL(string: imageUrlString)
                                if let imageData = try? Data(contentsOf: imageURL!) {
                                    let photo = PhotoEntity(context: PersistenceService.context)
                                    photo.image = imageData as NSData
                                    photo.title = photoTitle
                                    photo.medialUrl = imageUrlString
                                    photo.pin = self.pin
                                    PersistenceService.saveContext()
                                }
                            }
                        }
                       
                        self.photoCollectionView.reloadData()
                    } else {
                       
                        print("Images not available")
                    }
                }
            case .failure(let err):
                print(err)
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func getNewCollection(_ sender: Any) {
        let photos = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: "Photo"))
        do {
            try PersistenceService.context.execute(photos)
            self.photoCollectionView.reloadData()
        }
        catch {
            print(error)
        }
        if (InternetConnection.isConnectedToNetwork()){
            getImages()
        }
        else {
            showAlert(title: "Message", message: "No internet connection")
        }
    }
    
    func displayOverlay()  {
        let alert = UIAlertController(title: nil, message: "Downloading...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    func showAlert(title: String, message: String)  {
        let actionSheetController = UIAlertController (title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        actionSheetController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
}
