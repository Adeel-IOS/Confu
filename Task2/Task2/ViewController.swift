//
//  ViewController.swift
//  Task2
//
//  Created by Adeel Hussain on 28/02/2022.
//

import UIKit

import MultipeerConnectivity
import os

enum NamedColor: String, CaseIterable {
    case red, green, yellow
}


class ViewController: UIViewController, UITableViewDataSource , UITableViewDelegate,UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    
     var serviceType = "example-color"

     var session: MCSession!
    var myPeerId : MCPeerID = MCPeerID(displayName: UIDevice.current.name)
     var serviceAdvertiser: MCNearbyServiceAdvertiser!
     var serviceBrowser: MCNearbyServiceBrowser!
     var log = Logger()
    
    var connectedPeers: [MCPeerID] = [MCPeerID]()
    var imagePicker = UIImagePickerController()
    var thumbNailPlaceHHolder = UIImage()

    
    @IBOutlet weak var imageTableView: UITableView!
    var imageArray : [UIImage] = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.session = MCSession(peer: myPeerId)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self

        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
        // Do any additional setup after loading the view.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return imageArray.count
        }else{
            return connectedPeers.count//imageArray.count
            
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let imageCell = tableView.dequeueReusableCell(withIdentifier: "ImageTableViewCell", for: indexPath) as! ImageTableViewCell
            imageCell.imgView.image = self.imageArray[indexPath.row]
            return imageCell
        }else{
            
            let peerInfoCell = tableView.dequeueReusableCell(withIdentifier: "peerInfoTableViewCell", for: indexPath) as! peerInfoTableViewCell
            peerInfoCell.namelabel.text = self.connectedPeers[indexPath.row].displayName
            return peerInfoCell
            
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    @IBAction func sendMessageButtonClickAction(_ sender: UIButton) {
        
        let actionSheet = UIAlertController(title: "Please select one option", message: nil, preferredStyle: .actionSheet)
        
        let  selectPhotoCamera = UIAlertAction(title: "Take Photo", style: .default) { (action) in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
                self.imagePicker = UIImagePickerController()
                self.imagePicker.delegate = self
                self.imagePicker.sourceType = UIImagePickerController.SourceType.camera
                self.imagePicker.allowsEditing = false
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
        let  selectPhoto = UIAlertAction(title: "Gallery Photo", style: .default) { (action) in
            self.imagePicker.delegate = self
            self.imagePicker.sourceType = .photoLibrary
            self.imagePicker.mediaTypes = ["public.image", "public.movie" , "public.video"]
            self.imagePicker.allowsEditing = true
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (action) in
            
        }
        actionSheet.addAction(selectPhotoCamera);
        actionSheet.addAction(selectPhoto);
        actionSheet.addAction(cancelAction);
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
        }
        present(actionSheet, animated: true) {
            
        }
    }
    //MARK:- Image Picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let imagePicked = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            
            self.thumbNailPlaceHHolder = imagePicked
            self.imageSend()
            DispatchQueue.main.async {
                self.imageArray.append(self.thumbNailPlaceHHolder)
                self.imageTableView.reloadData()
            }
        }
    }
    func imageSend(){
        do {
            print("image send calleed")
            let data = self.thumbNailPlaceHHolder.jpegData(compressionQuality: 0.10)
            try self.session.send(data!, toPeers: self.connectedPeers, with: .reliable)
        }catch {
            print("catch ")

        }
        dismiss(animated: true, completion: nil)
    }
}

extension ViewController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        precondition(Thread.isMainThread)
        log.error("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        precondition(Thread.isMainThread)
        log.info("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, session)
    }
}

extension ViewController: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        log.error("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        log.info("ServiceBrowser found peer: \(peerID)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        log.info("ServiceBrowser lost peer: \(peerID)")
    }
}

extension ViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        log.info("peer \(peerID) didChangeState: \(state.debugDescription)")
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
            self.imageTableView.reloadData()
        }
        
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("data recieving ??")
        
        let image = UIImage(data: data)
        DispatchQueue.main.async {
            self.imageArray.append(image!)
            self.imageTableView.reloadData()
            
        }

    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        log.error("Receiving streams is not supported")
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        log.error("Receiving resources is not supported")
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        log.error("Receiving resources is not supported")
    }
}

extension MCSessionState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notConnected:
            return "notConnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        @unknown default:
            return "\(rawValue)"
        }
    }
}
