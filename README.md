# Network Starter Kit for Swift

This is a sample project that integrates some popular libraries and useful networking features.  Honestly, a lot of this is just implementing instructions on the [AlamoFire](https://github.com/Alamofire/Alamofire) README, but sometimes it helps to see code snippets in the context of a sample project.  Feel free to use this as a starter template.

The aim of this is to solve the following problems as simply as possible:

* Handle JSON as elegantly as possible
* Cache successfully downloaded images
* Serialize images (automatically convert NSData to UIImage)
* Dry out network boilerplate code with a request router
* Parameter encode for GET and POST
* Multipart POST

## Using the sample project

The working demo grabs the top 10 free and paid apps from the iTunes API.  The right and left bar buttons perform a POST and multipart POST, with the response logged to the console.

![animated gif demo](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/githubImages/networkMashupDemo.gif)

## Integration

First install [AlamoFire](https://github.com/Alamofire/Alamofire) using the instructions on their README.  I prefer to simply copy all the `.swift` files from the `Source` folder.

Next, install [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON).  Again, just copy the one `.swift` file from the `Source` folder into your project.

Copy the two lines of code from `AppDelegate.swift` that sets up caching.

Copy the `RouterService.swift`, and customize it for your own project.

## How it works

### The Router

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

Notice how the actual `request()` call is really lightweight.  All of the URL, HTTP verb, and URL parameters are in the `NSURLRequest` object returned by the `Router`.

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

The next few lines loads up these variables into a new `NSMutableURLRequest` object:

```
        let URL = NSURL(string: path)!
        let URLRequest = NSMutableURLRequest(URL: URL)
        URLRequest.HTTPMethod = verb
```

Finally, the last part does actually do anything in this particular example:

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

But if we actually had parameters, `ParameterEncoding.URL.encode` will convert a Swift dictionary `[ "foo" : "bar" ]` into URL parameters `?foo=bar` for GET requests.  

The sample project makes use of AlamoFire's JSON encoding for the POST HTTP body.  

The Router seems a little daunting at first.  But once you have the basic structure in place, it's pretty easy to add additional API calls.  The beauty of this is the ability to add tokens or set a timeoutInterval with a single point of change.

### JSON Serialization

Handling JSON objects with Swift can get pretty ugly.  SwiftyJSON makes life much easier.

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

One neat trick with SwiftyJSON is the ability to turn a Swift dictionary into stringified JSON:

```
// use SwiftyJSON to convert a dictionary to JSON
var parameterJSON = JSON([
    "title": "foo",
    "description": "bar"
])

// JSON stringify
let parameterString = parameterJSON.rawString(encoding: NSUTF8StringEncoding, options: nil)
```

### Image Serialization

With image serialization, you can simply chain `.responseImage()` and expect an `UIImage` ready for use in your callback.

```
request(.GET, "http://example.com/image")
    .responseImage() { (_, _, image, _) in
        cell.imageView?.image = image
    }
```

This [same tutorial](http://www.raywenderlich.com/85080/beginning-alamofire-tutorial) and the [AlamoFire documentation](https://github.com/Alamofire/Alamofire#response-serialization) are good resources for more information.  

### Image Caching

Although I've come across other image caching implementations, we're going to stick with the one described (here)[http://nshipster.com/nsurlcache/].  It's simple and stable.

Per the nshipster blog post, add these two lines to your `AppDelegate`

```
let URLCache = NSURLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: "cachedResponse")
NSURLCache.setSharedURLCache(URLCache)
```

Images are added to this cache using the image serializer mentioned in the section above.

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

### Multipart POST

Multipart can be tediously to implement, if your API happens to use it.  Here's a (Stackoverflow article)[http://stackoverflow.com/questions/26162616/upload-image-with-parameters-in-swift] for more information.  

Say you need to upload both an image and POST information like a title and description.  The image is binary, but the rest of the HTTP POST body is text.  

Multipart simply requires everything to be in binary.  In the sample project, you start with header strings converted to binary.  Then you tack on the JSON stringified form data, converted to binary.  Then append more header binary strings.  Finally you can add the image data, which is already in binary.  There's a handy `NSMutableData` extension from the Stackoverflow article that makes appending a string as binary very easy.
