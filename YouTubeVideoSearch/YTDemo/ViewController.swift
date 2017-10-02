//
//  ViewController.swift
//  YTDemo
//
//  Created by nagarani konda on 9/29/17.
//  Copyright © 2017 nagarani konda. All rights reserved.
//

import UIKit
import SystemConfiguration

protocol Utilities {
}

extension NSObject:Utilities{
    
    
    enum ReachabilityStatus {
        case notReachable
        case reachableViaWWAN
        case reachableViaWiFi
    }
    
    var currentReachabilityStatus: ReachabilityStatus {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .notReachable
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .notReachable
        }
        
        if flags.contains(.reachable) == false {
            // The target host is not reachable.
            return .notReachable
        }
        else if flags.contains(.isWWAN) == true {
            // WWAN connections are OK if the calling application is using the CFNetwork APIs.
            return .reachableViaWWAN
        }
        else if flags.contains(.connectionRequired) == false {
            // If the target host is reachable and no connection is required then we'll assume that you're on Wi-Fi...
            return .reachableViaWiFi
        }
        else if (flags.contains(.connectionOnDemand) == true || flags.contains(.connectionOnTraffic) == true) && flags.contains(.interventionRequired) == false {
            // The connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs and no [user] intervention is needed
            return .reachableViaWiFi
        }
        else {
            return .notReachable
        }
    }
    
}

class MyCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var videoImageView: UIImageView!
}

class ViewController: UIViewController,  UITextFieldDelegate ,UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {
    
    
    @IBOutlet weak var serarchBtn: UIButton!
    
    @IBOutlet weak var videoSearch: UITextField!
    let reuseIdentifier = "CellIdentifier"
    
    var apiKey = "key"// I enabled youtube data api key. To run thsi app kindly enable YT data api
    
    var videosArray: Array<Dictionary<String, AnyObject>> = []
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var selectedVideoIndex: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        videoSearch.isEnabled = false
        navigationController?.navigationBar.isHidden = true
        videoSearch.delegate = self
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func searchAction(_ sender: Any) {
        videoSearch.text = ""
        videoSearch.isEnabled = true
        serarchBtn.isHidden = true
        videoSearch.becomeFirstResponder()
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "idSeguePlayer" {
            let playerViewController = segue.destination as! PlayerViewController
            playerViewController.videoID = videosArray[selectedVideoIndex]["videoID"] as! String
            
        }
    }
    
    
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videosArray.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! MyCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        cell.backgroundColor = UIColor.cyan // make cell more visible in our example project
        let videoDetails = videosArray[indexPath.row]
        
        cell.videoImageView.image = UIImage(data: try! Data(contentsOf: URL(string: (videoDetails["thumbnail"] as? String)!)!))
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        print("You selected cell #\(indexPath.item)!")
        
        selectedVideoIndex = indexPath.row
        performSegue(withIdentifier: "idSeguePlayer", sender: self)
    }
    
   func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        print("cell hieght!")

        return CGSize(width: 100, height: 100)
    }
    
    // MARK: UITextFieldDelegate method implementation
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        
        videosArray.removeAll(keepingCapacity: false)
        
        
        if(currentReachabilityStatus != .notReachable)
        {
            // Form the request URL string.
            
            var urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(String(describing: videoSearch.text))&type=\("video")&key=\(apiKey)"
            
            urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            
            // Create a NSURL object based on the above string.
            let targetURL = URL(string: urlString)
            
            // Get the results.
            performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
                if HTTPStatusCode == 200 && error == nil {
                    // Convert the JSON data to a dictionary object.
                    do {
                        
                        let resultsDict = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, AnyObject>
                        
                        
                        // Get all search result items ("items" array).
                        
                        
                        
                        let items: Array<Dictionary<String, AnyObject>> = resultsDict["items"] as! Array<Dictionary<String, AnyObject>>
                        
                        
                        // Loop through all search results and keep just the necessary data.
                        
                        for  i in 0..<items.count{
                            
                            let snippetDict = items[i]["snippet"] as! Dictionary<String, AnyObject>
                            
                            
                            // Gather the proper data depending on whether we're searching for channels or for videos.
                            
                            
                            var videoDetailsDict = Dictionary<String, AnyObject>()
                            
                            videoDetailsDict["title"] = snippetDict["title"]
                            videoDetailsDict["thumbnail"] = ((snippetDict["thumbnails"] as! Dictionary<String, AnyObject>)["default"] as! Dictionary<String, AnyObject>)["url"]
                            
                            
                            
                            videoDetailsDict["videoID"] = (items[i]["id"] as! Dictionary<String, AnyObject>)["videoId"]
                            
                            
                            // Append the desiredPlaylistItemDataDict dictionary to the videos array.
                            self.videosArray.append(videoDetailsDict)
                            print("collectionview reload")
                            self.collectionView.reloadData()
                        }
                        //}
                    } catch {
                        print(error)
                    }
                    self.collectionView.reloadData()

                    
                }
                else {
                    print("HTTP Status Code = \(HTTPStatusCode)")
                    print("Error while loading channel videos: \(String(describing: error))")
                }
                
                
            })
        }
        
        return true
    }
    
    
    // MARK: Custom method implementation
    
    func performGetRequest(_ targetURL: URL!, completion:  @escaping (_ data: Data?, _ HTTPStatusCode: Int, _ error: NSError?) -> Void) {
        let request = NSMutableURLRequest(url: targetURL)
        request.httpMethod = "GET"
        
        let sessionConfiguration = URLSessionConfiguration.default
        
        let session = URLSession(configuration: sessionConfiguration)
        
        
        let task = session.dataTask(with: targetURL) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            DispatchQueue.main.async(execute: { () -> Void in
                completion(data, (response as! HTTPURLResponse).statusCode, error as NSError?)
            })}
        
        
        task.resume()
    }
    
    
    
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = ""
        videosArray.removeAll(keepingCapacity: false)
        collectionView.reloadData()
        textField.resignFirstResponder()
        return true
    }
    
    
    
    
    
}

