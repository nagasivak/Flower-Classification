//
//  ViewController.swift
//  FlowerClassification
//
//  Created by Naga Siva on 11/02/21.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var pointingImage: UIImageView!
    @IBOutlet weak var wikiTextView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pointingImage.isHidden = false
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        // Do any additional setup after loading the view.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[.originalImage] as? UIImage {
            imageView.image = userPickedImage
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Cannot convert UIImage to CIImage")
            }
            detect(image: ciimage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage) {
        
        guard let model =  try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading Model Failed")
        }
        
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("could not classify image.")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
        ]
        
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            do{
                //let flowerModel =  try JSONDecoder().decode(FlowerModel.self, from: response.data!)
                let flowerModel = try JSON(data: response.data!)
                let pageids = flowerModel["query"]["pageids"][0].stringValue
                
                let extract = flowerModel["query"]["pages"]["\(pageids)"]["extract"].stringValue
                
                DispatchQueue.main.async {
                    self.wikiTextView.text = extract
                }
                    
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        pointingImage.isHidden = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    
}

