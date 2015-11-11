openalpr-ios
============

A Ruby script that builds an Xcode project and a universal iOS static library framework for the [openalpr](https://github.com/openalpr/openalpr) library.  *As of this writing, this project is compatible with the 2.2.x release of OpenALPR and later.*

Running the script will:

- Download the OpenCV 3.0.0 framework binary release and symlink the headers directory so that the OpenALPR code will see them.
- Download and build universal Tesseract 3.03, Leptonica 1.71, and OpenALPR static library framework bundles from source.
- Generate a OpenALPR Xcode project

## Requirements

- Mac OS X
- Ruby 2.1.x
  - [osx-plist](https://github.com/kballard/osx-plist) Ruby gem
- Xcode and command line tools.  Tested with Xcode 7.1.
- curl, tar, unzip, git (seems to be installed by default on OS X)

As of this writing, the latest openalpr commit on the master branch was `eecd41e097534f84e2669da24d4aed4bf75a1132`

## Installation

- Clone this module:

  ```
  # git clone git@github.com:twelve17/openalpr-ios.git
  ```

- Run the `./bin/build_frameworks.rb` script.  By default, it will put all the frameworks under a subdirectory called `output`.  You can  pass an alternate path with the `-d` option.  Intermediate files are kept under the `work` subdirectory, including a log called `build.log` which you can inspect for errors.

## Usage 

### Bitcode

Because the OpenCV binary framework release is compiled without bitcode, the other frameworks built by this script are also built without it, which ultimately means your Xcode project  also cannot be built with bitcode enabled.  [Per this message](http://stackoverflow.com/a/32728516/868173), it sounds like we want this feature disabled for OpenCV anyway.  

To disable bitcode in your project:

- In `Build Settings` → `Build Options`, search for `Enable Bitcode` and set it to `No`.   

### Linking To Frameworks

- In Xcode, open your project.  Then go to `Add Files` and add all four frameworks (leptonica, opencv, tesseract, openalpr) from the `output` directory.  Use the `Copy items if needed` option.  This should cause the project to add a framework search path to the project's build settings (e.g. `$(PROJECT_DIR)`).  
- Ensure that all four frameworks are included in the `Link Binary With Libraries` build phase.
- The alpr library requires a config file (`openalpr.conf`) and a data folder (`runtime_data`), both of which are included in the framework, but must be copied to the application resources:
  - Select your project on the project navigator, then, on the main pane, go to `Targets` → `<Your Project>` → `Build Phases` → `Copy Bundle Resources`, and click on the `+`.  
  - Select `Add Other...`
  - Browse *into* the `openalpr.framework` bundle, and command-select both `runtime_data` and `openalpr.conf`.  Unselect `Copy items if needed` and select `Create folder references`.

## AlprSample App

You can use the `AlprSample` app included in this project to test your installation.  It has one view that simply presents a fixed (pre-selected) license place image, and a table view below it showing scanned plate values for that image.

To run the app, you will need to build the frameworks with `build_frameworks.rb`.  Then, in Xcode, open the project and follow these steps:

1. Find a plate image file you wish to test with and add it to the project.  
2. Edit `ViewController.mm` and change the value of `plateFilename` to the name of the file you added in step 1, e.g. `NSString *plateFilename = @"license_plate.jpg";`
3. Link the project to the dependency frameworks and add the required resources per the "Linking To Frameworks" section above.

## Misc Notes

### Dynamic Library?

I initially attempted to build dynamic libraries, since they are supported as of iOS 9.  It required me to update the `rpath` of the dynamic libraries.  Then the frameworks must be embedded into the application.  However, even after doing that, I ran into odd run-time errors where the libopenalpr.dylib library could not load the statedetection library.  PRs welcome!

### AlprSample Creation

Steps for creating the app are kept here for posterity.

- Create New Project
  - `iOS` → `Application` → `Single View Application`
  - Product Name: `AlprSample`
- You should end up with a project which contains, among other things, a `ViewController.h` and `ViewController.m` class.  Rename the `.m` class to `ViewController.mm` (two m's).  This causes Xcode to compile the class as "Objective-C++", which we need, as the openalpr code is in C++.
- Disable bitcode per the "Bitcode" section above.
- Link the project to the dependency frameworks and add the required resources per the "Linking To Frameworks" section above.

### Tips

- [Viewing iOS device logs](http://stackoverflow.com/a/31379741/868173)
- Viewing symbols in library:
  `nm -gUj  openalpr.framework/Libraries/libopenalpr-static.a | c++filt`
- [Seeing errors in Simulator](http://stackoverflow.com/a/26129829/868173):
  `tail -f ~/Library/Logs/CoreSimulator/*.log`
- clean up temporary Xcode items

   ```
    rm -rf "$(getconf DARWIN_USER_CACHE_DIR)/org.llvm.clang/ModuleCache"
    rm -rf ~/Library/Developer/Xcode/DerivedData
    rm -rf ~/Library/Caches/com.apple.dt.Xcode
    ```


## Credits

- Tesseract and Leptonica install code based [on this script](http://tinsuke.wordpress.com/2011/11/01/how-to-compile-and-use-tesseract-3-01-on-ios-sdk-5/).
- iOS.cmake toolchain file based [on this one](https://github.com/cristeab/ios-cmake/blob/master/toolchain/iOS.cmake).

