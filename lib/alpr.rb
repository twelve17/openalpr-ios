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

require_relative 'alpr/constants'
require_relative 'alpr/package'
require_relative 'alpr/utils'
require_relative 'alpr/xcode'

# Dir Strucures:
#
# - $config_dir (etc)
#
# |- $work_dir (work)
# |    |- build.log
# |    |- tesseract-x.y.z.tar.gz
# |    |- tesseract-x.y.z
# |    |- $openalpr_src_dir (openalpr)
# |    |- $lib_output_dir (leptonica-thin-lib, ...)
#               |- per_arch_output

# - $dest_root:
#   |- src.xcodeproj
#   |- opencv2.framework
#   |- leptonica.framework
#   |- openalpr.framework
#   |- tesseract.framework

module Alpr
end
