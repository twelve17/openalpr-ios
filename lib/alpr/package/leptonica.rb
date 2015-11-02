require_relative 'automake'

module Alpr::Package
  class Leptonica < Alpr::Package::Automake

    protected

    def archive_name
      "#{self.package_name}.tar.gz"
    end

    def package_name
      "#{self.name}-#{self.package_version}"
    end

    def package_version
      "1.71"
    end

    def archive_url
      "http://www.leptonica.org/source/#{self.archive_name}"
    end

    def get_configure_options
      %w{--enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib --without-libtiff}
    end

    def do_autogen?
      false
    end

    def target_headers
      Dir["#{self.package_dir}/src/*.h"]
    end

    def target_libs
      Dir["#{self.package_dir}/src/.libs/lib*.a"]
    end

  end
end
