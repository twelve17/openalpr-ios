# This file was mooched from the equivalent one used in the OpenCV project: 
# https://github.com/Itseez/opencv/tree/master/platforms/ios 
# 
message (STATUS "Setting up iPhoneOS toolchain")
set (IPHONEOS TRUE)

set(CMAKE_MACOSX_BUNDLE YES)

# https://public.kitware.com/Bug/view.php?id=15329
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO")
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Don't Code Sign")

# Standard settings
# Include extra modules for the iOS platform files
set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../distros/ios/cmake/Modules")
set (CMAKE_SYSTEM_NAME iOS)

message (STATUS "CMAKE_CURRENT_SOURCE_DIR: ${CMAKE_CURRENT_SOURCE_DIR}")
message (STATUS "CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}")

# Force the compilers to clang for iOS
include (CMakeForceCompiler)
#CMAKE_FORCE_C_COMPILER (clang GNU)
#CMAKE_FORCE_CXX_COMPILER (clang++ GNU)

set (CMAKE_C_SIZEOF_DATA_PTR 4)
set (CMAKE_C_HAS_ISYSROOT 1)
set (CMAKE_C_COMPILER_ABI ELF)
set (CMAKE_CXX_SIZEOF_DATA_PTR 4)
set (CMAKE_CXX_HAS_ISYSROOT 1)
set (CMAKE_CXX_COMPILER_ABI ELF)

# Skip the platform compiler checks for cross compiling
set (CMAKE_CXX_COMPILER_WORKS TRUE)
set (CMAKE_C_COMPILER_WORKS TRUE)

# Search for programs in the build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
#   for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

message (STATUS "iPhoneOS toolchain loaded")
