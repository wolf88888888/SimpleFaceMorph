//
//  ViewController.swift
//  FaceMorph
//
//  Created by Admin on 12/24/17.
//  Copyright © 2017 wolf. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet var ivFirst: UIImageView!
    @IBOutlet var ivSecond: UIImageView!
    @IBOutlet var ivResult: UIImageView!
    @IBOutlet var sldMorph: UISlider!
    
    let morph = FaceMorph()
    var operation = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        ivFirst.layer.borderColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).cgColor
        ivFirst.layer.cornerRadius = 0.0
        ivFirst.layer.borderWidth = 1.0
        ivFirst.layer.masksToBounds = true;
        ivFirst.contentMode = .scaleAspectFit
        
        ivSecond.layer.borderColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).cgColor
        ivSecond.layer.cornerRadius = 0.0
        ivSecond.layer.borderWidth = 1.0
        ivSecond.layer.masksToBounds = true;
        ivSecond.contentMode = .scaleAspectFit
        
        ivResult.layer.borderColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).cgColor
        ivResult.layer.cornerRadius = 0.0
        ivResult.layer.borderWidth = 1.0
        ivResult.layer.masksToBounds = true;
        ivResult.contentMode = .scaleAspectFit
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onFirstImage(_ sender: Any) {
        if (operation != -1) {
            return
        }
        operation = 0;
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
        
        sldMorph.value = 0;
    }
    
    @IBAction func onSecondImage(_ sender: Any) {
        if (operation != -1) {
            return
        }
        operation = 1;
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
        
        sldMorph.value = 0;
    }
    
    @IBAction func MorphChange(_ sender: Any) {
        let imgResult = morph?.faceMorph(sldMorph.value);
        if (imgResult != nil) {
            ivResult.image = imgResult;
        }
    }
}

extension MainViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        if (operation == 0) {
            self.ivFirst.image = image
            if (morph?.setFirstImage(image) != true) {
                // create the alert
                let alert = UIAlertController(title: "Alert", message: "Current image hasn't any face, Please select new Image", preferredStyle: UIAlertControllerStyle.alert)
                
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                // show the alert
                self.present(alert, animated: true, completion: nil)
            }
            else {
                
            }
        }
        else if (operation == 1) {
            self.ivSecond.image = image
            if (morph?.setSecondImage(image) != true) {
                // create the alert
                let alert = UIAlertController(title: "Alert", message: "Current image hasn't any face, Please select new Image", preferredStyle: UIAlertControllerStyle.alert)
                
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                // show the alert
                self.present(alert, animated: true, completion: nil)
            }
            else {
                
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
        
        operation = -1;
    }
}
