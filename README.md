openalpr-ios
============

Xcode Framework for the [openalpr](https://github.com/openalpr/openalpr) library.

Because openalpr requires Tesseract 3.03, and, as of this writing, that version has not been released yet, it means that we cannot yet use the Tesseract [CocoaPod](http://cocoapods.org).  Instead, this module includes a bash script (based on [this one](http://stackoverflow.com/questions/12849517/c-linking-problems-seems-like-i-cant-link-against-standard-c-stuff)) that will compile universal Tesseract 3.03 and Leptonica 1.71 libraries, which can then be used to compile/link openalpr for iOS.

It *used to be* that getting openalpr working on iOS required that both OpenCV and Tesseract needed to be compiled with libstdc++ instead of libc++.  **This is no longer the case.** OpenCV has more recently begun to be built with libc++, so it is possible to use it across the dependencies and in openalpr. (It *does* remain a requirement that the same library is used for all dependencies and openalpr.)

The basic steps to getting openalpr configured on XCode are:

- Clone this module, which includes a template XCode project for a openalpr library and Cocoa Touch Framework.
- Run a script to build the dependencies
- Configure your own XCode project that will use the openalpr Cocoa Touch Framework.

## Steps in Detail

- Get openalpr source:
  ```
  git clone https://github.com/openalpr/openalpr.git openalpr
  ```

- Clone this module:
  ```
  # git clone git@github.com:twelve17/openalpr-ios.git
  ```

- From the top level `openalpr-ios` git folder, run the `sync_openalpr_source.sh` script, passing the path to whereyou cloned openalpr:
  ```
    ./bin/sync_openalpr_source.sh ~/work/lp/openalpr -n
  ```
 This script will do the following:
 - Copy openalpr sources and headers to `openalpr-ios/openalpr-xcode/openalpr`, for use by the XCode project.
 - Copy openalpr headers (only) to `openalpr-ios/work/dependencies/include/openalpr`, for use by your own XCode iOS application project.
 - Copy openalpr `runtime_data` folder to `openalpr-ios/work/dependencies/share/openalpr`, for use by your own XCode iOS application project.



This will compile iOS compatible versions of Leptonica and Tesseract to the prefix `openalpr-ios/work/dependencies`


- Open the openalpr-ios/openalpr-xcode XCode project.  
  - As of this writing, openalpr revision 904ff09fa78f9577c9dfde677c600c5cf38d1c66 required me to make a couple of manual changes:
    1. Fix a couple of syntax-error lines in [ocr.cpp](https://github.com/openalpr/openalpr/blob/904ff09fa78f9577c9dfde677c600c5cf38d1c66/src/openalpr/ocr.cpp).
    2. Create a file called `version.h` in the `openalpr` folder (in same folder  `main.cpp` is in) to set a few variables that are required.  This module [includes a copy](https://github.com/twelve17/openalpr-ios/blob/master/etc/version.h) you can use.  The version numbers may be wrong on this file, so feel free to fix them.






- Uses OpenCV CocoaPod instead of iOS version from OpenCV site.
- Requires Tesseract 3.03

## Creating the XCode Project From Scratch



- Create Project
  - Framework & Library -> Cocoa Touch Static Library 
    - Product Name: openalpr-xcode
  - Save under openalpr-ios folder.
  - Delete openalpr_xcode.h and openalpr_xcode.m (move to trash)
  


- On the left pane, select the 'openalpr-xcode' group.
- File -> Add files to "openalpr-xcode"
  - Browse to /path/to/openalpr-ios/openalpr-xcode/openalpr
  - Select all items in that folder (main.cpp, etc.)
    - Uncheck 'Copy items if needed'
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

- Add search path for openalpr headers within the Project, as well as 
  tesseract and leptonica headers.
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


- Add libraries to include in the Framework target.
  - openalpr-xcode -> Targets -> openalpr -> Build Phases
    - Target Dependencies, add: `openalpr-xcode` (static library target)

- Add alpr.h header as public.
  - openalpr-xcode -> Targets -> openalpr -> Build Phases
    - Headers  
      - Remove 'openalpr.h' by pressing the - sign 
      - Add 'openalpr/alpr.h' by dragging it from the navigator.

TODO: - Add Info.plist file to openalpr (Framework) target.
TODO: - Set installation directory in openalpr (Framework) target.
 - from /Library/Frameworks to @loader_path/../Frameworks/ 
 - skip install - no?

- Add Tesseract and Leptonica libraries.
  - openalpr-xcode -> Targets -> openalpr -> Build Phases
    - Link Binary With Libraries
      - Add Other.  Browse to openalpr-ios/work/dependencies/lib
      - Remove 'openalpr.h' by pressing the - sign 
      - Add 'openalpr/alpr.h' by dragging it from the navigator.


# TODO: this is not needed.  Only the library needs this, and they should already exist.  The framework should not compile any sources.
- Add sources to compile 
  - openalpr-xcode -> Targets -> openalpr -> Build Phases
  - Compile Sources.  Press the "plus" sign.  Shift click to select all sources under the openalpr folder, as well as the main.cpp class.

- Build library 
  - Select the openalpr-xcode Library from the drop down to the right of the "Play" and "Stop" icons on the top toolbar, left side.
  - Press command-B to build.  Under Products, the libopenalpr-xcode.a should have turned from red to black.
  - Select the openalpr Framework from the drop down to the right of the "Play" and "Stop" icons on the top toolbar, left side.
  - Press command-B to build.  Under Products, the libopenalpr-xcode.a should have turned from red to black.



xxxxx  - openalpr-xcode -> Targets -> openalpr -> Build Phases
  - Link Binary With Libraries, add: 
    - `openalpr-xcode.a`
    - `$(PROJECT_DIR)/openalpr` (recursive)
    - `$(PROJECT_DIR)/../work/dependencies/include/` (non-recursive)



- Pseudo Patches 
  - Create version.h 
  ``` 
#define OPENALPR_MAJOR_VERSION "1"
#define OPENALPR_MINOR_VERSION "2"
#define OPENALPR_PATCH_VERSION "0"
  ```

- Fix a few pointer bugs in ocr.cpp.



