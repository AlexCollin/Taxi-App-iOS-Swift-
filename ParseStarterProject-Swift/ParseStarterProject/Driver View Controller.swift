//
//  Driver View Controller.swift
//  ParseStarterProject-Swift
//
//  Created by Arunjot Singh on 6/16/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class Driver_View_Controller: UITableViewController, CLLocationManagerDelegate {
    
    var usernames = [String]()
    var locations = [CLLocationCoordinate2D]()
    var distances = [CLLocationDistance]()
    
    let manager = CLLocationManager()
    var latitude = CLLocationDegrees()
    var longitude = CLLocationDegrees()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        if #available(iOS 8.0, *) {
            manager.requestAlwaysAuthorization()
        }
        manager.startUpdatingLocation()
        
        
     
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let driverLocation: CLLocationCoordinate2D = (manager.location?.coordinate)!
        self.latitude = driverLocation.latitude
        self.longitude = driverLocation.longitude
        print("\(latitude), \(longitude)")
    
        
        
        
        
        
        
        var query = PFQuery(className: "driverLocation")
        query.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)
        query.findObjectsInBackgroundWithBlock({ (objects, error) in
            
            if error == nil {
                
                if let objects = objects {
                    
                    if objects.count > 0 {
                        
                        for object in objects {
                            
                            let query = PFQuery(className: "driverLocation")
                            query.getObjectInBackgroundWithId(object.objectId!, block: { (object, error) in
                                
                                if error != nil {
                                    
                                    print(error)
                                    
                                } else if let object = object {
                                    object["driverLocation"] = PFGeoPoint(latitude: self.latitude, longitude: self.longitude)
                                    object.saveInBackground()
                                    
                                    
                                    
                                }
                            })
                            
                        }
                    }  else {
                    
                    let driverLocation = PFObject(className: "driverLocation")
                    driverLocation["username"] = PFUser.currentUser()?.username!
                    driverLocation["driverLocation"] = PFGeoPoint(latitude: self.latitude, longitude: self.longitude)
                    driverLocation.saveInBackground()
                    
                }
            }
                
        } else {
            print(error)
        }

    })
        
        
        
        
        
        
        
        query = PFQuery(className: "RiderRequest")
        query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: latitude, longitude: longitude))
        query.limit = 10
        query.findObjectsInBackgroundWithBlock({ (objects, error) in
            
            if error == nil {
                
                if let objects = objects {
                    
                    self.usernames.removeAll()
                    self.locations.removeAll()
                    
                    for object in objects {
                        
                        if object["driverResponded"] == nil {
                           
                            if let username = object["username"] as? String {
                                
                                self.usernames.append(username)
                                
                            }
                            
                            if let riderLocation = object["location"] as? PFGeoPoint {
                                
                                let requestLocation = CLLocationCoordinate2D(latitude: riderLocation.latitude, longitude: riderLocation.longitude)
                                self.locations.append(requestLocation)
                                
                                let requestCLLocation = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
                                let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                let distance = driverCLLocation.distanceFromLocation(requestCLLocation)
                                self.distances.append(distance/1000)
                            }
                        }
                        self.tableView.reloadData()
                        //                    print(self.usernames)
                        //                    print(self.locations)
                    }
                       
                }
                
            } else {
                
                print(error)
            }
        })
        
        
    }
    
                    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        let distanceDouble = Double(distances[indexPath.row])
        let roundedDistance = round((distanceDouble * 10) / 10)
        //print(roundedDistance)
        cell.textLabel?.text = "\(usernames[indexPath.row]):  \(roundedDistance) Km away"
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "logOutDriver" {
            
            manager.stopUpdatingLocation()

            navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: false)
            PFUser.logOut()
            
        } else if segue.identifier == "showViewRequest" {
            
            if let destinationVC = segue.destinationViewController as? RequestViewController {
                
                destinationVC.riderLocation = locations[(tableView.indexPathForSelectedRow?.row)!]
                destinationVC.riderUsername = usernames[(tableView.indexPathForSelectedRow?.row)!]
            }
            
        }
    }

}
