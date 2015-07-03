//
//  ViewController.swift
//  networkMashup
//
//  Created by Robert Chen on 7/3/15.
//  Copyright (c) 2015 Thorn Technologies. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    var appCollectionResponse = [AppItem]()
    
    @IBAction func freeOrPaid(sender: UISegmentedControl) {
        println(sender.selectedSegmentIndex)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        request(.GET, "https://itunes.apple.com/us/rss/topfreeapplications/limit=10/json", parameters: nil, encoding: .JSON)
            .responseJSON { (request, response, data, error) in
                let json = JSON(data!)
                let feedArray = json["feed"]["entry"]
                println("feedArray:: \(feedArray)")
                self.appCollectionResponse = []
                for (_, appItem) in feedArray {
                    self.appCollectionResponse.append(AppItem(appObject: appItem))
                }
                self.tableView.reloadData()
            }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - UITableViewDataSource methods

extension ViewController {
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appCollectionResponse.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! UITableViewCell
        cell.textLabel?.text = appCollectionResponse[indexPath.row].name ?? "no name in json response"
        return cell
    }
    
}
