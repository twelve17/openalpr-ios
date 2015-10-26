require_relative './alpr/cocoa_pods_build'
require_relative './alpr/manual_deps_build'
require_relative './alpr/xcode'
require_relative './alpr/core_build'

# Dir Strucures:
#
# - $config_dir (etc)
#
# |- $work_dir (work)
# |    |- build.log
# |    |- tesseract-x.y.z.tar.gz
# |    |- tesseract-x.y.z
# |    |- $openalpr_src_dir (optnalpr)
# |    |- $lib_output_dir (lib)
#               |- per_arch_output

# - $dest_root:
#   |- Xcode
#   |    |- Headers
#   |    |- Libraries
#   |    |- Resources
#   |    |- openalpr
#   |- openalpr.framework/
#   |    |- <todo>

module Alpr
end
