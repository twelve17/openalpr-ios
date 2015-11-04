#!/usr/bin/env ruby

# Tested on Ruby 2.1.2

require 'pry-byebug'
require 'optparse'
require 'logger'
require_relative '../lib/alpr/package'

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

work_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'work'))
dest_root = options.delete(:dest_root)
dest_root ||= File.expand_path(File.join(File.dirname(__FILE__), '..', 'output'))
log_file = File.join(work_dir, 'build.log')

# needed for Logger.new instantiation
if !File.directory?(work_dir)
  FileUtils.mkdir_p(work_dir)
end

puts "options: #{options}"

args = {
  log_file: log_file,
  logger: logger = Logger.new(log_file),
}

build_args = {
  work_dir: work_dir,
  dest_root: dest_root,
  force: options[:rebuild_deps]
}

Alpr::Package::Opencv.new(args).install(build_args)

Alpr::Package::Leptonica.new(args).install(build_args)

Alpr::Package::Tesseract.new(
  args.merge(
    leptonica_headers_dir: File.join(dest_root, 'leptonica.framework/Headers'),
    leptonica_thin_lib_dir: File.join(work_dir, 'leptonica-thin-lib')
  )
).install(build_args)

Alpr::Package::Alpr.new(
  args.merge(
    opencv_framework_dir: File.join(dest_root, 'opencv2.framework'),
    leptonica_framework_dir: File.join(dest_root, 'leptonica.framework'),
    tesseract_framework_dir: File.join(dest_root, 'tesseract.framework'),
  )
).install(build_args)


  info = <<'END'
The script builds openalpr.framework for iOS.
The built framework is universal, but does NOT use bitcode.  It can be
used to build app and run it on either iOS simulator or real device.

Usage:
    ./build_frameworks.rb

Script will create <output> dir, if it's missing, and a few its subdirectories:

    <output>
      opencv2.framework/
          [the framework content]
      leptonica.framework/
          [the framework content]
      tesseract.framework/
          [the framework content]
      openalpr.framework/
          [the framework content]

In addition, the cmake build will create an Xcode project (called 'src')
under <work/openalpr/src/build>.
END

