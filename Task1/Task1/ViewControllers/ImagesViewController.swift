//
//  ViewController.swift
//  Task1
//
//  Created by Adeel Hussain on 26/02/2022.
//

import UIKit

class ImagesViewController: UIViewController , ImageDownloadingDelegate{
    @IBOutlet weak var firstImageView: UIImageView!
    @IBOutlet weak var secondImageView: UIImageView!
    @IBOutlet weak var thirdImageView: UIImageView!
    @IBOutlet weak var firstProgressVieew: UIProgressView!
    @IBOutlet weak var secondProgressView: UIProgressView!
    @IBOutlet weak var thirdProgressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ImageDownloadManager.shared.imageDownloadingDelegate = self
        
        ImageDownloadManager.shared.downloadImage(with: "https://cdn.spacetelescope.org/archives/images/publicationjpg/heic1509a.jpg", completionHandler: { (image, cached) in

            self.firstImageView.image = image

        }, placeholderImage: UIImage(named: "placeholder_profile_pic"))
        
        ImageDownloadManager.shared.downloadImage(with: "https://cdn.spacetelescope.org/archives/images/large/heic1307a.jpg", completionHandler: { (image, cached) in

            self.secondImageView.image = image

        }, placeholderImage: UIImage(named: "placeholder_profile_pic"))
        ImageDownloadManager.shared.downloadImage(with: "https://cdn.spacetelescope.org/archives/images/publicationjpg/heic1107a.jpg", completionHandler: { (image, cached) in

            self.thirdImageView.image = image

        }, placeholderImage: UIImage(named: "placeholder_profile_pic"))
    }
    // Image Delegates
    func downloadedImage(image: UIImage, index: Int) {
        DispatchQueue.main.async {
            if index == 1 {
                self.firstImageView.image = image
            }else if index == 2{
                self.secondImageView.image = image
            }else{
                self.thirdImageView.image = image
            }
        }
    }
    func downloadedImageProgress(progress: Float, index: Int) {
        DispatchQueue.main.async {
            if index == 1 {
                self.firstProgressVieew.progress = progress
            }else if index == 2{
                self.secondProgressView.progress = progress
            }else{
                self.thirdProgressView.progress = progress
            }
        }
    }
}

