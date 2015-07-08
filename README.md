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

### Image Caching

### Multipart POST


