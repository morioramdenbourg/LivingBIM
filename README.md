# LivingBIM

LivingBIM is an iOS application to collect data by connecting a range camera mounted to an iPad Air 2 using the structure.io SDK. The application uses that data to create vivid 3D models of the world, which can be stored and analyzed.

A brief description of the project and each view within the application can be found [here](https://github.com/morioramdenbourg/LivingBIM/raw/master/Resources/Part-Time_iOS_developer_position_advert_Civil_Engineering_Department.pdf).

Additionally, the documentation for structure.io is found [here](https://github.com/morioramdenbourg/LivingBIM/blob/master/Structure%20SDK/Reference/html/index.html).

## Getting Started

The structure.io SDK has already been bridged via XCode and the environment has already been configured. To use this application, CocoaPods is required. CocoaPods is a dependency manager for Swift and Objective-C, which we use to install dependencies such as the Box API and Kanna, to parse HTML. The installation instructions for CocoaPods can be found on their [documentation](https://cocoapods.org/).

After installing cocoapods, install all of our dependencies using the following command:

    $ pod install

As a note, from now be sure to always open the project using **LivingBIM.xcworkspace**.

To run the app, simply press the "Run" button on the top left corner after opening the application. There may be several warnings while building due to the third-party libraries, but that is normal.

A working knowledge of Swift and Objective-C would greatly assist in understanding, and contributing to this project.

## How it works

Our app has an intuitive yet basic main UI for the user to decide which type of scan they would like to collect. The logic for the home screen, including user navigation, user-specific data collection, and peripheral sensor data collection, can be found in [HomeViewController.swift](https://github.com/morioramdenbourg/LivingBIM/blob/master/LivingBIM/LivingBIM/Home/HomeViewController.swift). The home screen controller logic integrates itself with the native iOS sensor APIs, which can be set and configured at [AppDelegate.swift](https://github.com/morioramdenbourg/LivingBIM/blob/master/LivingBIM/LivingBIM/AppDelegate.swift). The two main sensor APIs we used were [CLLocationManager](https://developer.apple.com/documentation/corelocation/cllocationmanager) and [CMMotionManager](https://developer.apple.com/documentation/coremotion/cmmotionmanager). [CaptureCollectionViewController.swift](https://github.com/morioramdenbourg/LivingBIM/blob/master/LivingBIM/LivingBIM/Home/CaptureCollectionViewController.swift) creates the cells that are displayed on the home screen, which contains each scan that has been taken. The logic contained here also sets up Core Data, the iOS internal database we used to store our scans, along with Box and a multitude of other settings. Finally, this controller performs the Box upload, by iterating through the scans collected in Core Data.

The first scanning option, capturing a single frame, combines the native device camera with the range camera, using the provided API within structure.io. The code to perform this is located in this [view controller](https://github.com/morioramdenbourg/LivingBIM/blob/master/LivingBIM/LivingBIM/Capture/Frame/CaptureFrameViewController.swift). An important method is [sensorDidOutputSynchronizedDepthFrame()](https://github.com/morioramdenbourg/LivingBIM/blob/master/LivingBIM/LivingBIM/Capture/Frame/CaptureFrameViewController.swift#L213), which takes in both the device camera input and range camera input for a single frame, and creates a Scan object, which is stored in Core Data. To learn more about how Core Data works, look at the Useful Links below.

The second scanning option, capturing an entire model, which is much more complex, uses the code within Sample Code provided by the structure.io developers. I integrated this code within our project by creating a "Model" directory under the "Captures" directory, which basically points to the sample code [here](https://github.com/morioramdenbourg/LivingBIM/tree/master/Structure%20SDK/Samples/RoomCapture). The code that structure.io provided had  the functionality we needed for our use cases. Instead of rewriting the complex math and logic, we decided to modify this code for our own purposes. However, this code was all written in Objective-C. I created a wrapping class, called [Wrapper.mm](https://github.com/morioramdenbourg/LivingBIM/blob/master/LivingBIM/LivingBIM/Util/Wrapper.mm), which creates a ViewController object for the model scan. This Wrapper class is then called inside HomeViewController.swift, whenever the user navigates to the model scan. This was necessary since the model scanning code used c++ code, which did not easily bridge to Swift. After a scan is fully created, the logic within [MashViewController.mm](https://github.com/morioramdenbourg/LivingBIM/blob/master/Structure%20SDK/Samples/RoomCapture/MeshViewController.mm) goes and stores the entire scan to Core Data. Throughout the scanning process, each frame is stored in Core Data as well, in the [ViewController+Sensor.mm](https://github.com/morioramdenbourg/LivingBIM/blob/master/Structure%20SDK/Samples/RoomCapture/ViewController%2BSensor.mm) file. I changed the original email functionality to have it perform these actions.

Lastly, the Help and Set Locations page changes the metadata that will be stored in the scan. The list of locations was found by scraping the [UT Buildings List](https://facilitiesservices.utexas.edu/buildings/), using the third-party library [Kanna](https://github.com/tid-kijyun/Kanna). The user-specific information is stored in UserDefaults. A tutorial for UserDefaults can be found [here](https://developer.apple.com/documentation/foundation/userdefaults).

## Important Files (Modify These)

* [**HomeViewController.swift**](https://github.com/morioramdenbourg/LivingBIM/blob/master/LivingBIM/LivingBIM/Home/HomeViewController.swift) - Performs the overarching logic to navigate, collect data, upload the data, and perform basic user queries
* [**Settings.swift**](https://github.com/morioramdenbourg/LivingBIM/blob/master/LivingBIM/LivingBIM/Settings/Settings.swift) - Performs the logic that gets and stores user specific information, such as username, location, box credentials, etc.
* [**CaptureFrameViewController.swift**](https://github.com/morioramdenbourg/LivingBIM/blob/master/LivingBIM/LivingBIM/Home/CaptureCollectionViewController.swift) - Single frame capture and storage
* [**MeshViewController.mm**](https://github.com/morioramdenbourg/LivingBIM/blob/master/Structure%20SDK/Samples/RoomCapture/MeshViewController.mm) - Converts the mesh and model into a zip file, and stores it to disk
* [**ViewController+Sensor.mm**](https://github.com/morioramdenbourg/LivingBIM/blob/master/Structure%20SDK/Samples/RoomCapture/ViewController%2BSensor.mm) - Sensor input for model scanning, process each frame and render the view
* [**Constants.swift**](https://github.com/morioramdenbourg/LivingBIM/blob/master/LivingBIM/LivingBIM/Util/Constants.swift) - Bunch of constants, such as key names stored in UserDefaults and CoreData, and default values for the tables
* [**Extensions.swift**](https://github.com/morioramdenbourg/LivingBIM/blob/master/LivingBIM/LivingBIM/Util/Extensions.swift) - Admittedly, this was a hack, but I wrote this to pretty much write code that was more tedious to write in Objective-C in Swift. It basically does all the heavy-lifting, such as converting types, and processing each frame and storing it into Core Data. It also performs the process of processing the model once its created. As a result, this module is quite loaded, and consequently is one of the bottlenecks of this application. If I had the chance to rewrite a piece of code in this application, it would definitely be this module. I would most likely convert some of these functions to Objective-C, to better use the API provided, and most likely find a different storage format, rather than Core Data, which was strained and limited by the amount of data that was coming in.

## Authors

* **Morio Ramdenbourg** - [Github](https://github.com/morioramdenbourg)
* **Thomas Czerniawski** - [Github](https://github.com/Tcmbot)

See also the list of [contributors](https://github.com/morioramdenbourg/LivingBIM/contributors) who participated in this project.

## Acknowledgments

Useful Links:
* [Structure Viewer](https://github.com/ponderousmad/StructureViewerSwift) (What I based my code off of)
* [CocoaPods](https://cocoapods.org/)
* [Swift Tour](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/GuidedTour.html)
* [CLLocationManager](https://developer.apple.com/documentation/corelocation/cllocationmanager)
* [CMMotionManager](https://developer.apple.com/documentation/coremotion/cmmotionmanager)
* [Core Data Tutorial](https://www.raywenderlich.com/173972/getting-started-with-core-data-tutorial-2)
* [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)
* [Kanna](https://github.com/tid-kijyun/Kanna)
* [UIImage to CMSampleBuffer Conversion in Extensions.swift](https://stackoverflow.com/questions/16475737/convert-uiimage-to-cmsamplebufferref)
* [Box iOS SDK Documentation](https://github.com/box/box-ios-sdk)
* [Alamofire](https://github.com/Alamofire/Alamofire)
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)