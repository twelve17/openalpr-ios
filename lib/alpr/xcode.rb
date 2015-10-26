require 'osx/plist'
require_relative 'utils'

module Alpr
  module Xcode
    extend Utils

    def build_settings(src_dir, header_search_paths=nil)
      v = []
      Find.find(File.join(src_dir, 'openalpr')) do |path|
        if File.directory?(path) && !path.include?('support/windows')
          v << path
        end
      end
      if header_search_paths
        v.concat(header_search_paths)
      end
      { 'HEADER_SEARCH_PATHS' => v }
    end

    def find_version_definitions(plist)
      self.build_settings_sections(plist).select do |id,ref|
        vdefs = self.get_version_definitions(ref['buildSettings'])
        return vdefs if !vdefs.empty?
      end
    end

    def get_version_definitions(bs)
      bs['GCC_PREPROCESSOR_DEFINITIONS'].select do |x|
        x =~ /OPENALPR_.+_VERSION/
      end
    end

    def build_settings_sections(plist)
      plist['objects'].select do |id,ref|
        ref['isa'] == "XCBuildConfiguration" && ref['buildSettings']
      end
    end

    def patch_xcode_project!(pfile, src_dir, target, target_version, header_search_paths=nil, library_search_paths=nil)

      if !File.exists?(pfile)
        warn "File does not exist: #{pfile}"
        return
      end

      plist = OSX::PropertyList.load(File.new(pfile))

      self.build_settings_sections(plist).select do |id,ref|
        #oldbs = ref['buildSettings']

        #ref['buildSettings'].merge!(self.build_settings(src_dir, header_search_paths))

        ref['buildSettings']['GCC_PREPROCESSOR_DEFINITIONS'] ||= []
        if self.get_version_definitions(ref['buildSettings']).empty?
          ref['buildSettings']['GCC_PREPROCESSOR_DEFINITIONS'] << self.find_version_definitions(plist)
        end

        #if !library_search_paths.nil?
        #  ref['buildSettings']['LIBRARY_SEARCH_PATHS'] ||= []
#
#          if !ref['buildSettings']['LIBRARY_SEARCH_PATHS'].is_a?(Array)
#            ref['buildSettings']['LIBRARY_SEARCH_PATHS'] =
#              ref['buildSettings']['LIBRARY_SEARCH_PATHS'].split(/\s+/).reject { |x| x.nil? || x.empty? }
#          end
#
#          ref['buildSettings']['LIBRARY_SEARCH_PATHS'].concat(library_search_paths)
#        end
      end

      # writes to XML, does not support old plist format
      OSX::PropertyList.dump_file(pfile, plist)

      # re-convert to old plist format :(
      log_execute("xcproj -p #{File.dirname(pfile)} touch")
    end

    def create_skeleton_alpr_framework(framework_dir)
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
      %w{Headers Libraries Resources openalpr}.each do |k|
        FileUtils.ln_s("Versions/Current/#{k}", k)
      end

      return framework_dir
    end

  end
end


