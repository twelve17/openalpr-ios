# This is a Ruby port of this script:
#
# http://tinsuke.wordpress.com/2011/11/01/how-to-compile-and-use-tesseract-3-01-on-ios-sdk-5/
#
# It has been updated with the following:
# - amd64 build support
# - pointers to new locations of XCode toolchains
# - additional header files for Tesseract 3.03-rc1
#
# It was tested with iOS 8.0 base target, on Mavericks.

require 'fileutils'
require 'find'
require 'logger'
require 'osx/plist'
require_relative 'core_build'
require_relative 'utils'

module Alpr
  class ManualDepsBuild < CoreBuild

    XCODE_DEVELOPER = "/Applications/Xcode.app/Contents/Developer"
    XCODETOOLCHAIN = "#{XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain"
    SDK_IPHONEOS = qexec("xcrun --sdk iphoneos --show-sdk-path")
    SDK_IPHONESIMULATOR = qexec("xcrun --sdk iphonesimulator --show-sdk-path")

    BUILD_PLATFORMS=%w{i386 armv7 armv7s arm64 x86_64}

    TESSERACT_HEADERS = %w{
      api/apitypes.h api/baseapi.h
      ccmain/pageiterator.h ccmain/mutableiterator.h ccmain/ltrresultiterator.h ccmain/resultiterator.h
      ccmain/thresholder.h ccstruct/publictypes.h
      ccutil/errcode.h ccutil/genericvector.h ccutil/helpers.h
      ccutil/host.h ccutil/ndminx.h ccutil/ocrclass.h
      ccutil/platform.h ccutil/tesscallback.h ccutil/unichar.h
    }

    LEPTON_LIB="leptonica-1.71"
    LEPTON_LIB_URL="http://www.leptonica.org/source/#{LEPTON_LIB}.tar.gz"
    TESSERACT_LIB="tesseract-3.03"
    TESSERACT_LIB_URL='https://drive.google.com/uc?id=0B7l10Bj_LprhSGN2bTYwemVRREU&export=download'

    CXX = xcfind("c++")
    CC = xcfind("cc")
    LD = xcfind("ld")
    AS = xcfind("as")
    NM = xcfind("nm")
    RANLIB = xcfind("ranlib")

    protected

    def opencv_framework_version
      plist = OSX::PropertyList.load(File.read(File.join(self.opencv_framework_dir, 'Resources', 'Info.plist')))
      if plist['CFBundleVersion'].nil?
        raise "could not determine OpenCV version in framework: #{self.opencv_framework_dir}"
      end
      return plist['CFBundleVersion']
    end

    def alpr_cmake_args(target, arch)
       tess_include_dir = File.join(self.framework_headers_dir)

       target_dir = self.arch_build_dir(target, arch)

       tess_include_dirs = %w{
         Tesseract_INCLUDE_BASEAPI_DIR
         Tesseract_INCLUDE_CCSTRUCT_DIR
         Tesseract_INCLUDE_CCMAIN_DIR
         Tesseract_INCLUDE_CCUTIL_DIR
         Tesseract_INCLUDE_DIRS
         Tesseract_PKGCONF_INCLUDE_DIRS
       }.map do |k|
         "-D#{k}=#{tess_include_dir}"
       end
       super(target).concat(tess_include_dirs).concat(
         [
          "-DTesseract_LIB=#{File.join(target_dir, 'libtesseract_all.a')}",
          "-DLeptonica_LIB=#{File.join(target_dir, 'liblept.a')}",
          "-DOpenCV_IOS_FRAMEWORK_PATH=#{self.opencv_framework_dir}",
          "-DOpenCV_VERSION=#{self.opencv_framework_version}",
          "-DOpenCV_VERSION_MAJOR=#{self.opencv_framework_version[0]}",
        ]
      )
    end

    def build_alpr(target, arch)
      self.build_deps(target, arch)
      self.configure_alpr_build(target, arch)
      self.run_alpr_xcodebuild(target, arch)
    end

    #-----------------------------------------------------------------------------
    def build_deps(target, arch)
      if !self.built? || self.rebuild_deps
        self.download
        self.install_leptonica(target, arch)
        self.install_tesseract(target, arch)
        self.patch_opencv_framework!(target, arch)
      end
    end

    # the alpr codebase includes opencv libs with the path prefix 'opencv2'
    # (e.g. #include "opencv2/highgui/highgui.hpp").  we are going to create
    # a second folder within the opencv2 framework that will include this path,
    # linking back to the headers:
    # HeadersForAlpr/opencv2 -> Headers
    def patch_opencv_framework!(target, arch)
      headers_dir_for_alpr = File.join(self.opencv_framework_dir, 'HeadersForAlpr')
      if !File.directory?(headers_dir_for_alpr)
        FileUtils.mkdir(headers_dir_for_alpr)
      end

      link_target = File.join(headers_dir_for_alpr, 'opencv2')
      if !File.symlink?(link_target)
        puts "Adding opencv headers symlink: #{self.opencv_framework_headers_dir} -> #{link_target}"
        FileUtils.ln_s(self.opencv_framework_headers_dir, link_target)
      end
    end

    def opencv_framework_dir
      File.join(self.dest_dir, 'opencv2.framework')
    end

    def opencv_framework_lib_dir
      File.join(self.opencv_framework_dir, 'Versions', 'Current')
    end

    def opencv_framework_headers_dir
      File.join(self.opencv_framework_dir, 'Versions', 'Current', 'Headers')
    end

    #-----------------------------------------------------------------------------
    def leptonica_lib_dir
      File.join(self.work_dir, LEPTON_LIB)
    end

    #-----------------------------------------------------------------------------
    def tesseract_lib_dir
      File.join(self.work_dir, TESSERACT_LIB)
    end

    #-----------------------------------------------------------------------------
    def download
      FileUtils.cd(self.work_dir)

      if !File.exists?("#{self.work_dir}/#{LEPTON_LIB}.tar.gz")
        puts "Downloading leptonica library."
        log_execute("curl -o #{self.work_dir}/#{LEPTON_LIB}.tar.gz #{LEPTON_LIB_URL}")
      end
      if !File.directory?(self.leptonica_lib_dir)
        log_execute("tar -xvf #{self.work_dir}/#{LEPTON_LIB}.tar.gz")
      end

      if !File.exists?("#{self.work_dir}/#{TESSERACT_LIB}.tar.gz")
        puts "Downloading tesseract library."
        log_execute("curl -L -o #{self.work_dir}/#{TESSERACT_LIB}.tar.gz #{TESSERACT_LIB_URL}")
      end
      if !File.directory?(self.tesseract_lib_dir)
        log_execute("tar -xvf #{self.work_dir}/#{TESSERACT_LIB}.tar.gz")
      end

      [self.tesseract_lib_dir, self.leptonica_lib_dir].each do |src_dir|
        if !File.directory?(src_dir)
          raise "Missing source directory: #{src_dir}"
        end
      end
    end

    #-----------------------------------------------------------------------------
    def cleanup_source
      %w{clean distclean}.each { |t| log_execute("make #{t} || echo \"Nothing to #{t}\"") }
    end

    #-----------------------------------------------------------------------------
    def do_standard_build(target, arch, build_args)
      build_env = self.env_for_arch(target, arch)
      if build_env['BUILD_HOST_NAME']
        build_args.unshift("--host=#{build_env['BUILD_HOST_NAME']}")
      end
      log_execute("./configure #{build_args.join(' ')} && make -j12 2>&1", build_env)
    end

    #-----------------------------------------------------------------------------
    # Assuming all library files exist in all platform directories,
    # this function picks one directory as a template to build a list
    # of files to lipo together from all platform dirs, writing the
    # fat libraries to the framework Libraries folder.
    #
    # xcrun -sdk iphoneos lipo -info $(FILENAME)
    #-----------------------------------------------------------------------------
    def lipo_dependency_libs

      (template_platform, template_target) = BUILD_TARGETS.first

      Find.find(File.join(self.lib_output_dir, "#{template_target}-#{template_platform}")) do |template_lib_name|
        next unless File.basename(template_lib_name) =~ /^lib.+\.(a|dylib)$/

        fat_lib = File.join(self.framework_lib_dir, File.basename(template_lib_name))
        lipo_args = ["-arch #{template_platform} #{template_lib_name}"]

        BUILD_TARGETS.each do |platform, target|
          next if platform == template_platform
          lib_name = template_lib_name.sub(
            "#{template_target}-#{template_platform}",
            "#{target}-#{platform}"
          )
          if File.exists?(lib_name)
            lipo_args << "-arch #{platform} #{lib_name}"
          else
            warn "********* WARNING: lib doesn't exist! #{FileUtils.pwd}/#{lib_name}"
          end
        end

        lipo_args = lipo_args.join(' ')

        self.logger.info("LIPOing libs with args: #{lipo_args}")
        lipoResult=`xcrun -sdk iphoneos lipo #{lipo_args} -create -output #{fat_lib} 2>&1`
        if lipoResult =~ /fatal error/
          raise "Got fatal error during LIPO: #{lipoResult}"
        end
      end
    end

    #-----------------------------------------------------------------------------
    def env_for_arch(target, arch)

      sdk_root = arch.start_with?('arm') ? SDK_IPHONEOS : SDK_IPHONESIMULATOR
      if !File.exists?(sdk_root)
        raise "SDKROOT does not exist: #{sdk_root}"
      end

      cflags = [
        "-I#{self.framework_headers_dir}",
        "-arch #{arch}",
        "-pipe",
        "-no-cpp-precomp",
        "-isysroot #{sdk_root}",
        "-miphoneos-version-min=#{IOS_DEPLOY_TGT}",
      ]
      if arch.start_with?('arm')
        cflags << "-I#{sdk_root}/usr/include/"
      end
      cflags = cflags.join(' ')

      env = {
        'SDKROOT' => sdk_root,
        'CXX' => CXX,
        'CC' => CC,
        'LD' => LD,
        'AS' => AS,
        'AR' => AR,
        'NM' => NM,
        'RANLIB' => RANLIB,
        'LDFLAGS' => "-L#{sdk_root}/usr/lib/ -L#{self.arch_build_dir(target, arch)}",
        'CFLAGS' => cflags,
        'CPPFLAGS' => cflags,
        'CXXFLAGS' => cflags,
        'PATH' => "#{XCODETOOLCHAIN}/usr/bin:#{ENV['PATH']}",
      }

      # TODO: do we need this?  clang complains about it
      if arch.start_with?('arm')
        env['BUILD_HOST_NAME'] = arch.sub(/^armv?(.+)/, 'arm-apple-darwin\1')
      end

      env
    end

    def merge_tesseract_libfiles(platform_output_dir, merged_lib_name)
      lib_files = Find.find(platform_output_dir).select do |path|
        File.basename(path) =~ /^lib.+\.a$/ || File.basename(path) !~ /liblept/
      end
      self.merge_libfiles(lib_files, platform_output_dir, merged_lib_name)
    end

    def put_framework_together
      self.lipo_dependency_libs
    end

    #-----------------------------------------------------------------------------
    def install_leptonica(target, arch)

      puts "Installing Leptonica"

      self.install_leptonica_headers
