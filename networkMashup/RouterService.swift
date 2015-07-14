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
        case CreateMultipart()
        
        // each case above needs to be implemented here.
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
                case .CreateMultipart:
                    return ("POST", "http://httpbin.org/post", nil)
                }
            }()
            
            let URL = NSURL(string: path)!
            let URLRequest = NSMutableURLRequest(URL: URL)
            URLRequest.HTTPMethod = verb
            // some nice defaults to have
            URLRequest.cachePolicy = .ReloadIgnoringLocalCacheData
            URLRequest.timeoutInterval = 60.0
            
            // handle GET, POST, and multipart POST differently
            switch self {
            // POST needs JSON encoding of params
            case .CreatePost:
                // JSON encode the parameters
                return ParameterEncoding.JSON.encode(URLRequest, parameters: parameters).0
            // Multipart POST needs a special "Content-Type" header to define the boundary between JSON and Image Data.
            case .CreateMultipart():
                // we have the URL and HTTP verb.
                // no need to mess with parameter encoding
                // because all the form and file data gets set in the upload() method.
                return URLRequest
            // Everything else is GET.  The JSON gets URL encoded.
            default:
                // URL encode into GET parameters for everything else
                return ParameterEncoding.URL.encode(URLRequest, parameters: parameters).0
            }
            
        }
    }
    
    // These are the methods called by your app.
    // Each one has a success flag in the callback.
    
    // GET top 10 free apps
    func fetchTopFree(callback: (Bool, [AppItem]) -> Void) {
        request(Router.FetchTopFree())
            .responseJSON() { (request, response, data, error) in
                if error != nil {
                    // Error condition, return false for success flag.
                    callback(false, [])
                } else {
                    // convert the response using swiftyJSON
                    let json = JSON(data!)
                    // apple structures the array of apps in feed.entry
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
    
    // GET top 10 paid apps
    func fetchTopPaid(callback: (Bool, [AppItem]) -> Void) {
        request(Router.FetchTopPaid())
            .responseJSON() { (request, response, data, error) in
                if error != nil {
                    // Error condition, return false for success flag.
                    callback(false, [])
                } else {
                    // convert the response using swiftyJSON
                    let json = JSON(data!)
                    // apple structures the array of apps in feed.entry
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
    
    // POST to httpbin.org
    func createPost(callback: Bool -> Void){
        // hard-coding params just to show you how it works.
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
    
    // Multipart POST to httpbin.org
    func createMultipart(image: UIImage, callback: Bool -> Void){
        // hard-coding params just to show you how it works.

        // use SwiftyJSON to convert a dictionary to JSON
        var parameterJSON = JSON([
            "title": "foo",
            "description": "bar"
        ])
        
        // JSON stringify
        let parameterString = parameterJSON.rawString(encoding: NSUTF8StringEncoding, options: nil)
        let jsonParameterData = parameterString!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        let imageData = UIImageJPEGRepresentation(image, 0.7)
        
        upload(
            Router.CreateMultipart(),
            multipartFormData: { multipartFormData in
                // fileData: puts it in "files"
                multipartFormData.appendBodyPart(fileData: jsonParameterData!, name: "goesIntoFile", fileName: "json.txt", mimeType: "application/json")
                multipartFormData.appendBodyPart(fileData: imageData, name: "file", fileName: "iosFile.jpg", mimeType: "image/jpg")
                // data: puts it in "form"
                multipartFormData.appendBodyPart(data: jsonParameterData!, name: "goesIntoForm")
            },
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.responseJSON { request, response, data, error in
                        println("request:: \(request)")
                        println("response:: \(response)")
                        println("data:: \(data)")
                        println("error:: \(error)")
                        
                        let json = JSON(data!)
                        println("json:: \(json)")
                        callback(true)
                    }
                case .Failure(let encodingError):
                    callback(false)                }
            }
        )
        
        
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
            } else {
                // Cache only if the image downloaded completely.  Otherwise, you end up caching corrupt images in poor network situations.
                // Check if the Content-Length exactly matches the data.length.
                // Remember there are two lines in the AppDelegate to setup the NSURLCache.
                if let contentLength = response?.allHeaderFields["Content-Length"] as? String {
                    if let data = data {
                        if contentLength == "\(data.length)" {
                            // UIImage class method is not thread-safe. See UIImage extension below.
                            let image = UIImage.safeImageWithData(data)
                            
                            // caches NSData response
                            let cachedURLResponse = NSCachedURLResponse(response: response!, data: (data as NSData), userInfo: nil, storagePolicy: .Allowed)
                            NSURLCache.sharedURLCache().storeCachedResponse(cachedURLResponse, forRequest: request)
                            return (image, nil)
                        }
                    }
                }
                return (nil, nil)
            }
        }
    }
    /// Turns Data into UIImage
    func responseImage(completionHandler: (NSURLRequest, NSHTTPURLResponse?, UIImage?, NSError?) -> Void) -> Self {
        return response(serializer: Request.imageResponseSerializer(), completionHandler: { (request, response, image, error) in
            completionHandler(request, response, image as? UIImage, error)
        })
    }
}

// see https://github.com/Haneke/HanekeSwift/pull/207/files
private let imageSync = NSLock()

extension UIImage {
    
    static func safeImageWithData(data:NSData) -> UIImage? {
        imageSync.lock()
        let image = UIImage(data:data)
        imageSync.unlock()
        return image
    }
    
}