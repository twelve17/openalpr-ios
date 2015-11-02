#!/usr/bin/env ruby

# Tested on Ruby 2.1.2

require 'pry-byebug'
require_relative '../lib/alpr/dependency/core'
require_relative '../lib/alpr/dependency/leptonica'
require_relative '../lib/alpr/dependency/tesseract'
require 'optparse'
require 'logger'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  opts.on("-rd", "--[no-]rebuild-deps", "Force rebuild of dependencies") do |rd|
    options[:rebuild_deps] = rd
  end
  opts.on("-d", "--dest-root DR", "Destination root directory") do |d|
    options[:dest_root] = d
  end
end.parse!

work_dir = File.join(File.expand_path(File.dirname(__FILE__)), '..', 'work')
dest_root = options.delete(:dest_root)
dest_root ||= File.join(File.expand_path(File.dirname(__FILE__)), '..', 'output')
#dest_root ||= File.expand_path(File.join(File.dirname(__FILE__), '..', 'output'))
log_file = File.join(work_dir, 'build.log')


puts "options: #{options}"

args = {
  work_dir: work_dir,
  target_dir: dest_root,
  log_file: log_file,
  logger: logger = Logger.new(log_file),
  force: options[:rebuild_deps]
}

Alpr::Package::Leptonica.new.build_framework(args.merge(name: 'leptonica'))

Alpr::Package::Tesseract.new(
  leptonica_headers_dir: File.join(dest_root, 'leptonica.framework/Headers'),
  leptonica_thin_lib_dir: File.join(work_dir, 'leptonica-thin-lib')
).build_framework(args.merge(name: 'tesseract'))

Alpr::Package::Alpr.new(
  leptonica_framework_dir: File.join(dest_root, 'leptonica.framework'),
  tesseract_framework_dir: File.join(dest_root, 'tesseract.framework'),
  opencv_framework_dir: File.join(dest_root, 'opencv2.framework'),
  leptonica_thin_lib_dir: File.join(work_dir, 'leptonica-thin-lib'),
  tesseract_thin_lib_dir: File.join(work_dir, 'tesseract-thin-lib'),
).build_framework(args.merge(name:'openalpr'))


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


