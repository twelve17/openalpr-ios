require 'osx/plist'

module Alpr
  module Xcode

    def create_framework_skeleton(framework_dir, shallow=true)
      shallow ? self.create_shallow_framework_skeleton(framework_dir) \
        : self.create_deep_framework_skeleton(framework_dir)
    end

    # find openalpr.framework.bak -not -path "*runtime_data*" -type f -exec cp {} openalpr.framework/ \; && cp -r openalpr.framework.bak/Resources/runtime_data openalpr.framework/
    def create_shallow_framework_skeleton(framework_dir)
      FileUtils.mkdir_p(File.join(framework_dir, 'Headers'))
    end

    def create_deep_framework_skeleton(framework_dir)
      # set the current dir to the dst root
      currdir = FileUtils.pwd()
      if File.directory?(framework_dir)
        FileUtils.rm_rf(framework_dir)
      end

      FileUtils.mkdir_p(framework_dir)
      FileUtils.cd(framework_dir)

      # form the directory tree
      version_dir = "Versions/A"
      FileUtils.mkdir_p(version_dir + "/Resources")
      FileUtils.mkdir_p(version_dir + "/Headers")
      FileUtils.mkdir_p(version_dir + "/Libraries")

      # make symbolic links
      FileUtils.ln_s("A", "Versions/Current")
      %w{Headers Libraries Resources}.each do |k|
        FileUtils.ln_s("Versions/Current/#{k}", k)
      end

      return framework_dir
    end

    # pkg can be BNDL, FMWK
    def create_framework_plist(name:, id:, version:, dest_dir:, pkg:'BNDL', executable:nil)
      executable ||= name
      OSX::PropertyList.dump_file(File.join(dest_dir, 'Info.plist'), {
        'CFBundleName' => name,
        'CFBundleIdentifier' => id,
        'CFBundleShortVersionString' => version,
        'CFBundleVersion' => version,
        'CFBundleSignature' => '????',
        'CFBundleExecutable' => executable,
        'CFBundlePackageType' => pkg,
      })
    end

    def get_framework_version(framework_path:)
      plist_file = File.exists?(File.join(framework_path, 'Resources', 'Info.plist')) ?
        File.join(framework_path, 'Resources', 'Info.plist') :
        File.join(framework_path, 'Info.plist')

      plist = OSX::PropertyList.load(File.read(plist_file))
      if plist['CFBundleVersion'].nil?
        raise "could not determine version in framework: #{framework_path}"
      end
      return plist['CFBundleVersion']
    end

  end
end


