# Network Starter Kit for Swift

This is a sample project that integrates some popular libraries and useful networking features.  Admittedly, a lot of this is just implementing instructions on the [AlamoFire](https://github.com/Alamofire/Alamofire) README, but sometimes it helps to see code snippets in action.  Feel free to use this as a starter template.

The aim of this is to solve the following problems as simply as possible:

* Dry out network boilerplate code with a request router
* Encode parameters for GET and POST
* Elegantly handle JSON responses
* Serialize images (automatically convert NSData to UIImage)
* Cache successfully downloaded images
* Support Multipart POST

## Using the sample project

The working demo grabs the top 10 free and paid apps from the iTunes API.  The right and left corner buttons perform a POST and multipart POST, with the response logged to the console.

![animated gif demo](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/githubImages/networkMashupDemo.gif)

## Integration

First install [AlamoFire](https://github.com/Alamofire/Alamofire) using the instructions on their README.  I prefer to simply copy all the `.swift` files from the `Source` folder.

Next, install [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON).  Again, just copy the one `.swift` file from the `Source` folder into your project.

Copy the two lines of code from `AppDelegate.swift` that sets up caching.  [See Example](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/networkMashup/AppDelegate.swift#L20)

Copy the `RouterService.swift` file, and customize it for your own project.

## Usage

To make an API call, invoke one of the methods in the router:

```
RouterService.sharedInstance.fetchTopFree(){ success, appCollection in
    self.appCollectionResponse = appCollection
    self.tableView.reloadData()
}
```

To download an image, just request an imageURL and assign the image:

```
request(.GET, "http://example.com/imageURL")
    .responseImage() { (_, _, image, error) in
        if error == nil && image != nil {
            cell.imageView?.image = image
        }
    }
```

## How it works

### [The Router](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/networkMashup/RouterService.swift#L32)

This [tutorial](http://www.raywenderlich.com/85080/beginning-alamofire-tutorial) is a good resource for understanding the request router, as is the [AlamoFire documentation](https://github.com/Alamofire/Alamofire#urlrequestconvertible).  

Let's examine the simplest example to see how it works.

```
enum Router: URLRequestConvertible {
    case FetchTopFree()
    var URLRequest: NSURLRequest {
        let (verb: String, path: String, parameters: [String: AnyObject]?) = {
            switch self {
            case .FetchTopFree():
                return ("GET", "https://itunes.apple.com/us/rss/topfreeapplications/limit=10/json", nil)
            }
        }()
        let URL = NSURL(string: path)!
        let URLRequest = NSMutableURLRequest(URL: URL)
        URLRequest.HTTPMethod = verb
        switch self {
        default:
            return ParameterEncoding.URL.encode(URLRequest, parameters: parameters).0
        }
    }
}

request(Router.FetchTopFree())
    .responseJSON() { (_, _, data, _) in
      println(data)
    }
```

Notice how the actual `request()` call is really lightweight.  All of the URL, HTTP verb, and URL parameters are baked into the `NSURLRequest` object that gets returned by the `Router`.

The `Router` itself is an enum, with a `case` for each API endpoint.  For example, there's a `case FetchTopFree()` near the top.

There's an intimidating section that uses a tuple:

```
        let (verb: String, path: String, parameters: [String: AnyObject]?) = {
            switch self {
            case .FetchTopFree():
                return ("GET", "https://itunes.apple.com/us/rss/topfreeapplications/limit=10/json", nil)
            }
        }()
```

It's just a fancy way of saying this:

```
let verb = "GET"
let path = "https://itunes.apple.com/us/rss/topfreeapplications/limit=10/json"
let parameters = nil
```

The reason why we use the tuple with the `switch` statement is to support more `case` scenarios.

The next few lines loads up the variables for the URL and HTTP verb into a new `NSMutableURLRequest` object:

```
        let URL = NSURL(string: path)!
        let URLRequest = NSMutableURLRequest(URL: URL)
        URLRequest.HTTPMethod = verb
```

Finally, the last part doesn't do anything in this particular example, since `parameters` is nil:

```
        switch self {
        default:
            return ParameterEncoding.URL.encode(URLRequest, parameters: parameters).0
        }
```

We could have actually just done this:

```
return URLRequest
```

But if we had parameters, `ParameterEncoding.URL.encode` would convert a Swift dictionary `[ "foo" : "bar" ]` into URL parameters `?foo=bar` for GET requests.  

The sample project makes use of AlamoFire's `ParameterEncoding.JSON.encode` for the POST HTTP body.  

The Router seems a little daunting at first.  But once you have the basic structure in place, it's pretty easy to add additional API calls.  The beauty of this is the ability to add tokens or set a timeoutInterval using a single point of change.

### [JSON Serialization](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/networkMashup/RouterService.swift#L98)

Handling JSON objects with Swift can get pretty ugly.  SwiftyJSON makes life much easier.  Here's a good [tutorial if you want to learn more](http://www.raywenderlich.com/82706/working-with-json-in-swift-tutorial).

```
request(Router.FetchTopFree())
    .responseJSON() { (_, _, data, _) in
        let json = JSON(data!)
        let feedArray = json["feed"]["entry"]
        println(feedArray)
}
```

AlamoFire already gives us `.responseJSON()`.  We go a step further by converting it to a SwiftyJSON object:

```
        let json = JSON(data!)
```

This lets us reach deep into the JSON object without the dreaded `if-let` pyramid of doom.

```
        let feedArray = json["feed"]["entry"]
```

One neat trick with SwiftyJSON is the ability to turn a Swift dictionary into stringified JSON: [Example](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/networkMashup/RouterService.swift#L98)

```
// use SwiftyJSON to convert a dictionary to JSON
var parameterJSON = JSON([
    "title": "foo",
    "description": "bar"
])

// JSON stringify
let parameterString = parameterJSON.rawString(encoding: NSUTF8StringEncoding, options: nil)
```

### [Image Serialization](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/networkMashup/RouterService.swift#L236)

With image serialization, you can simply chain `.responseImage()` and expect an `UIImage` ready for use in your callback.

```
request(.GET, "http://example.com/image")
    .responseImage() { (_, _, image, _) in
        cell.imageView?.image = image
    }
```

A [previously mentioned tutorial](http://www.raywenderlich.com/85080/beginning-alamofire-tutorial) and the [AlamoFire documentation](https://github.com/Alamofire/Alamofire#response-serialization) are good resources for more information.  

### [Image Caching](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/networkMashup/RouterService.swift#L249)

Although I've come across other image caching implementations, we're going to stick with the one described [here](http://nshipster.com/nsurlcache/).  It's simple and stable.

Per the nshipster blog post, add these two lines to your `AppDelegate`.  [See Example](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/networkMashup/AppDelegate.swift#L20)

```
let URLCache = NSURLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: "cachedResponse")
NSURLCache.setSharedURLCache(URLCache)
```

Images are added to this cache using the image serializer mentioned in the previous section.

```
if let contentLength = response?.allHeaderFields["Content-Length"] as? String {
    if let data = data {
        if contentLength == "\(data.length)" {
            let cachedURLResponse = NSCachedURLResponse(response: response!, data: (data as NSData), userInfo: nil, storagePolicy: .Allowed)
            NSURLCache.sharedURLCache().storeCachedResponse(cachedURLResponse, forRequest: request)
        }
    }
}
```

There are a few validations to make sure the image has downloaded completely before calling `storeCachedResponse()`

### [Multipart POST](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/networkMashup/RouterService.swift#L155)

Multipart can be tediously to implement, if your API happens to use it.  Here's a [Stackoverflow article](http://stackoverflow.com/questions/26162616/upload-image-with-parameters-in-swift) for more information.  

Say you need to upload both an image and form data.  The mixture of binary and text can be problematic.  You could convert the image into a huge base64 string (a picture is worth a thousand words...) so that the entire POST body is text.  But there could be server limits on POST size. 

The alternative is to use Multipart, which simply requires everything to be in binary.  This means all the headers and form data need to be in binary format.  In the sample project, you start with headers converted to binary.  Then you tack on the JSON stringified form data, converted to binary.  Then append more headers, again converted to binary.  Finally you can add the image data, which is already in binary.  There's a handy `NSMutableData` extension from the Stackoverflow article that makes appending a string as binary very easy.
