# Downloads the binary release of the iOS Opencv framework
# Note: the binary release is not built with bitcode,
# so the other dependencies are also built without it.
# Which also means any Xcode project using these frameworks
# must have bitcode disabled.
module Alpr::Package
  class Opencv < Base

   #-----------------------------------------------------------------------------
    def build_framework(work_dir:, target_dir:, force:)
      self.work_dir = work_dir
      self.target_dir = target_dir #File.join(target_dir, "#{self.name}.framework")

     if !File.directory?(target_dir)
        FileUtils.mkdir_p(target_dir)
      end

      FileUtils.chdir(target_dir)
      self.download
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
    def download
      do_in_dir(self.target_dir) do

        if File.exists?(self.package_dir)
          puts "Package #{self.name} already installed"
        else
          binding.pry
          puts "Downloading #{self.name} library."
          log_execute("curl -L -o #{self.package_dir} #{self.archive_url}")
          # frameworks don't appear as dirs
          if !File.exists?(self.package_dir)
            log_execute("unzip #{self.package_dir}")
          end
          if !File.exists?(self.package_dir)
            raise "Missing #{self.name} source directory: #{self.package_dir}"
          end
        end
      end
    end

  end
end

