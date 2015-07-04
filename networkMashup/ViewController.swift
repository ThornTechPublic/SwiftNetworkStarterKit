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
        
        switch sender.selectedSegmentIndex {
        case 0:
            fetchTopFree()
        default:
            fetchTopPaid()
        }
        
    }
    
    func fetchTopFree(){
        RouterService.sharedInstance.fetchTopFree(){ success, appCollection in
            self.appCollectionResponse = appCollection
            self.tableView.reloadData()
        }
    }
    
    func fetchTopPaid(){
        RouterService.sharedInstance.fetchTopPaid(){ success, appCollection in
            self.appCollectionResponse = appCollection
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchTopFree()
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
