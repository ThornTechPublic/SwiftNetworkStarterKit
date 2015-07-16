# Network Starter Kit for Swift

This is a sample project that integrates some popular libraries and useful networking features.  Admittedly, a lot of this is just implementing instructions on the [AlamoFire](https://github.com/Alamofire/Alamofire) README, but sometimes it helps to see code snippets in action.  Feel free to use this as a starter template.

This repo is tied to this [blog post](http://www.thorntech.com/2015/07/4-essential-swift-networking-tools-for-working-with-rest-apis/).

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

First download [AlamoFire](https://github.com/Alamofire/Alamofire).  To install, follow the instructions on their readme.  I prefer to simply copy all the `.swift` files from their `Source` folder.

Next, download [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON).  Again, you can just copy the one `.swift` file from their `Source` folder into the project.

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

To download an image, just request an imageURL and use the `responseImage()` serializer:

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

The router is an `URLRequestConvertible`. This lets you call an enum and get back a fully configured request object. Although, it's up to you to programmatically set the URL, verb, POST parameters, timeouts, tokens, etc. 

Besides the [AlamoFire documentation](https://github.com/Alamofire/Alamofire#urlrequestconvertible), this [Ray Wenderlich tutorial](http://www.raywenderlich.com/85080/beginning-alamofire-tutorial) is a good resource to learn more.  

Let's examine the simplest example to see how it works.

```
enum Router: URLRequestConvertible {
    case FetchTopFree()
    var URLRequest: NSURLRequest {
        // verbs, URLs, and params
        let (verb: String, path: String, parameters: [String: AnyObject]?) = {
            switch self {
            case .FetchTopFree():
                return ("GET", "https://itunes.apple.com/us/rss/topfreeapplications/limit=10/json", nil)
            }
        }()
        // creating the request.
        // set the verb and URL.
        // also set headers here too.
        let URL = NSURL(string: path)!
        let URLRequest = NSMutableURLRequest(URL: URL)
        URLRequest.HTTPMethod = verb
        // encode the params
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

The nice thing about using a tuple with the `switch` statement is that the syntax stays tight even as you add more API endpoints.

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

The Router seems a little daunting at first.  But once you have the basic structure in place, it's pretty easy to add additional API calls.  This setup is scalable because there's a single point of change should you need to add auth tokens or set a `timoutInterval`.

### [JSON Serialization](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/networkMashup/RouterService.swift#L98)

Handling JSON objects with Swift can get pretty ugly, but SwiftyJSON makes life much easier.  Here's a good [tutorial if you want to learn more](http://www.raywenderlich.com/82706/working-with-json-in-swift-tutorial).

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

One neat trick with SwiftyJSON is the ability to turn a Swift dictionary into stringified JSON, which comes in handy for multipart. [See Example](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/networkMashup/RouterService.swift#L98)

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

Also, don't forget to add some [safety checks](https://github.com/ThornTechPublic/SwiftNetworkStarterKit/blob/master/networkMashup/RouterService.swift#L247) to `UIImage`.  Since `UIImage` is not thread-safe, it will intermittently crash as you convert an incoming barrage of image requests.

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

Say you need to upload both image and text in a single API call.  You can't really mix binary with text, so one approach is to go all-text.  This means converting the image into a huge base64 string (a picture is worth a thousand words...).  This approach is limited, depending on the server's maximum POST size. 

The alternative is to use Multipart, which requires everything to be in binary.  This means all the headers and form data need to be converted to binary.  We included a working example of using Multipart with AlamoFire.  

The multipart HTTP body has different "parts" to it:

```
{
    files : {
        file : "data:image/jpg;base64,/9j/4AAQ...2Q=="
    },
    form : {
        payload : "{ 
            \"foo\":\"bar\"
        }"
    },
    args : {},
    json : null
}
```

To put the image binary inside of `files`, use the `fileData` parameter:

```
multipartFormData.appendBodyPart(fileData: imageData, name: "file", fileName: "iosFile.jpg", mimeType: "image/jpg")
```

For the JSON payload, we need to perform some conversions before appending the body part.  First use SwiftyJSON to convert a dictionary to JSON.

```
var parameterJSON = JSON([
    "title": "foo",
    "description": "bar"
])
```

Then stringify the JSON:

```
let parameterString = parameterJSON.rawString(encoding: NSUTF8StringEncoding, options: nil)
```

Now convert the string to binary:

```
let jsonParameterData = parameterString!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
```

Finally, add the JSON as a `file`:

```
multipartFormData.appendBodyPart(fileData: jsonParameterData!, name: "goesIntoFile", fileName: "json.txt", mimeType: "application/json")
```

Or depending on how your API endpoint is setup, insert the JSON into the `form`:

```
multipartFormData.appendBodyPart(data: jsonParameterData!, name: "goesIntoForm")
```
