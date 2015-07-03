//
//  ViewController.swift
//  networkMashup
//
//  Created by Robert Chen on 7/3/15.
//  Copyright (c) 2015 Thorn Technologies. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        request(.GET, "https://itunes.apple.com/us/rss/topfreeapplications/limit=10/json", parameters: nil, encoding: .JSON)
            .responseJSON { (request, response, data, error) in
                let json = JSON(data!)
                let iTunesStore = json["feed"]["author"]["name"]["label"].string
                println("iTunesStore:: \(iTunesStore)")
            }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

