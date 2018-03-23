//
//  ApiClient.swift
//  VirtualTourist
//
//  Created by Swifta on 3/22/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
class ApiClient {
    
    enum ConnectionArrayResult {
        case success([[String: AnyObject]])
        case failure(Error)
    }
    
    enum ConnectionResult {
        case success([String: AnyObject])
        case failure(Error)
    }
    
    func getFlickrImages(_ latitudeValue: Double, _ longitudeValue: Double, completionHandler: @escaping (_ serverResponse: ConnectionArrayResult) -> Void ) {
       
        if isValidRange(locationValue: latitudeValue, forRange: Constants.Flickr.SearchLatRange) && isValidRange(locationValue: longitudeValue, forRange: Constants.Flickr.SearchLonRange) {
                let methodParameters = [
                    Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
                    Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
                    Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude: latitudeValue, longitude: longitudeValue),
                    Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
                    Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
                    Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
                    Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
                ]
            displayImageFromFlickrBySearch(methodParameters as [String: AnyObject], completionHandler: {response in
                switch response {
                case .success(let res):
                    completionHandler(.success(res))
                  //  print(res)
                case .failure(let err):
                   // print(err)
                    completionHandler(.failure(err))
                }
            })
            }
            else {
            _ = "No Images"
            }
        }
    
    // MARK: TextField Validation
    private func bboxString(latitude: Double, longitude: Double) -> String {
            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    func isValidRange(locationValue: Double, forRange: (Double, Double)) -> Bool {
         return isValueInRange(locationValue, min: forRange.0, max: forRange.1)
        
    }

    func isValueInRange(_ value: Double, min: Double, max: Double) -> Bool {
        return !(value < min || value > max)
    }
    // MARK: Flickr API
    private func displayImageFromFlickrBySearch(_ methodParameters: [String: AnyObject], completionHandler: @escaping (_ serverResponse: ConnectionArrayResult) -> Void ) {
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                //print(error)
                performUIUpdatesOnMain {
                   
                }
            }
//
//            /* GUARD: Was there an error? */
//            guard (error == nil) else {
//                displayError("There was an error with your request: \(String(describing: error))")
//                return
//            }
//
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            // pick a random page!
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
           // self.displayImageFromFlickrBySearch(methodParameters, withPageNumber: randomPage)
            self.displayImageFromFlickrBySearch(methodParameters, withPageNumber: randomPage, completionHandler: { response in
                switch response {
                case .success(let res):
                  //  print(res)
                    completionHandler(.success(res))
                case .failure(let err):
                  //  print(err)
                    completionHandler(.failure(err))
                }
            })
        }
        // start the task!
        task.resume()
    }
    
    
    // FIX: For Swift 3, variable parameters are being depreciated. Instead, create a copy of the parameter inside the function.
    
    private func displayImageFromFlickrBySearch(_ methodParameters: [String: AnyObject], withPageNumber: Int, completionHandler: @escaping (_ serverResponse: ConnectionArrayResult) -> Void ) {
        
        
        // add the page to the method's parameters
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = withPageNumber as AnyObject?
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
                performUIUpdatesOnMain {
                   // let message = "No photo returned. Try again."
                }
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(String(describing: error))")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            var photos = [[String: AnyObject]]()
            //get the first twenty elements
            for i in 0 ... 20 {
                photos.append(photosArray[i])
            }
            print(photosArray)
                if let error = error {
                    completionHandler(.failure(error))
                }
                else {
                    completionHandler(.success(photos))
                }
        }
        // start the task!
        task.resume()
    }
    
    
    
    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
