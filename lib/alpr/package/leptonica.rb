#==============================================================================
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#==============================================================================

require_relative 'automake'

module Alpr::Package
  class Leptonica < Automake

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
