//
//  RequestViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Arunjot Singh on 6/16/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import MapKit
import Parse

class RequestViewController: UIViewController, CLLocationManagerDelegate {
    
    var riderLocation = CLLocationCoordinate2D()
    var riderUsername = String()
    
    @IBOutlet var map: MKMapView!
    @IBOutlet var pickUpRider: UIButton!
    
    @IBAction func pickUp(sender: AnyObject) {
        
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: riderUsername)
        query.findObjectsInBackgroundWithBlock({ (objects, error) in
            
            if error == nil {
                
                if let objects = objects {
                    
                    for object in objects {
                        
                        let query = PFQuery(className: "RiderRequest")
                        query.getObjectInBackgroundWithId(object.objectId!, block: { (object, error) in
                            
                            if error != nil {
                                
                                print(error)
                                
                            } else if let object = object {
                                object["driverResponded"] = PFUser.currentUser()?.username
                                object.saveInBackground()
                                
                                let riderCLLocation = CLLocation(latitude: self.riderLocation.latitude, longitude: self.riderLocation.longitude)
                                CLGeocoder().reverseGeocodeLocation(riderCLLocation, completionHandler: { (placemarks, error) in
                                    
                                    if error != nil {
                                        
                                        print(error)
                                        
                                    } else {
                                        
                                        if placemarks?.count > 0 {
                                            
                                            let pm = placemarks![0] as CLPlacemark
                                            let mkpm = MKPlacemark(placemark: pm)
                                            let mapItem = MKMapItem(placemark: mkpm)
                                            mapItem.name = self.riderUsername
                                            
                                            let launchOption = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                            mapItem.openInMapsWithLaunchOptions(launchOption) 
                                            
                                            
                                        } else {
                                            
                                            print("problem with data received from geocoder")
                                        }
                                        
                                    }
                                })

                            }
                        })
                        
                        
                        
                    }
                    
                }
            }
        })
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(riderLocation)
        print(riderUsername)
        
        pickUpRider.setTitle("Pick Up \(riderUsername)", forState: .Normal)
    
        let region = MKCoordinateRegion(center: riderLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.map.setRegion(region, animated: true)
       
        let objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = riderLocation
        objectAnnotation.title = "\(riderUsername)'s location"
        self.map.addAnnotation(objectAnnotation)

    }

}
