require 'fileutils'
require 'logger'
require_relative 'core_build'
require_relative 'utils'

module Alpr
  class CocoaPodsBuild < CoreBuild

    PUBLIC_HEADERS_PREFIX = '${PODS_ROOT}/Headers/Public'
    OPENCV_PREFIX = 'OpenCV'

    OPENCV_HEADERS =  [
      "",
      "opencv2",
      "opencv2/calib3d",
      "opencv2/contrib",
      "opencv2/core",
      "opencv2/features2d",
      "opencv2/flann",
      "opencv2/highgui",
      "opencv2/imgproc",
      "opencv2/legacy",
      "opencv2/ml",
      "opencv2/nonfree",
      "opencv2/objdetect",
      "opencv2/photo",
      "opencv2/stitching",
      "opencv2/stitching/detail",
      "opencv2/video",
      "opencv2/videostab",
      "opencv2/world"
    ].map { |x| x.empty? ? OPENCV_PREFIX : File.join(OPENCV_PREFIX, x) }

    OTHER_HEADERS = [ "" ]

    PUBLIC_HEADERS = (OTHER_HEADERS + OPENCV_HEADERS).map do |x|
      '"' +
        (x.empty? ? PUBLIC_HEADERS_PREFIX : File.join(PUBLIC_HEADERS_PREFIX, x)) +
        '"'
    end

    def get_cmake_args(target)
      super(target).push(
        "-DOPENALPR_DEP_COCOA_PODS_PATH=#{self.dest_root}/Pods"
      )
    end

    def build_deps(build_dir, target, arch)

      xcodeproj_file = File.join(build_dir, "src.xcodeproj/project.pbxproj")

      #log_execute("xcproj touch")

      # Install Tesseract and OpenCV CocoaPods
      #    if !File.exist?(File.join(build_dir, 'Podfile'))
      FileUtils.cp(File.join(CONFIG_DIR, 'Podfile'), build_dir)
      #      log_execute('pod install')
      #    end


      FileUtils.cp(xcodeproj_file, "#{xcodeproj_file}.orig")
      Alpr::Xcode.rewrite_project_file!(
        xcodeproj_file,
        self.alpr_src_dir,
        target,
        IOS_DEPLOY_TGT,
      )

      #log_execute("xcodebuild IPHONEOS_DEPLOYMENT_TARGET=#{IOS_DEPLOY_TGT} -parallelizeTargets ARCHS=#{arch} -jobs 8 -sdk #{target.downcase} -configuration Release -target cocoapod_setup")
      log_execute("xcodebuild IPHONEOS_DEPLOYMENT_TARGET=#{IOS_DEPLOY_TGT} ARCHS=#{arch} -sdk #{target.downcase} -configuration Release -target cocoapod_setup")


      #FileUtils.ln_s(File.join(build_dir, 'Pods', 'OpenCV','opencv2.framework','Headers/'), File.join(alt_headers_path, 'opencv2'))
      #FileUtils.ln_s(File.join(build_dir, 'Pods', 'TesseractOCRiOS','TesseractOCR','include'), File.join(alt_headers_path, 'opencv2'))
    end

    #  "constructs the framework directory after all the targets are built"
    def self.put_framework_together(srcroot, dstroot)

      # find the list of targets (basically, ["iPhoneOS", "iPhoneSimulator"])
      targetlist = Dir[(File.join(dstroot, "build", "*"))].map { |t| File.basename(t) }

      # set the current dir to the dst root
      currdir = FileUtils.pwd()
      framework_dir = dstroot + "/openalpr.framework"
      if File.directory?(framework_dir)
        FileUtils.rm_rf(framework_dir)
        FileUtils.mkdir_p(framework_dir)
        FileUtils.cd(framework_dir)

        # form the directory tree
        dstdir = "Versions/A"
        FileUtils.mkdir_p(dstdir + "/Resources")

        tdir0 = "../build/" + targetlist[0]
        # copy headers
        FileUtils.cp_r(tdir0 + "/install/include/openalpr", dstdir + "/Headers")

        # make universal static lib

        wlist = targetlist.map { |t| "../build/" + t + "/lib/Release/libopencv_world.a"  }.join(" ")
        #wlist = " ".join(["../build/" + t + "/lib/Release/libopencv_world.a" for t in targetlist])
        log_execute("lipo -create " + wlist + " -o " + dstdir + "/openalpr")

        # copy Info.plist
        FileUtils.cp(tdir0 + "/ios/Info.plist", dstdir + "/Resources/Info.plist")

        # make symbolic links
        FileUtils.ln_s("A", "Versions/Current")
        FileUtils.ln_s("Versions/Current/Headers", "Headers")
        FileUtils.ln_s("Versions/Current/Resources", "Resources")
        FileUtils.ln_s("Versions/Current/openalpr", "openalpr")
      end
    end

  end

end
