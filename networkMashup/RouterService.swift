//
//  RouterService.swift
//  networkMashup
//
//  Created by Robert Chen on 7/3/15.
//  Copyright (c) 2015 Thorn Technologies. All rights reserved.
//

import UIKit
import Foundation

class RouterService {
    
    // see http://code.martinrue.com/posts/the-singleton-pattern-in-swift for thread-safe singletons
    // although the link appears to be down
    class var sharedInstance: RouterService {
        struct Static {
            static var instance: RouterService?
            static var token: dispatch_once_t = 0
        }
        dispatch_once(&Static.token) {
            Static.instance = RouterService()
        }
        return Static.instance!
    }
    
    // see AlamoFire readme for more details
    // https://github.com/Alamofire/Alamofire
    //
    // also here's a good tutorial (toward the bottom)
    // http://www.raywenderlich.com/85080/beginning-alamofire-tutorial
    enum Router: URLRequestConvertible {
        
        // define Router calls and input parameter types
        case FetchTopFree()
        case FetchTopPaid()
        case CreatePost(params: [String: AnyObject])
        
        var URLRequest: NSURLRequest {
            // generate HTTP verbs, URL paths, and parameters
            let (verb: String, path: String, parameters: [String: AnyObject]?) = {
                switch self {
                case .FetchTopFree():
                    // iTunes API URLs can be generated here https://rss.itunes.apple.com/us/?urlDesc=
                    return ("GET", "https://itunes.apple.com/us/rss/topfreeapplications/limit=10/json", nil)
                case .FetchTopPaid():
                    return ("GET", "https://itunes.apple.com/us/rss/toppaidapplications/limit=10/json", nil)
                case .CreatePost(let params):
                    // Make API calls against a server
                    // see http://stackoverflow.com/questions/5725430/http-test-server-that-accepts-get-post-calls
                    return ("POST", "http://httpbin.org/post", params)
                }
            }()
            
            let URL = NSURL(string: path)!
            let URLRequest = NSMutableURLRequest(URL: URL)
            URLRequest.HTTPMethod = verb
            URLRequest.cachePolicy = .ReloadIgnoringLocalCacheData
            URLRequest.timeoutInterval = 60.0
            
            switch self {
            case .CreatePost:
                // JSON encode the parameters
                return ParameterEncoding.JSON.encode(URLRequest, parameters: parameters).0
            default:
                // URL encode into GET parameters for everything else
                return ParameterEncoding.URL.encode(URLRequest, parameters: parameters).0
            }
            
        }
    }
    
    func fetchTopFree(callback: (Bool, [AppItem]) -> Void) {
        request(Router.FetchTopFree())
            .responseJSON() { (request, response, data, error) in
                if error != nil {
                    // Error condition, return false for success flag.
                    callback(false, [])
                } else {
                    // convert the response using swiftyJSON
                    let json = JSON(data!)
                    let feedArray = json["feed"]["entry"]
                    // load up the app item objects into an array and pass it to the callback
                    var appCollectionResponse = [AppItem]()
                    for (_, appItem) in feedArray {
                        appCollectionResponse.append(AppItem(appObject: appItem))
                    }
                    callback( true, appCollectionResponse )
                }
        }
    }
    
    func fetchTopPaid(callback: (Bool, [AppItem]) -> Void) {
        request(Router.FetchTopPaid())
            .responseJSON() { (request, response, data, error) in
                if error != nil {
                    // Error condition, return false for success flag.
                    callback(false, [])
                } else {
                    // convert the response using swiftyJSON
                    let json = JSON(data!)
                    let feedArray = json["feed"]["entry"]
                    // load up the app item objects into an array and pass it to the callback
                    var appCollectionResponse = [AppItem]()
                    for (_, appItem) in feedArray {
                        appCollectionResponse.append(AppItem(appObject: appItem))
                    }
                    callback( true, appCollectionResponse )
                }
        }
    }
    
    func createPost(callback: Bool -> Void){
        var parameters:[String: AnyObject] = [
            "title": "foo",
            "description": "bar"
        ]
        request(Router.CreatePost(params: parameters))
            .responseJSON() { (request, response, data, error) in
                if error != nil {
                    // Error condition, return false for success flag.
                    callback(false)
                } else {
                    // convert the response using swiftyJSON
                    let json = JSON(data!)
                    println("json:: \(json)")
                    callback(true)
                }
        }
    }
    
}

// MARK: - Alamofire Extension

extension Request {
    // Image Serializer
    // see http://www.raywenderlich.com/85080/beginning-alamofire-tutorial
    class func imageResponseSerializer() -> Serializer {
        return { request, response, data in
            
            if data == nil || response == nil {
                return (nil, nil)
            }
            
            // cache only if the image downloaded completely
            if let contentLength = response?.allHeaderFields["Content-Length"] as? String {
                if let data = data {
                    if contentLength == "\(data.length)" {
                        // caches NSData response
                        let cachedURLResponse = NSCachedURLResponse(response: response!, data: (data as NSData), userInfo: nil, storagePolicy: .Allowed)
                        NSURLCache.sharedURLCache().storeCachedResponse(cachedURLResponse, forRequest: request)
                    } else {
                        println("dont cache this image!!!")
                    }
                }
            }
            
            // scales the image to screen size
            let image = UIImage(data: data!, scale: UIScreen.mainScreen().scale)
            return (image, nil)
        }
    }
    /// Turns Data into UIImage
    func responseImage(completionHandler: (NSURLRequest, NSHTTPURLResponse?, UIImage?, NSError?) -> Void) -> Self {
        return response(serializer: Request.imageResponseSerializer(), completionHandler: { (request, response, image, error) in
            completionHandler(request, response, image as? UIImage, error)
        })
    }
}