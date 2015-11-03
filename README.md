openalpr-ios
============

A Ruby script that builds an Xcode project and a universal iOS static library framework for the [openalpr](https://github.com/openalpr/openalpr) library.  *As of this writing, this project is compatible with the github branch of OpenALPR, not the last 2.x release.*

Running the script will:

- Download the OpenCV 3.0.0 framework binary release.
- Dwonload and build universal Tesseract 3.03, Leptonica 1.71, and OpenALPR static library framework bundles from source.
- Generate a OpenALPR Xcode project

## Requirements

- Mac OS X
- Ruby 2.1.x
  - [osx-plist](https://github.com/kballard/osx-plist) Ruby gem
- Xcode and command line tools.  Tested with Xcode 7.1.
- curl (seems to be installed by default on OS X)

## Installation

- Clone this module:

  ```
  # git clone git@github.com:twelve17/openalpr-ios.git
  ```

- Run the `./bin/build_frameworks.rb` script.  By default, it will put all the frameworks under a subdirectory called `output`.  You can  pass an alternate path with the `-d` option.  Commands are logged to `work/build.log`.  Intermediate files are kept under the `work` subdirectory.

## Usage 

### Xcode Linking To Frameworks

- In the Xcode project, select the `Frameworks` folder.  Then go to `Add Files` and add all four frameworks (leptonica, opencv, tesseract, openalpr) from the `output` directory.  Use the `Copy items if needed` option.  This should cause the project to add a framework search path to the project's build settings (e.g. `$(PROJECT_DIR)/YourProject`).  
- Ensure that all four frameworks are included in the `Link Binary With Libraries` build phase.
- The alpr library requires a config file (`openalpr.conf`) and a data folder (`runtime_data`), both of which are included in the framework, but must be configured to be copied to the application resources on the target.  Therefore, for each of these two, go to `Add Files` again, browse *into* the `openalpr.framework` bundle, and select each item.  Since these items are going to be copied into the app target, you can unselect `Copy items if needed`, and select `Create folder references`.
- In the build settings, under `Build Options`, search for `Enable Bitcode` and set it to `No`.  This is needed because the opencv2 binary release is compiled without bitcode, and therefore the other frameworks built by this script are also built without it, which ultimately means the Xcode project codebase also cannot be built with bitcode enabled.

  - As of this writing, the latest openalpr commit on the master branch was `eecd41e097534f84e2669da24d4aed4bf75a1132`

## Using the Xcode Project In Your Own Project

- Go to `<Your Project>` → `Targets` → `<Project>` → `Build Settings`
  - Under `Header Search Paths`, add:
  `/<path_to>/output/openalpr.framework/include/openalpr`

- In your project, create a group called `Resources`, below the root node.
  - While having the `openalpr-xcode` project open, browse to `Products`, then drag the `libopenalpr-xcode.a` library to your own project, into the `Resources` group created above.  This should cause a few other things to happen, but you should confirm this:
  - Under `<Your Project>` → `Targets` → `<Project>` → `Build Settings`
    - `Library Search Paths` should now have an entry that looks something like this:
      `$(USER_LIBRARY_DIR)/Developer/Xcode/DerivedData/openalpr-xcode-ddcvnkuwwembihfiemhmlsqzmnar/Build/Products/Debug-iphoneos`
    - `Link Binary With Libraries` should now have `libopenalpr-xcode.a`.


## Creating the XCode Project From Scratch

- Create Project
  - `Framework & Library` → `Cocoa Touch Static Library`
    - Product Name: `openalpr-xcode`
  - Save under the `openalpr-ios` folder.
  - Delete `openalpr_xcode.h` and `openalpr_xcode.m` (move to trash)
  
- On the left pane, select the `openalpr-xcode` group.
- Go to `File` → `Add files to "openalpr-xcode"`
  - Browse to `/<path_to>/openalpr-ios/openalpr-xcode/openalpr`
  - Select all items in that folder (main.cpp, etc.)
    - Uncheck `Copy items if needed`
    - Under `Added folders`, select `Create groups`

- Quit XCode 

- Create a Podfile on the openalpr-xcode folder:
  ```
platform :ios, '8.1'

source 'https://github.com/CocoaPods/Specs.git'

pod 'OpenCV'
  ```

- Install the CocoaPods  
  ```
  # cd openalpr-xcode
  # pod install
  ```

- Re-open XCode as suggested by the CocoaPod docs:
  ```
  # open openalpr-xcode.xcworkspace
  ```

- Remove `openalpr-xcodeTests` target by selecting it, then selecting the - at the bottom of the panel.

- Add search path for `openalpr` headers within the Project, as well as 
  `tesseract` and `leptonica` headers.
  - openalpr-xcode -> Targets -> openalpr-xcode -> Build Settings 
  - Search Paths -> Header Search Paths, add: 
    - `$(PROJECT_DIR)/openalpr` (recursive)
    - `$(PROJECT_DIR)/../work/dependencies/include/` (non-recursive)

- Add target for building framework.   Select 'openalpr-xcode' on the navigation panel.  
  - Click on the + at the bottom of the right panel to add a new target.
    - Select iOS -> Framework & Library -> Cocoa Touch Framework
      - Product Name: `openalpr`
      - Select `Finish`
  - The above framework creates an additional `openalprTests` target.  Remove it by selecting the - at the bottom of the panel.


- Browse to `openalpr-xcode` -> `Targets` -> `openalpr` -> `Build Phases`
  - Add libraries to include in the Framework target:
    - `Target Dependencies`, add: `openalpr-xcode` (static library target)
    - `Headers`:  
      - Remove `openalpr.h` by pressing the `-` sign 
      - Add `openalpr/alpr.h` by dragging it from the navigator.
    - `Link Binary With Libraries`
      - `Add Other`.  
      - Browse to `openalpr-ios/work/dependencies/lib`.  
      - Add `libtesseract.a` and `liblept.a`.


- Build library 
  - Select the openalpr-xcode Library from the drop down to the right of the "Play" and "Stop" icons on the top toolbar, left side.
  - Press command-B to build.  Under Products, the libopenalpr-xcode.a should have turned from red to black.
  - Select the openalpr Framework from the drop down to the right of the "Play" and "Stop" icons on the top toolbar, left side.
  - Press command-B to build.  Under Products, the libopenalpr-xcode.a should have turned from red to black.

### TODO

TODO: - Add Info.plist file to openalpr (Framework) target.
TODO: - Set installation directory in openalpr (Framework) target.
 - from /Library/Frameworks to @loader_path/../Frameworks/ 
 - skip install - no?

xxxxx  - openalpr-xcode -> Targets -> openalpr -> Build Phases
  - Link Binary With Libraries, add: 
    - `openalpr-xcode.a`
    - `$(PROJECT_DIR)/openalpr` (recursive)
    - `$(PROJECT_DIR)/../work/dependencies/include/` (non-recursive)


Tips
======

- [Viewing iOS device logs](http://stackoverflow.com/a/31379741/868173)
- Viewing symbols in library:
nm -gUj  openalpr.framework/Libraries/libopenalpr-static.a | c++filt | less
- Seeing errors in Simulator: tail -f ~/Library/Logs/CoreSimulator/*.log http://stackoverflow.com/a/26129829/868173

# clean up xcode problems
rm -rf "$(getconf DARWIN_USER_CACHE_DIR)/org.llvm.clang/ModuleCache"
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode
