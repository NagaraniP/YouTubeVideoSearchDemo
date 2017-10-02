//
//  PlayerViewController.swift
//  YTDemo
//
//  Created by nagarani konda on 9/29/17.
//  Copyright © 2017 nagarani konda. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController {

    @IBOutlet weak var playerView: YTPlayerView!
    
    var videoID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
           navigationController?.navigationBar.isHidden = false
        // Do any additional setup after loading the view.
        
        playerView.load(withVideoId: videoID)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
