openalpr-ios
============

Xcode Framework for the openalpr library

## Dependency Installation

Run the `./bin/sync_openalpr_source.sh` script.

- Uses OpenCV CocoaPod instead of iOS version from OpenCV site.
- Requires Tesseract 3.03

## Creating the XCode Project From Scratch

- Get openalpr source:
  ```
  git clone https://github.com/openalpr/openalpr.git openalpr
  ```

- Create Project
  - Framework & Library -> Cocoa Touch Static Library 
    - Product Name: openalpr-xcode
  - Save under openalpr-ios folder.
  - Delete openalpr_xcode.h and openalpr_xcode.m (move to trash)
  
- From the top level git folder, run the `sync_openalpr_source.sh` script:
  ```
    ./bin/sync_openalpr_source.sh ~/work/lp/openalpr -n
  ```

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

  - openalpr-xcode -> Targets -> openalpr -> Build Phases
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



