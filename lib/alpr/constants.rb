require_relative 'utils'

module Alpr
  module Constants
    extend Utils # needed for class level calls to execute

    PROJECT_ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    CONFIG_DIR = File.join(PROJECT_ROOT_DIR, 'etc')

    AR = xcfind("ar")

    IOS_BASE_SDK="9.0"
    IOS_DEPLOY_TGT="9.0"

    XCODE_CONFIGURATION = "Release"

    CMAKE_IOS_PLATFORMS = {
      "armv7" => "OS",
      "armv7s" => "OS",
      "arm64" => "OS",
      "i386" => "SIMULATOR",
      "x86_64" => "SIMULATOR64"
    }

    BUILD_TARGETS = {
      "armv7" => "iPhoneOS",
      "armv7s" => "iPhoneOS",
      "arm64" => "iPhoneOS",
      "i386" => "iPhoneSimulator",
      "x86_64" => "iPhoneSimulator"
    }

  end
end
