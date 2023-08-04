//
//  ViewController.swift
//  TravelBook
//
//  Created by Şeyda Aydın on 9.06.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate{
    

    @IBOutlet weak var mapKitView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var choseLongitude = Double()
    
    var selectedTitle = ""
    var selectedId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapKitView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest   //konumun kesinliğinin ne kadar olması gerektiğini ayarladık
        locationManager.requestWhenInUseAuthorization()             //konumun sadece uygulamayı kullanırken bizi takip etmesi
        locationManager.startUpdatingLocation()
        
        let gesturedRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(choosenLocation(gesturedRecognizer:)))
        gesturedRecognizer.minimumPressDuration = 3
        mapKitView.addGestureRecognizer(gesturedRecognizer)
        
        if selectedTitle != "" {
             //Core Data       //Seçilen view  ViewControllerde gözükür
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] // coreDataya ulaştık
                    {
                        
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let cordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = cordinate
                                        
                                        mapKitView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                                        let region = MKCoordinateRegion(center: cordinate, span: span)
                                        mapKitView.setRegion(region, animated: true)
                                    }
                                }
                            }
                            
                        }
                    }
                }
                
            } catch{
                print("error")
            }
            
            saveButton.isHidden = true
            
        }
        else {
             
            //Add new data
        }
        
    }
    
    @objc func choosenLocation(gesturedRecognizer:UILongPressGestureRecognizer) {    //içerisine göndermeseydik gesturedRecognizer ve methodlarını kullanamazdık
        
        if gesturedRecognizer.state == .began {              //touch başladıysa
            
            let touchedPoint = gesturedRecognizer.location(in: self.mapKitView)
            let touchedCoordinates = self.mapKitView.convert(touchedPoint, toCoordinateFrom: self.mapKitView)
            
            chosenLatitude = touchedCoordinates.latitude
            choseLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()       //pin oluşturma
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            
            self.mapKitView.addAnnotation(annotation)
            
            
        }
        
        
        
    }
 
    
    
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)      //enlem ve boylamlardan olluşan konum çizmek için bir obje
            let span = MKCoordinateSpan(latitudeDelta: 0.1 , longitudeDelta: 0.1)    //haritada gösterebilmek için zoom seviyesi yaptık buna span denir
            
            let region = MKCoordinateRegion(center: location , span: span )
            mapKitView.setRegion(region, animated: true)
        }
        else {
            
        }
        
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button  //sağ tarafında göster
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if selectedTitle != "" {
            
            
            var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { ( placemarks, error) in        //CLGeocoder navigasyonu çalıştırmak için gerekli objeyi alır
                //closure  bir işlem yapılıyor ve sonucunda bir şey veriliyor ya hata ya bir dizi biz de navigasyonu başlatabilmek için bu dizinin objesini kullanacağız
                
                if let placemark = placemarks {
                    
                    if placemark.count > 0 {
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
            }
            
            
        }
    }
    
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlaces = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlaces.setValue(nameText.text, forKey: "title")
        newPlaces.setValue(commentText.text, forKey: "subtitle")
        newPlaces.setValue(chosenLatitude, forKey: "latitude")
        newPlaces.setValue(choseLongitude, forKey: "longitude")
        newPlaces.setValue(UUID(), forKey: "id")
        
        do{
            try  context.save()
            print("succes!")
            
        }catch{
            
            print("error!")
            
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)//newPlace isimli bir observ yolladık
        navigationController?.popViewController(animated: true)    //bir önceki controllera döndük
       
    }
    
    
    


}

