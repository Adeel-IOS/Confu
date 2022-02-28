//
//  ImageDownloadManager.swift
//  Task1
//
//  Created by Adeel Hussain on 26/02/2022.
//

import UIKit

protocol ImageDownloadingDelegate{
    
    func downloadedImage(image: UIImage , index : Int) -> ()
    func downloadedImageProgress(progress: Float , index : Int) -> ()
}

class ImageDownloadManager: NSObject , URLSessionDelegate, URLSessionDownloadDelegate  {
    
    var imageDownloadingDelegate : ImageDownloadingDelegate!
    
    private lazy var urlSession = URLSession(configuration: .default,
                                             delegate: self,
                                             delegateQueue: nil)
    
    static let shared = ImageDownloadManager() // shared instance
    
    
    private var imagesDownloadTasks: [String: URLSessionDownloadTask]
        
    let serialQueueForDataTasks = DispatchQueue(label: "dataTasks.queue", attributes: .concurrent)
    
    private override init() {

        self.imagesDownloadTasks = [:]
    }
    
    func downloadImage(with imageUrlString: String?,
                       completionHandler: @escaping (UIImage?, Bool) -> Void,
                       placeholderImage: UIImage?) {
        
        guard let imageUrlString = imageUrlString else {
            completionHandler(placeholderImage, true)
            return
        }
        guard let url = URL(string: imageUrlString) else {
            completionHandler(placeholderImage, true)
            return
        }
        
        if let _ = getDataTaskFrom(urlString: imageUrlString) {
            return
        }
        let downloadTask = self.urlSession.downloadTask(with: url)
           downloadTask.resume()
        // We want to control the access to no-thread-safe dictionary in case it's being accessed by multiple threads at once
        self.serialQueueForDataTasks.sync(flags: .barrier) {
            self.imagesDownloadTasks[imageUrlString] = downloadTask
        }
        
        downloadTask.resume()
    }
    private func getDataTaskFrom(urlString: String) -> URLSessionTask? {
        
        // Reading from the dictionary should happen in the thread-safe manner.
        self.serialQueueForDataTasks.sync {
            return imagesDownloadTasks[urlString]
        }
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.imageDownloadingDelegate.downloadedImageProgress(progress: progress, index: downloadTask.taskIdentifier)
        }
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        // Clear out the finished task from download tasks container
        _ = self.serialQueueForDataTasks.sync(flags: .barrier) {
            print("request url : \(downloadTask.originalRequest!.url!.absoluteString)")
            self.imagesDownloadTasks.removeValue(forKey: (downloadTask.originalRequest!.url!.absoluteString))
        }
        
        let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
        
        let date :NSDate = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'_'HH:mm:ss"
        let imageName = "-\(downloadTask.taskIdentifier)-\(dateFormatter.string(from: date as Date)).jpg"
        
        let destinationFileUrl = documentsUrl.appendingPathComponent("\(imageName)")
        do {
            try FileManager.default.copyItem(at: location, to: destinationFileUrl)
            let imagData = NSData(contentsOf: location)
            let image = UIImage(data: imagData! as Data)
            self.imageDownloadingDelegate.downloadedImage(image: image!, index: downloadTask.taskIdentifier)
            
        } catch (let writeError) {
            print("error \(writeError)")
        }
        debugPrint("Download finished: \(location)")
        try? FileManager.default.removeItem(at: location)
    }
}
