require_relative 'utils'
require_relative 'xcode'
require 'fileutils'
require 'osx/plist'

module Alpr
  class CoreBuild
    include Utils # needed for instance level calls to execute
    extend Utils # needed for class level calls to execute
    include Xcode

    def self.qexec(cmd)
      execute(cmd, nil, {quiet: true})
    end

    def self.xcfind(path)
      qexec("xcrun -find #{path}")
    end

    AR = xcfind("ar")

    IOS_BASE_SDK="9.0"
    IOS_DEPLOY_TGT="9.0"

    PROJECT_ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

    XCODE_CONFIGURATION = "Release"

    CONFIG_DIR = File.join(PROJECT_ROOT_DIR, 'etc')

    BUILD_TARGETS = {
      "armv7" => "iPhoneOS",
      "armv7s" => "iPhoneOS",
      "arm64" => "iPhoneOS",
      "i386" => "iPhoneSimulator",
      "x86_64" => "iPhoneSimulator"
    }

    ALPR_CMAKE_TARGETS = %w{support video statedetection openalpr-static}

    # for some reason, if you do not specify CMAKE_BUILD_TYPE, it puts libs to "RELEASE" rather than "Release"
    CMAKE_BASE_ARGS = [
      '-GXcode',
      "-DCMAKE_CONFIGURATION_TYPES=#{XCODE_CONFIGURATION}",
      '-DCMAKE_INSTALL_PREFIX=install',
      '-DWITH_DAEMON=OFF',
      '-DWITH_UTILITIES=OFF',
      '-DWITH_BINDING_JAVA=OFF',
      '-DWITH_BINDING_PYTHON=OFF',
      '-DWITH_GPU_DETECTOR=OFF',
      '-DWITH_TESTS=OFF',
    ]

    def log_execute(cmd, env={}, opts={})
      execute(cmd, env, {log: self.log_file})
    end

    # "main function to do all the work"
    def build_framework(dest_dir)
      self.dest_dir = dest_dir
      self.work_dir = File.join(PROJECT_ROOT_DIR, 'work')
      self.lib_output_dir = File.join(work_dir, "lib")

      [self.work_dir, self.lib_output_dir, self.dest_dir].each do |dir|
        FileUtils.mkdir_p(dir)
      end

      self.log_file = File.join(self.work_dir, "build.log")
      self.logger = Logger.new(self.log_file)
      self.logger.level = Logger::INFO
      puts "Logging shell output to #{self.log_file}"

      puts "Using build_root #{self.lib_output_dir}"

      self.framework_dir = File.join(self.dest_dir, "openalpr.framework")
      if !File.exists?(self.framework_dir) || self.rebuild_deps
        self.create_skeleton_alpr_framework(self.framework_dir)
      end

      self.patch_alpr_cmake

      BUILD_TARGETS.each do |arch, target|
        self.build_alpr_and_dependencies(target, arch)
      end

      self.install_alpr_assets
      self.put_framework_together
    end

    protected

    attr_accessor :log_file, :logger, :work_dir, :dest_dir, :lib_output_dir, :rebuild_deps, :framework_dir, :xcode_project_dir

    def install_alpr_assets
      headers_dir = File.join(self.framework_headers_dir, 'alpr')
      FileUtils.mkdir_p(headers_dir)
      #FileUtils.cp_r(Dir["#{self.alpr_src_dir}/openalpr/alpr.h"], headers_dir)
      FileUtils.cp("#{self.alpr_src_dir}/openalpr/alpr.h", headers_dir)

      resources_dir = File.join(self.framework_dir, 'Resources')
      FileUtils.cp_r("#{self.alpr_module_dir}/runtime_data", resources_dir)
      FileUtils.cp("#{self.alpr_build_dir}/config/openalpr.conf", resources_dir)

      cmakelists = File.read(File.join(self.alpr_src_dir, 'CMakeLists.txt'))

        versions = %w{MAJOR MINOR PATCH}.map do |k|
          if cmakelists =~ /OPENALPR_#{k}_VERSION "(\d+)"/
            $1
          else
            nil
          end
        end

        if versions.include?(nil)
          raise "could not parse ALPR version from cmake file"
        end

        alpr_version = versions.join('.')

        plist = OSX::PropertyList.load(File.read(File.join(CONFIG_DIR, 'Info.plist.in')))
        plist['CFBundleShortVersionString'] = alpr_version
        plist['CFBundleVersion'] = alpr_version

        target_pfile = File.join(resources_dir, 'Info.plist')
        OSX::PropertyList.dump_file(target_pfile, plist)
    end

    def initialize(opts={})
      opts.each { |k,v| self.send("#{k}=", v) }
      self.rebuild_deps = true if self.rebuild_deps.nil?
    end

    def alpr_module_dir
      File.join(self.work_dir, 'openalpr')
    end

    def alpr_src_dir
      File.join(self.alpr_module_dir, 'src')
    end

    def framework_lib_dir
      raise "framework_dir not set" if self.framework_dir.nil?
      File.join(self.framework_dir, 'Libraries')
    end

    def framework_headers_dir
      raise "framework_dir not set" if self.framework_dir.nil?
      File.join(self.framework_dir, 'Headers')
    end

    def alpr_build_dir
      File.join(self.alpr_src_dir, 'build')
    end

    def alpr_cmake_args(target)

      ios_cmake_platform = (target == 'iPhoneOS' ? 'OS' : 'SIMULATOR')

      CMAKE_BASE_ARGS.dup.concat([
        "-DIOS_PLATFORM=#{ios_cmake_platform}",
        "-DCMAKE_TOOLCHAIN_FILE=#{File.join(CONFIG_DIR, 'cmake', 'Toolchains', "iOS.cmake")}",
        # https://public.kitware.com/Bug/view.php?id=15329
        "-DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=NO",
        "-DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=\"Don't Code Sign\"",
      ])
    end

    def configure_alpr_build(target, arch)
      if File.directory?(self.alpr_build_dir)
        FileUtils.rm_rf(self.alpr_build_dir)
      end
      FileUtils.mkdir(self.alpr_build_dir)
      FileUtils.chdir(self.alpr_build_dir)

      cmakeargs = self.alpr_cmake_args(target, arch).join(" ")

      # if cmake cache exists, just rerun cmake to update OpenALPR.xcodeproj if necessary
      #if File.file?(File.join(build_dir, "CMakeCache.txt"))
      #  execute("cmake #{cmakeargs} ")
      #else
      #  binding.pry
      #end

      log_execute("cmake #{cmakeargs} #{self.alpr_src_dir}")

      #xcodeproj_file = File.join(self.alpr_build_dir, "src.xcodeproj/project.pbxproj")
      #FileUtils.cp(xcodeproj_file, "#{xcodeproj_file}.orig")
      #self.patch_xcode_project!(
      #  xcodeproj_file,
      #  self.alpr_src_dir,
      #  target,
      #  IOS_DEPLOY_TGT,
      #  [self.framework_headers_dir],
      #  %w{openalpr statedetection video support}.map do |lib|
      #    File.join(self.alpr_build_dir, lib, "#{XCODE_CONFIGURATION}-#{target.downcase}")
      #  end.push(self.opencv_framework_dir)
      #)
    end

    def build_deps(target, arch)
      raise "Subclass must implement."
    end

    def arch_build_dir(target, arch)
      File.join(self.lib_output_dir, target + '-' + arch)
    end

    def setup_build_dir(build_dir)
      if self.rebuild_deps
        FileUtils.rm_rf(build_dir)
      end

      if !File.directory?(build_dir)
        FileUtils.mkdir_p(build_dir)
      end
    end

    def alpr_xcodebuild_args(target, arch)
      args = [
        "-parallelizeTargets",
        "-jobs 8",
        "-sdk #{target.downcase}",
        "-configuration #{XCODE_CONFIGURATION}",
        "IPHONEOS_DEPLOYMENT_TARGET=#{IOS_DEPLOY_TGT}",
        "ARCHS=#{arch}",
      ]
    end

    def run_alpr_xcodebuild(target, arch)
      FileUtils.chdir(self.alpr_build_dir)

      ALPR_CMAKE_TARGETS.map { |x| "-target #{x}" }.each do |cmake_target|
        log_execute("xcodebuild #{self.alpr_xcodebuild_args(target, arch).push(cmake_target).join(" ")}")
      end

      #libs = Dir["#{self.alpr_build_dir}/**/lib*.a"]
      libs = Dir["#{self.alpr_build_dir}/**/lib*.a","#{self.alpr_build_dir}/**/lib*.dylib"]
      self.logger.info("ALPR libs for arch #{arch}: #{libs}")
      FileUtils.cp(libs, self.arch_build_dir(target, arch))

      #libs = libs.map do |path|
      #  File.join(self.arch_build_dir(target, arch), File.basename(path))
      #end
      #binding.pry
      #self.merge_libfiles(libs, self.alpr_build_dir, 'libopenalpr-static_all.a')
      #FileUtils.cp(File.join(self.alpr_build_dir, 'libopenalpr-static_all.a'), self.arch_build_dir(target, arch))
    end

    #-----------------------------------------------------------------------------
    # Merges distinct *.a archive libraries into a single one by pulling out all
    # .o files from the individual archives and stuffing them into the target archive.
    #
    # Show symbols:
    # nm -gU  libtesseract.a  | grep GetIterator
    #-----------------------------------------------------------------------------
    def merge_libfiles(lib_files, output_dir, merged_lib_name)
      tmp_dir="#{output_dir}.tmp"
      self.do_in_dir(tmp_dir, true) do
        lib_files.each do |path|
          self.logger.debug("Extracting libraries from archive #{path}")

          # extract all *.o files from .a library
          log_execute("#{AR} -x #{path} `#{AR} -t #{path} | grep '.o$'`")
          # replace or add all *.o files to new lib archive
          log_execute("#{AR} -r #{File.join(output_dir, merged_lib_name)} *.o")
        end
      end
    end

    def do_in_dir(dir, is_tmp=false)
      if is_tmp
        if File.directory?(dir)
          FileUtils.rm_rf(dir)
        end
        FileUtils.mkdir(dir)
      end
      currdir = FileUtils.pwd
      FileUtils.cd(dir)
      yield
      FileUtils.cd(currdir)
      if is_tmp
        FileUtils.rm_rf(dir)
      end
    end

    def build_alpr(target, arch)
      self.configure_alpr_build(target, arch)
      self.build_deps(build_dir, target, arch)
      self.run_alpr_xcodebuild(target, arch)
    end

    def patch_alpr_cmake
      common_args = "-d #{self.alpr_module_dir} -p1 -i #{CONFIG_DIR}/cmake/OpenALPR_CMakeLists.txt.patch"
      output = `patch --silent --dry-run #{common_args}`
      # file is not patched yet
      if $?.success?
        log_execute("patch #{common_args}")
      end
    end

    # "builds OpenALPR for device or simulator"
    def build_alpr_and_dependencies(target, arch)
      build_dir = self.arch_build_dir(target, arch)
      puts "building openalpr for target #{target}, arch #{arch}, on #{build_dir}"
      self.setup_build_dir(build_dir)
      self.do_in_dir(build_dir) do
        self.build_alpr(target, arch)
      end
    end

  end
end


