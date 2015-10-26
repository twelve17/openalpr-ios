#!/usr/bin/env ruby

# Tested on Ruby 2.1.2

require 'pry-byebug'
require_relative '../lib/alpr'
require 'optparse'

#-----------------------------------------------------------------------------
#if ARGV[0].nil?
#  puts "Usage:\n\t./build_framework.py <outputdir>\n"
#  exit(0)
#end


options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  opts.on("-rd", "--[no-]rebuild-deps", "Force rebuild of dependencies") do |rd|
    options[:rebuild_deps] = rd
  end
  opts.on("-m", "--dependency-method DM", "How to build dependencies. Must be :cocoapods or :manual") do |m|
    options[:dep_build_method] = m
  end
  opts.on("-d", "--dest-root DR", "Destination root directory") do |d|
    options[:dest_root] = d
  end
end.parse!

method = options.delete(:dep_build_method)
method ||= 'manual'
dest_root = options.delete(:dest_root)
dest_root ||= File.expand_path(File.join(File.dirname(__FILE__), '..', 'output'))

klass = nil
if method == 'manual'
  klass = Alpr::ManualDepsBuild
elsif method == 'cocoapods'
  klass = Alpr::CocoaPodsBuild
else
  raise "Invalid build method: #{method}"
end

puts "options: #{options}"

klass.new(options).build_framework(dest_root)

  info = <<'END'
The script builds OpenALPR.framework for iOS.
The built framework is universal, it can be used to build app and run it on either iOS simulator or real device.

Usage:
    ./build_framework.py <outputdir>

By cmake conventions (and especially if you work with OpenALPR repository),
the output dir should not be a subdirectory of OpenALPR source tree.

Script will create <outputdir>, if it's missing, and a few its subdirectories:

    <outputdir>
        build/
            iPhoneOS-*/
               [cmake-generated build tree for an iOS device target]
            iPhoneSimulator-*/
               [cmake-generated build tree for iOS simulator]
        openalpr.framework/
            [the framework content]

The script should handle minor OpenALPR updates efficiently
- it does not recompile the library from scratch each time.
However, openalpr.framework directory is erased and recreated on each run.
END


#    dirs_to_exclude = %w{daemon misc_utilities support/windows tests}
#    files_to_exclude = %w{daemon.cpp}
#
#    if false
#      dirs_to_exclude.each do |dir|
#        puts "deleting dir: #{File.join(srcroot, dir)}"
#        FileUtils.rm_rf(File.join(srcroot, dir))
#      end
#
#      files_to_exclude.each do |file|
#        puts "deleting file: #{File.join(srcroot, file)}"
#        FileUtils.rm(File.join(srcroot, file))
#      end
#    end
#
    #for wlib in [builddir + "/modules/world/UninstalledProducts/libopencv_world.a",
    #             builddir + "/lib/Release/libopencv_world.a"]:
    #    if os.path.isfile(wlib):
    #        os.remove(wlib)


