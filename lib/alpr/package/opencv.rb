# Downloads the binary release of the iOS Opencv framework
# Note: the binary release is not built with bitcode,
# so the other dependencies are also built without it.
# Which also means any Xcode project using these frameworks
# must have bitcode disabled.
module Alpr::Package
  class Opencv < Base

    #-----------------------------------------------------------------------------
    def install(work_dir:, dest_root:, force:)
      self.work_dir = work_dir
      self.dest_root = dest_root
      self.target_dir = File.join(dest_root, 'opencv2.framework')

      # Unarchiving the opencv2 zip will create what would normally be
      # the actual target_dir, so we do not need to create it manually.

      self.download
      self.add_headers_symlink_hack
    end

    protected

    def name
      'opencv2'
    end

    def archive_name
     "#{self.package_name}.zip"
    end

    def package_name
     "#{self.name}.framework"
    end

    # Parse out the version from the main CMakeLists.txt file
    def package_version
      '3.0.0'
    end

    def archive_url
      "http://sourceforge.net/projects/opencvlibrary/files/opencv-ios/#{package_version}/#{archive_name}/download#"
    end

    #-----------------------------------------------------------------------------
    # Since the unarchived contents of this package are also the installed
    # contents, we go ahead and unarchive directly to the target_dir.
    #-----------------------------------------------------------------------------
    def package_dir
      File.join(self.target_dir, package_name)
    end

    #-----------------------------------------------------------------------------
    def download
      archive_path = File.join(self.work_dir, self.archive_name)

      if File.exists?(archive_path)
        puts "Package #{self.name} already downloaded"
      else
        puts "Downloading #{self.name} library."
        log_execute("curl -L -o #{archive_path} #{self.archive_url}")
      end

      if !File.exists?(self.package_dir)
        log_execute("unzip -d #{self.target_dir} #{archive_path}")
      end
      # frameworks appear to be considered dirs
      if !File.directory?(self.package_dir)
        raise "Missing #{self.name} framework bundle: #{self.package_dir}"
      end
    end

    #-----------------------------------------------------------------------------
    # openalpr looks for the headers with a path of 'opencv2/*'. Create a symlink
    # to emulate this path.
    #-----------------------------------------------------------------------------
    def add_headers_symlink_hack
      binding.pry
      headers_dir = File.join(target_dir, 'Headers')
      link_path = File.join(headers_dir, 'opencv2')
      if !File.symlink?(link_path)
        msg = "adding opencv2 headers symlink hack: #{link_path} -> #{headers_dir}"
        puts msg
        logger.info(msg)
        do_in_dir(headers_dir) do
          FileUtils.ln_s('../Headers', 'opencv2')
        end
      end
    end

  end
end

