require_relative '../constants'
require_relative '../gnu_make'
require_relative '../utils'
require_relative '../xcode'

module Alpr::Package
  class Base
    include Alpr::Constants
    include Alpr::Utils
    include Alpr::Xcode

   #-----------------------------------------------------------------------------
    def build_framework(name:, work_dir:, target_dir:, log_file:, logger:, force:)

      self.name = name

      self.work_dir = work_dir

      if !File.directory?(work_dir)
        FileUtils.mkdir_p(work_dir)
      end

      self.target_dir = File.join(target_dir, "#{name}.framework")

      self.log_file = log_file
      self.logger = logger

      if !self.built? || force
        FileUtils.rm_rf(self.target_dir)

        self.create_framework_skeleton(self.target_dir)
        self.download
        self.install_headers
        self.pre_build_setup
        BUILD_TARGETS.each do |arch, target|
          self.build_arch(target, arch)
        end
        self.lipo_libraries(self.thin_lib_dest_root, self.target_dir)
        self.rename_target_lib_as_executable

        self.create_framework_plist(
          name: self.name,
          id: self.name,
          version: self.package_version,
          dest_dir: self.target_dir
        )

        self.post_build_setup
      end
    end

    protected

    attr_accessor :name, :work_dir, :target_dir, :log_file, :logger

    def rename_target_lib_as_executable
      FileUtils.chdir(self.target_dir)
      if target_lib_path
        logger.info("Moving #{self.target_merged_lib} as executable #{self.name}")
        FileUtils.mv(target_lib_path, self.name)
      else
        raise "Package installs more than one library. Cannot install single executable for framework."
      end
    end

    #-----------------------------------------------------------------------------
    def download
      do_in_dir(self.work_dir) do
        archive_path = File.join(self.work_dir, self.archive_name)

        if !File.exists?(archive_path)
          puts "Downloading #{self.name} library."
          log_execute("curl -L -o #{archive_path} #{self.archive_url}")
        end
        if !File.directory?(self.package_dir)
          log_execute("tar -xvf #{archive_path}")
        end

        if !File.directory?(self.package_dir)
          raise "Missing #{self.name} source directory: #{self.package_dir}"
        end
      end
    end

    #-----------------------------------------------------------------------------
    def install_headers
      FileUtils.mkdir_p(self.target_headers_dir)
      FileUtils.cp(self.target_headers, self.target_headers_dir)
    end

    def headers_installed?
      File.exists?(self.target_headers_dir)
    end

    def built?
      self.headers_installed? && File.exists?(target_lib_path)
    end

    #-----------------------------------------------------------------------------
    def package_dir
      File.join(self.work_dir, package_name)
    end

    def thin_lib_dest_root
      File.join(self.work_dir, self.name + '-thin-lib')
    end

    def arch_build_dir(target, arch)
      File.join(self.thin_lib_dest_root, target + '-' + arch)
    end

    def target_headers_dir
      File.join(self.target_dir, 'Headers', self.name)
    end

    def target_lib_path
      if self.target_merged_lib
        return File.join(target_dir, target_merged_lib)
      elsif self.target_libs.size == 1
        return File.join(target_dir, File.basename(self.target_libs.first))
      else
        return nil
      end
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

    #-----------------------------------------------------------------------------
    # Assuming all library files exist in all platform directories,
    # this function picks one directory as a template to build a list
    # of files to lipo together from all platform dirs, writing the
    # fat libraries to the framework Libraries folder.
    #
    # xcrun -sdk iphoneos lipo -info $(FILENAME)
    #-----------------------------------------------------------------------------
    def lipo_libraries(base_dir, target_dir) #self.lib_output_dir

      (template_platform, template_target) = BUILD_TARGETS.first

      Find.find(File.join(base_dir, "#{template_target}-#{template_platform}")) do |template_lib_name|
        next unless File.basename(template_lib_name) =~ /^lib.+\.(a|dylib)$/

        fat_lib = File.join(target_dir, File.basename(template_lib_name))
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

    # http://www.opensource.apple.com/source/subversion/subversion-52/rpath_subversion.sh
    # see also:
    # http://stackoverflow.com/questions/26001321/application-with-private-framework-could-not-inspect-application-package-in-xc
    # http://stackoverflow.com/questions/26015194/xcode-could-not-inspect-the-application-package
    # http://stackoverflow.com/questions/14630828/could-not-inspect-application-package-xcode/14631281#14631281
    #
    #
    # https://developer.apple.com/library/mac/technotes/tn2206/_index.html#//apple_ref/doc/uid/DTS40007919-CH1-TNTAG205
    # https://github.com/kstenerud/iOS-Universal-Framework/issues/76
    # http://stackoverflow.com/questions/25632886/an-error-was-encountered-while-running-domain-launchserviceserror-code-0
    #
    #
    # http://www.raywenderlich.com/65964/create-a-framework-for-ios
    # http://stackoverflow.com/questions/31295369/ld-framework-not-found-parse-xcode-7-beta
    # https://techblog.badoo.com/blog/2015/02/09/code-signing-and-distributing-swift/
    #
    # https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/20001431-101909
    def update_rpath(libs:, dest_base_path:nil)
      dest_base_path ||= File.join('@executable_path')
      libs.each do |lib|
        old_name = `otool -D "#{lib}" | sed "1d"`.strip

        # oof, it points to the lib in the original build dir:
        # openalpr/src/build/openalpr/Release-iphonesimulator/libopenalpr.2.dylib"
        #new_name = File.join('@rpath', File.basename(old_name))
        #new_name = File.join('@executable_path', File.basename(old_name))
        #new_name = File.join('@executable_path/../Frameworks', File.basename(old_name))
        # based on: http://stackoverflow.com/a/28401662/868173
        #new_name = File.join('@executable_path','Frameworks', 'openalpr.framework','Libraries', File.basename(old_name))
        #new_name = File.join('@executable_path','Frameworks', 'openalpr.framework', File.basename(old_name))
        new_name = File.join(dest_base_path, File.basename(old_name))

        # fix LC_ID_DYLIB
        log_execute("install_name_tool -id \"#{new_name}\" #{lib}")

        # fix LC_LOAD_DYLIB entries in other binaries
        libs.each do |ref_lib|
          log_execute("install_name_tool -change \"#{old_name}\" \"#{new_name}\" \"#{ref_lib}\"")
        end
      end
    end

    #-----------------------------------------------------------------------------

    def pre_build_setup
      # NOOP
    end

    def post_build_setup
      # NOOP
    end

    def build_arch(target, arch)
      raise "subclass must implement"
    end

    def archive_name
      raise "subclass must implement"
    end

    def package_name
      raise "subclass must implement"
    end

    def package_version
      raise "subclass must implement"
    end

    def archive_url
      raise "subclass must implement"
    end

    def get_configure_options
      raise "subclass must implement"
    end

    def do_autogen?
      raise "subclass must implement"
    end

    def extra_headers_dir
      nil
    end

    def extra_libs_dir(target, arch)
      nil
    end

    def target_headers
      raise "subclass must implement"
    end

    def target_libs
      raise "subclass must implement"
    end

    def target_merged_lib
      nil
    end

  end
end

