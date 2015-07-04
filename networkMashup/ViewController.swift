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
    
    // The segmented control was toggled.
    // Make an API call to either the free or paid top 10 apps
    @IBAction func freeOrPaid(sender: UISegmentedControl) {
        println("tapped on index:: \(sender.selectedSegmentIndex)")
        switch sender.selectedSegmentIndex {
        case 0:
            fetchTopFree()
        default:
            fetchTopPaid()
        }
    }
    
    // Tapped on left multipart button.
    // This makes a multipart post to httpbin.org
    @IBAction func multipartButton(sender: AnyObject) {
        let appleImage = UIImage(named: "apple")
        RouterService.sharedInstance.createMultipart(appleImage!, callback: { success in
            if success {
                let alertView = UIAlertView()
                alertView.title = "Success"
                alertView.message = "Check out the println statements for the json response"
                alertView.addButtonWithTitle("Ok")
                alertView.show()
            }
        })
    }
    
    // Tapped on the right post button.
    // This makes a post to httpbin.org.
    @IBAction func postButton(sender: AnyObject) {
        RouterService.sharedInstance.createPost { success in
            if success {
                let alertView = UIAlertView()
                alertView.title = "Success"
                alertView.message = "Check out the println statements for the json response"
                alertView.addButtonWithTitle("Ok")
                alertView.show()
            }
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
        // hard-coding an image so the build-in imageView UI appears on cell instantiation.
        // serves no other purpose.
        cell.imageView?.image = UIImage(named: "apple")
        if let appImage = appCollectionResponse[indexPath.row].imageURLString {
            request(.GET, appImage)
                // this is the Image serializer in action.
                // notice the .responseImage instead of .responseJSON
                .responseImage() { (request, _, image, error) in
                    if error == nil && image != nil {
                        cell.imageView?.image = image
                    }
            }
        }

        return cell
    }
    
}
