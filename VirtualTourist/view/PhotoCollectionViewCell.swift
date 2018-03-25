//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Swifta on 3/23/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var image: UIImageView!
    func updateUI(photoRes: [String: AnyObject], pin: PinEntity) {
        let imageUrlString = photoRes[Constants.FlickrResponseKeys.MediumURL] as! String
        let url = URL(string: imageUrlString)
        let photoTitle = photoRes[Constants.FlickrResponseKeys.Title] as? String
        /* GUARD: Does our photo have a key for 'url_m'? */
        // if an image exists at the url, set the image and title
        DispatchQueue.main.async {
            do {
                let imageData = try Data(contentsOf: url!)
                DispatchQueue.main.async {
                    self.image.image = UIImage(data: imageData)
                    let photo = PhotoEntity(context: PersistenceService.context)
                    photo.image = imageData as NSData
                    photo.title = photoTitle
                    photo.medialUrl = imageUrlString
                    photo.pin = pin
                    PersistenceService.saveContext()
                    
                }
            }
            catch {}
        }
    }
}
