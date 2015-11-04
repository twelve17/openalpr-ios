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
