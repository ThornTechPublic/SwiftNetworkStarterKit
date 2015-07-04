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
        case CreateMultipart(contentType: String, payload: NSMutableData)
        
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
            case .CreateMultipart(let contentType, let payload):
                // Multipart form.  Set content type and pass along the body (NSData).  JSON params are embedded in data.
                URLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
                URLRequest.HTTPBody = payload
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
        
        // Set Content-Type in HTTP header.
        let boundaryConstant = "---------------------------126394370319358019764645774"; // This number probably should be auto-generated.
        let contentType = "multipart/form-data; boundary=" + boundaryConstant
        let mimeType = "image/jpg"
        
        // TODO: You want to set the fieldName to what your API accepts
        let fieldName = "file"
        
        let imageData = UIImageJPEGRepresentation(image, 0.7)
        
        // Example of what it might look like:
        
        //            -----------------------------126394370319358019764645774
        //            Content-Disposition: form-data;
        //            Content-Type: application/json
        //
        //            { "title":"foo", "description":"bar" }
        //            -----------------------------126394370319358019764645774
        //            Content-Disposition: form-data; name="file"; filename="TwitterIcon.png"
        //            Content-Type: image/png
        
        // Set data
        var error: NSError?
        var dataString = NSMutableData()
        // This "appendString" method is not a real method.
        // We're using an extension on NSMutableData (scroll down to the bottom).
        // It makes the code easier to read.
        dataString.appendString("--\(boundaryConstant)")
        dataString.appendString("\r\n")
        dataString.appendString("Content-Disposition: form-data;")
        dataString.appendString("\r\n")
        dataString.appendString("Content-Type: application/json")
        dataString.appendString("\r\n")
        dataString.appendString("\r\n")
        // This is your stringified JSON
        dataString.appendString(parameterString!)
        dataString.appendString("\r\n")
        dataString.appendString("--\(boundaryConstant)")
        dataString.appendString("\r\n")
        dataString.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"iosFile.jpg\"")
        dataString.appendString("\r\n")
        dataString.appendString("Content-Type: \(mimeType)")
        dataString.appendString("\r\n")
        dataString.appendString("\r\n")
        dataString.appendData(imageData!)
        dataString.appendString("\r\n")
        dataString.appendString("--\(boundaryConstant)--")
        dataString.appendString("\r\n")
        
        request(Router.CreateMultipart(contentType: contentType, payload: dataString))
            .responseJSON() { (request, response, data, error) in
                if error != nil {
                    // error condition.  for example, user is offline.
                    // indicate the call was unsuccessful.
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
            
            // Cache only if the image downloaded completely.  Otherwise, you end up caching corrupt images in poor network situations.
            // Check if the Content-Length exactly matches the data.length.
            // Remember there are two lines in the AppDelegate to setup the NSURLCache.
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

// MARK: - NSMutableData Extension

// see http://stackoverflow.com/questions/26162616/upload-image-with-parameters-in-swift
extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// :param: string       The string to be added to the `NSMutableData`.
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}