#return

      FileUtils.chdir(self.work_dir)
      puts "Building Leptonica for #{arch}"
      FileUtils.chdir(self.leptonica_lib_dir)
      self.cleanup_source
      self.do_standard_build(target, arch, %w{--enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib --without-libtiff})
      FileUtils.cp_r(Dir['src/.libs/lib*.a'], self.arch_build_dir(target, arch))
    end

    #-----------------------------------------------------------------------------
    def install_tesseract(target, arch)

      puts "Installing Tesseract"

      self.install_tesseract_headers
#return

      FileUtils.chdir(self.work_dir)

      puts "Building Tesseract for #{arch}"
      FileUtils.chdir(self.tesseract_lib_dir)
      self.cleanup_source
      log_execute('bash autogen.sh 2>&1', self.env_for_arch(target, arch))
      self.do_standard_build(target, arch, ["--enable-shared=no", "LIBLEPT_HEADERSDIR=#{File.join(self.framework_headers_dir, 'leptonica')}"])

      lib_files = Find.find(self.tesseract_lib_dir).map do |path|
        File.basename(path) =~ /^lib.+\.a$/ && !path.include?('arm')
        #  FileUtils.cp_r(path, self.arch_build_dir(target, arch))
      end
      self.merge_libfiles(lib_files, self.arch_build_dir(target, arch), 'libtesseract_all.a')
      #FileUtils.cp_r(path, self.arch_build_dir(target, arch))
    end

     def install_leptonica_headers
      return if self.leptonica_headers_installed?

      dest_dir = File.join(self.framework_headers_dir, 'leptonica')
      FileUtils.mkdir_p(dest_dir)
      FileUtils.cp_r(Dir["#{self.leptonica_lib_dir}/src/*.h"], dest_dir)
    end

    def install_tesseract_headers
      return if self.tesseract_headers_installed?

      dest_dir = File.join(self.framework_headers_dir, 'tesseract')
      FileUtils.mkdir_p(dest_dir)
      FileUtils.chdir(self.tesseract_lib_dir)
      TESSERACT_HEADERS.each do |header|
        FileUtils.cp_r(header, dest_dir)
      end
    end

    def leptonica_headers_installed?
      File.exists?("#{self.framework_headers_dir}/leptonica")
    end

    def tesseract_headers_installed?
      File.exists?("#{self.framework_headers_dir}/tesseract")
    end

    def built?
      self.leptonica_headers_installed? &&
        self.tesseract_headers_installed? &&
        File.exists?("#{self.framework_lib_dir}/libtesseract_all.a") &&
        File.exists?("#{self.framework_lib_dir}/liblept.a")
    end

  end
end

