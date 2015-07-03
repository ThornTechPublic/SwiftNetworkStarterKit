//
//  AppItem.swift
//  networkMashup
//
//  Created by Robert Chen on 7/3/15.
//  Copyright (c) 2015 Thorn Technologies. All rights reserved.
//

import Foundation

class AppItem {
    
    var imageURLString:String? = nil
    var name:String? = nil
    
    init(appObject:JSON){
        self.imageURLString = appObject["im:image"][0]["label"].string
        self.name = appObject["im:name"]["label"].string
    }
    
}