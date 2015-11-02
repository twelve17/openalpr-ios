require_relative 'constants'
require_relative 'utils'
require_relative 'xcode'
require 'fileutils'
require 'osx/plist'

module Alpr
  class CoreBuild
    include Constants
    include Utils # needed for instance level calls to execute
    extend Utils # needed for class level calls to execute
    include Xcode

    ALPR_CMAKE_TARGETS = %w{openalpr-static install}

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
        self.create_framework_skeleton(self.framework_dir, self.use_shallow_framework)
      end

      #self.patch_alpr_cmake

      BUILD_TARGETS.each do |arch, target|
        self.setup_build_dir(self.arch_build_dir(target, arch))
      end

      BUILD_TARGETS.each do |arch, target|
        self.build_deps(target, arch)
      end
      self.post_dependency_build

      BUILD_TARGETS.each do |arch, target|
      puts "building openalpr for target #{target}, arch #{arch}, on #{self.arch_build_dir(target, arch)}"
        self.build_alpr(target, arch)
      end
      self.post_dependency_build

      self.install_alpr_assets
      #self.put_framework_together
      self.update_rpath(libs: self.framework_libs)
    end

    protected

    attr_accessor :log_file, :logger, :work_dir, :dest_dir, :lib_output_dir, :rebuild_deps, :framework_dir, :xcode_project_dir, :use_shallow_framework

    def initialize(opts={})
      opts.each { |k,v| self.send("#{k}=", v) }
      self.rebuild_deps = true if self.rebuild_deps.nil?
      self.use_shallow_framework = true unless opts.has_key?(:use_shallow_framework)
      #self.use_shallow_framework = false
    end

    def alpr_module_dir
      File.join(self.work_dir, 'openalpr')
    end

    def alpr_src_dir
      File.join(self.alpr_module_dir, 'src')
    end

    def framework_lib_dir
      raise "framework_dir not set" if self.framework_dir.nil?
      if self.use_shallow_framework
        self.framework_dir
      else
        File.join(self.framework_dir, 'Libraries')
      end
    end

    def framework_resources_dir
      raise "framework_dir not set" if self.framework_dir.nil?
      if self.use_shallow_framework
        self.framework_dir
      else
        File.join(self.framework_dir, 'Resources')
      end
    end

    def install_alpr_assets
      headers_dir = File.join(self.framework_headers_dir, 'alpr')
      FileUtils.mkdir_p(headers_dir)
      #FileUtils.cp_r(Dir["#{self.alpr_src_dir}/openalpr/alpr.h"], headers_dir)
      FileUtils.cp("#{self.alpr_src_dir}/openalpr/alpr.h", headers_dir)
      FileUtils.cp("#{self.alpr_src_dir}/openalpr/config.h", headers_dir)
      FileUtils.cp("#{self.alpr_src_dir}/openalpr/constants.h", headers_dir)

      FileUtils.cp_r("#{self.alpr_module_dir}/runtime_data", self.framework_resources_dir)
      FileUtils.cp("#{self.alpr_build_dir}/config/openalpr.conf", self.framework_resources_dir)

      cmakelists_content = File.read(File.join(self.alpr_src_dir, 'CMakeLists.txt'))

      versions = %w{MAJOR MINOR PATCH}.map do |k|
        if cmakelists_content =~ /OPENALPR_#{k}_VERSION "(\d+)"/
          $1
        else
          nil
        end
      end

      if versions.include?(nil)
        raise "could not parse ALPR version from cmake file"
      end

      alpr_version = versions.join('.')

      create_framework_plist(
        name: 'openalpr',
        id: 'com.openalpr',
        version: alpr_version,
        dest_dir: self.framework_resources_dir
      )

    end

    def framework_libs
      Dir[File.join(self.framework_lib_dir, '*.dylib')].reject do |lib|
        File.symlink?(lib)
      end
    end

    def framework_headers_dir
      raise "framework_dir not set" if self.framework_dir.nil?
      #if self.use_shallow_framework
      #  self.framework_dir
      #else
        File.join(self.framework_dir, 'Headers')
      #end
    end

    def alpr_build_dir
      File.join(self.alpr_src_dir, 'build')
    end

    def opencv_framework_dir
      File.join(self.dest_dir, 'opencv2.framework')
    end


    def tesseract_framework_dir
      File.join(self.dest_dir, 'tesseract.framework')
    end

    def tesseract_framework_headers_dir
      File.join(self.tesseract_framework_dir, 'Headers')
    end

#    def configure_alpr_build(target, arch)
#      if File.directory?(self.alpr_build_dir)
#        FileUtils.rm_rf(self.alpr_build_dir)
#      end
#      FileUtils.mkdir(self.alpr_build_dir)
#      FileUtils.chdir(self.alpr_build_dir)
#
#      cmakeargs = self.alpr_cmake_args(target, arch).join(" ")
#
#      # TODO: can we make this work?
#      # if cmake cache exists, just rerun cmake to update OpenALPR.xcodeproj if necessary
#      #if File.file?(File.join(build_dir, "CMakeCache.txt"))
#      #  execute("cmake #{cmakeargs} ")
#      #else
#      #  binding.pry
#      #end
#
#      log_execute("cmake #{cmakeargs} #{self.alpr_src_dir} 2>&1")
#    end
#
#    def build_deps(target, arch)
#      raise "Subclass must implement."
#    end

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

      # appending 'install' to the target will install the resulting files
      ALPR_CMAKE_TARGETS.map { |x| "-target #{x} install" }.each do |cmake_target|
        log_execute("xcodebuild #{self.alpr_xcodebuild_args(target, arch).push(cmake_target).join(" ")}")
      end

      libs = Dir["#{self.alpr_build_dir}/**/#{XCODE_CONFIGURATION}-*/lib*.a"]
      self.merge_libfiles(libs, self.alpr_build_dir, 'libopenalpr-static_all.a')

      #libs = Dir["#{self.alpr_build_dir}/**/#{XCODE_CONFIGURATION}-*/lib*.a","#{self.alpr_build_dir}/**/#{XCODE_CONFIGURATION}-*/lib*.dylib"]
      libs << File.join(self.alpr_build_dir, 'libopenalpr-static_all.a')
      self.logger.info("ALPR libs for arch #{arch}: #{libs}")
      FileUtils.cp(libs, self.arch_build_dir(target, arch))
    end

    def build_alpr(target, arch)
      self.configure_alpr_build(target, arch)
      self.run_alpr_xcodebuild(target, arch)
    end

  end
end


