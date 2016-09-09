//
//  Rider View Controller.swift
//  ParseStarterProject-Swift
//
//  Created by Arunjot Singh on 6/16/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class Rider_View_Controller: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet var map: MKMapView!
    
    let manager = CLLocationManager()
    var latitude = CLLocationDegrees()
    var longitude = CLLocationDegrees()
    
    var riderRequestActive = false
    var driverOnTheWay = false
    
    @IBOutlet var callUberButton: UIButton!
    
    @IBAction func callUber(sender: AnyObject) {
        
        if riderRequestActive == false {
            
            let riderRequest = PFObject(className: "RiderRequest")
            riderRequest["username"] = PFUser.currentUser()?.username
            riderRequest["location"] = PFGeoPoint(latitude: latitude, longitude: longitude)
            
            riderRequest.saveInBackgroundWithBlock { (success, error) in
                
                if success {
                    
                    self.callUberButton.setTitle("Cancel Uber", forState: .Normal)
                    self.riderRequestActive = true

                } else {
                    
                    self.displayAlert("Could not call Uber", message: "Please try again!")
                }
            }
            
        } else {
            
            let query = PFQuery(className: "RiderRequest")
            query.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)
            query.findObjectsInBackgroundWithBlock({ (objects, error) in
                
                if error == nil {
                    
                    if let objects = objects {
                        
                        for object in objects {
                            object.deleteInBackgroundWithBlock({ (success, error) in
                                if success {
                                    self.callUberButton.setTitle("Call an Uber", forState: .Normal)
                                    self.riderRequestActive = false

                                } else {
                                    self.displayAlert("Error", message: "Not able to cancel your Uber right now. Please try again later!")
                                }
                            })
                        }
                        
                    }
                }
            })
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        if #available(iOS 8.0, *) {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location: CLLocationCoordinate2D = (manager.location?.coordinate)!
        self.latitude = location.latitude
        self.longitude = location.longitude
        
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)
        query.findObjectsInBackgroundWithBlock { (objects, error) in
            
            if error == nil {
                
                if let objects = objects {
                    
                    for object in objects {
                        
                        if let driverUsername = object["driverResponded"] {
                            
                            
                            let query = PFQuery(className: "driverLocation")
                            query.whereKey("username", equalTo: driverUsername)
                            query.findObjectsInBackgroundWithBlock({ (objects, error) in
                                
                                if error == nil {
                                    
                                    if let objects = objects {
                                        
                                        for object in objects {
                                            
                                            if let driverLocation = object["driverLocation"] as? PFGeoPoint {
                                                
                                               // print(driverLocation)
                                                let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                                let userCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                                                let distanceMeters = userCLLocation.distanceFromLocation(driverCLLocation)
                                                let distanceKM = distanceMeters / 1000
                                                let roundedTwoDigitDistance = Double(round(distanceKM * 10) / 10)
                                                
                                                self.callUberButton.setTitle("Uber is \(roundedTwoDigitDistance) km away!", forState: .Normal)
                                                self.driverOnTheWay = true
                                                
                                                let center = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
                                                
                                                let latDelta = abs(driverLocation.latitude - location.latitude) * 2 + 0.005
                                                let lonDelta = abs(driverLocation.longitude - location.longitude) * 2 + 0.005
                                                
                                                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                                                
                                                self.map.setRegion(region, animated: true)
                                                
                                                self.map.removeAnnotations(self.map.annotations)
                                                var pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(self.latitude, self.longitude)
                                                var objectAnnotation = MKPointAnnotation()
                                                objectAnnotation.coordinate = pinLocation
                                                objectAnnotation.title = "Your Location"
                                                self.map.addAnnotation(objectAnnotation)
                                                
                                                pinLocation = CLLocationCoordinate2DMake(driverLocation.latitude, driverLocation.longitude)
                                                objectAnnotation = MKPointAnnotation()
                                                objectAnnotation.coordinate = pinLocation
                                                objectAnnotation.title = "Driver Location"
                                                self.map.addAnnotation(objectAnnotation)

                                            }
                                        }
                                    }
                                }
                            })
                            

                        }
                    }
                }
                
                
            } else {
                
                print(error)
            }
            
            
        }
        
        if driverOnTheWay == false {
            
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.map.setRegion(region, animated: true)
            //print("locations = \(latitude) \(longitude)")
            
            self.map.removeAnnotations(map.annotations)
            let pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
            let objectAnnotation = MKPointAnnotation()
            objectAnnotation.coordinate = pinLocation
            objectAnnotation.title = "Your Location"
            self.map.addAnnotation(objectAnnotation)
        }
        
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "logOutRider" {
            manager.stopUpdatingLocation()
            PFUser.logOut()
        }
    }
    
    func displayAlert(title: String, message: String) {
        
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: title , message: message , preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction((UIAlertAction(title: "OK", style: .Default, handler: { (action) in
                self.dismissViewControllerAnimated(true, completion: nil)
            })))
            
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            // Fallback on earlier versions
        }
    }

}
