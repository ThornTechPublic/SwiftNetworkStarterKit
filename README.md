# Network Starter Kit for Swift

This is a sample project that integrates some popular libraries and useful networking features.  Honestly, a lot of this is taken straight from the [AlamoFire](https://github.com/Alamofire/Alamofire) README, but sometimes it helps to see code snippets in the context of a sample project.  Feel free to use this as a starter template.

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
