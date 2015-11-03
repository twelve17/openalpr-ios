require_relative 'base'
require_relative '../constants'
require_relative '../utils'

require 'find'

module Alpr::Package
  class Automake < Base
    include ::Alpr::Constants
    include ::Alpr::Utils
    extend ::Alpr::Utils

    protected

    XCODE_DEVELOPER = "/Applications/Xcode.app/Contents/Developer"
    XCODETOOLCHAIN = "#{XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain"

    SDK_IPHONEOS = qexec("xcrun --sdk iphoneos --show-sdk-path")
    SDK_IPHONESIMULATOR = qexec("xcrun --sdk iphonesimulator --show-sdk-path")

    CXX = xcfind("c++")
    CC = xcfind("cc")
    LD = xcfind("ld")
    AS = xcfind("as")
    NM = xcfind("nm")
    RANLIB = xcfind("ranlib")

    def build_arch(target, arch)

      puts "Building #{name} for #{arch} from #{self.package_dir}"
      FileUtils.chdir(self.package_dir)

      cleanup_source

      # TODO: obey 'force'
      FileUtils.rm_rf(self.thin_lib_dir(target, arch))
      FileUtils.mkdir_p(self.thin_lib_dir(target, arch))

      do_autoconf_build(
        target: target,
        arch: arch,
        headers_dir: self.extra_headers_dir,
        libs_dir: self.extra_libs_dir(target, arch),
        build_args: self.get_configure_options,
        do_autogen: self.do_autogen?,
      )

      if self.target_merged_lib.nil?
        FileUtils.cp(self.target_libs, self.thin_lib_dir(target, arch))
      else
        self.merge_libfiles(self.target_libs, self.thin_lib_dir(target, arch), self.target_merged_lib)
      end
    end

    private
    #-----------------------------------------------------------------------------
    def env_for_arch(target, arch, headers_dir, lib_dir)

      sdk_root = arch.start_with?('arm') ? SDK_IPHONEOS : SDK_IPHONESIMULATOR
      if !File.exists?(sdk_root)
        raise "SDKROOT does not exist: #{sdk_root}"
      end

      cflags = [
        "-arch #{arch}",
        "-pipe",
        "-no-cpp-precomp",
        "-isysroot #{sdk_root}",
        "-miphoneos-version-min=#{IOS_DEPLOY_TGT}",
      ]
      if arch.start_with?('arm')
        cflags << "-I#{sdk_root}/usr/include/"
      end
      if headers_dir
        cflags << "-I#{headers_dir}"
      end
      cflags = cflags.join(' ')

      ldflags = [
        "-L#{sdk_root}/usr/lib/"
      ]
      if lib_dir
        ldflags << "-L#{lib_dir}"
      end
      ldflags = ldflags.join(' ')

      env = {
        'SDKROOT' => sdk_root,
        'CXX' => CXX,
        'CC' => CC,
        'LD' => LD,
        'AS' => AS,
        'AR' => AR,
        'NM' => NM,
        'RANLIB' => RANLIB,
        'LDFLAGS' => ldflags,
        'CFLAGS' => cflags,
        'CPPFLAGS' => cflags,
        'CXXFLAGS' => cflags,
        'PATH' => "#{XCODETOOLCHAIN}/usr/bin:#{ENV['PATH']}",
      }

      # TODO: do we need this?  clang complains about it
      if arch.start_with?('arm')
        env['BUILD_HOST_NAME'] = arch.sub(/^armv?(.+)/, 'arm-apple-darwin\1')
      end

      env
    end
    #-----------------------------------------------------------------------------
    def cleanup_source
      binding.pry
      %w{clean distclean}.each { |t| log_execute("make #{t} || echo \"Nothing to #{t}\"") }
    end

    #-----------------------------------------------------------------------------
    def do_autoconf_build(target:, arch:, build_args:, headers_dir:, libs_dir:, do_autogen:false)

      build_env = env_for_arch(target, arch, headers_dir, libs_dir)

      if do_autogen?
        log_execute('bash autogen.sh 2>&1', build_env)
      end

      if build_env['BUILD_HOST_NAME']
        build_args.unshift("--host=#{build_env['BUILD_HOST_NAME']}")
      end
      log_execute("./configure #{build_args.join(' ')} && make -j12 2>&1", build_env)
    end

  end
end

