require_relative 'base'

# http://stackoverflow.com/questions/15331056/library-static-dynamic-or-framework-project-inside-another-project
module Alpr::Package
  class Alpr < Alpr::Package::Base

    protected

    ALPR_CMAKE_TARGETS = %w{openalpr-static install}
    IOS_TOOLCHAIN_FILE = File.join(CONFIG_DIR, 'cmake', 'Toolchains', "iOS.cmake")

    attr_accessor :opencv_framework_dir, :tesseract_framework_dir, :leptonica_framework_dir, :tesseract_thin_lib_dir, :leptonica_thin_lib_dir

    def initialize(log_file:, logger:,
                   opencv_framework_dir:,
                   tesseract_framework_dir:,
                   leptonica_framework_dir:,
                   tesseract_thin_lib_dir:,
                   leptonica_thin_lib_dir:
                  )
      super(log_file: log_file, logger: logger)
      self.opencv_framework_dir = opencv_framework_dir
      self.tesseract_framework_dir = tesseract_framework_dir
      self.leptonica_framework_dir = leptonica_framework_dir
      self.tesseract_thin_lib_dir = tesseract_thin_lib_dir
      self.leptonica_thin_lib_dir = leptonica_thin_lib_dir
    end

    def name
      'openalpr'
    end

    def download
      do_in_dir(self.work_dir) do
        archive_path = File.join(self.work_dir, self.archive_name)
        if !File.exists?(archive_path)
          log_execute("git clone #{self.archive_url} #{self.package_name}")
        end
      end
    end

    def archive_name
      self.package_name
    end

    def package_name
      self.name
    end

    # Parse out the version from the main CMakeLists.txt file
    def package_version
      cmakelists_content = File.read(File.join(cmake_src_dir, 'CMakeLists.txt'))

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

      versions.join('.')
    end

    def archive_url
      'https://github.com/openalpr/openalpr.git'
    end

    def target_headers
      %w{alpr.h config.h constants.h}.map { |x| File.join(cmake_src_dir, 'openalpr', x) }
    end

    def target_libs
      Dir["#{cmake_build_dir}/**/#{XCODE_CONFIGURATION}-*/lib*.a"]
    end

    def target_merged_lib
      'libopenalpr_all.a'
    end

    def build_arch(target, arch)

      puts "Building #{name} for #{arch} from #{self.package_dir}"

      if File.directory?(cmake_build_dir)
        FileUtils.rm_rf(cmake_build_dir)
      end
      FileUtils.mkdir(cmake_build_dir)
      FileUtils.chdir(cmake_build_dir)

      # TODO: obey 'force'
      FileUtils.rm_rf(self.thin_lib_dir(target, arch))
      FileUtils.mkdir_p(self.thin_lib_dir(target, arch))

      log_execute("cmake #{cmake_args(target,arch)} #{cmake_src_dir} 2>&1")

      # appending 'install' to the target will install the resulting files
      ALPR_CMAKE_TARGETS.map { |x| "-target #{x} install" }.each do |cmake_target|
        log_execute("xcodebuild #{xcodebuild_args(target, arch).push(cmake_target).join(" ")}")
      end

      self.merge_libfiles(self.target_libs, self.thin_lib_dir(target, arch), self.target_merged_lib)
    end

    def pre_build_setup
      patch_cmakelists
    end

    def post_build_setup
      install_resources
      #self.update_rpath(self.target_dir
    end

    # TODO: make this the default in Base class
    def target_headers_dir
      File.join(self.target_dir, 'Headers')
    end

    private

    def cmake_args(target, arch)
      opencv_framework_version = self.get_framework_version(framework_path: self.opencv_framework_dir)

#      tess_include_vars = %w{
#         Tesseract_INCLUDE_BASEAPI_DIR
#         Tesseract_INCLUDE_CCSTRUCT_DIR
#         Tesseract_INCLUDE_CCMAIN_DIR
#         Tesseract_INCLUDE_CCUTIL_DIR
#         Tesseract_INCLUDE_DIRS
#         Tesseract_PKGCONF_INCLUDE_DIRS
#      }.map { |k| "-D#{k}=#{File.join(self.tesseract_framework_dir, 'Headers')}" }

      [
        '-GXcode',
        "-DIOS_PLATFORM=#{CMAKE_IOS_PLATFORMS[arch]}",
        "-DCMAKE_TOOLCHAIN_FILE=#{IOS_TOOLCHAIN_FILE}",
        "-DTesseract_LIB=#{File.join(self.tesseract_thin_lib_dir, "#{target}-#{arch}", 'libtesseract_all.a')}",
        "-DLeptonica_LIB=#{File.join(self.leptonica_thin_lib_dir, "#{target}-#{arch}", 'liblept.a')}",
        "-DOpenCV_IOS_FRAMEWORK_PATH=#{self.opencv_framework_dir}",
        "-DOpenCV_VERSION=#{opencv_framework_version}",
        "-DOpenCV_VERSION_MAJOR=#{opencv_framework_version[0]}",
      ].concat(tess_include_vars).join(" ")
    end

    def install_resources
      FileUtils.cp_r("#{self.package_dir}/runtime_data", self.target_dir)
      FileUtils.cp("#{cmake_build_dir}/config/openalpr.conf", self.target_dir)
    end

    def xcodebuild_args(target, arch)
      args = [
        "-parallelizeTargets",
        "-jobs 8",
        "-sdk #{target.downcase}",
        "-configuration #{XCODE_CONFIGURATION}",
        "IPHONEOS_DEPLOYMENT_TARGET=#{IOS_DEPLOY_TGT}",
        "ARCHS=#{arch}",
      ]
    end

    def cmake_src_dir
      File.join(self.package_dir, 'src')
    end

    def cmake_build_dir
      File.join(cmake_src_dir, 'build')
    end

    def patch_cmakelists
      logger.info("patching CMakeLists")
      common_args = "-d #{self.package_dir} -p1 -i #{CONFIG_DIR}/cmake/OpenALPR_CMakeLists.txt.patch"
      output = `patch --silent --dry-run #{common_args}`
      # file is not patched yet
      if $?.success?
        log_execute("patch #{common_args}")
      else
        logger.info("CMakeLists is already patched") # TODO: could be error too
      end
    end

  end
end
