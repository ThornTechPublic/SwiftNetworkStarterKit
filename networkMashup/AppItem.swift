//
//  AppItem.swift
//  networkMashup
//
//  Created by Robert Chen on 7/3/15.
//  Copyright (c) 2015 Thorn Technologies. All rights reserved.
//

import Foundation

// This is the model that yanks out the string and image URL from the API response.
class AppItem {
    
    var imageURLString:String? = nil
    var name:String? = nil
    
    init(appObject:JSON){
        self.imageURLString = appObject["im:image"][0]["label"].string
        self.name = appObject["im:name"]["label"].string
    }
    
}

/// Example JSON

/*
{
    "im:name":{
        "label":"musical.ly - add music & sound effects to your videos with fast motion, slow motion, dub and share on instagram"
    },
    "im:image":[
        {
        "label":"http://is2.mzstatic.com/image/pf/us/r30/Purple7/v4/43/b6/e3/43b6e316-d3b7-e2d4-5dd0-b432aabd92da/mzl.ykeqwevp.53x53-50.png",
        "attributes":{
                "height":"53"
            }
        }, {
        "label":"http://is3.mzstatic.com/image/pf/us/r30/Purple7/v4/43/b6/e3/43b6e316-d3b7-e2d4-5dd0-b432aabd92da/mzl.ykeqwevp.75x75-65.png",
        "attributes":{
                "height":"75"
            }
        }, {
        "label":"http://is3.mzstatic.com/image/pf/us/r30/Purple7/v4/43/b6/e3/43b6e316-d3b7-e2d4-5dd0-b432aabd92da/mzl.ykeqwevp.100x100-75.png",
        "attributes":{
                "height":"100"
            }
        }
    ],
    "summary":{
        "label":"Add music..."
    },
    "im:price":{
        "label":"Get",
        "attributes":{
            "amount":"0.00000",
            "currency":"USD"
        }
    },
    "title": {
        "label":"musical.ly - add music & sound effects to your videos with fast motion, slow motion, dub and share on instagram - Jun Zhu"
    },
    "link":{
        "attributes":{
            "rel":"alternate",
            "type":"text/html",
            "href":"https://itunes.apple.com/us/app/musical.ly-add-music-sound/id835599320?mt=8&uo=2"
        }
    }
}
*/