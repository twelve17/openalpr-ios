require_relative 'automake'
require 'find'

module Alpr::Package
  class Tesseract < Automake

    protected

    attr_accessor :leptonica_thin_lib_dir, :leptonica_headers_dir

    def initialize(
      logger:,
      log_file:,
      leptonica_thin_lib_dir:,
      leptonica_headers_dir:
    )
      super(logger: logger, log_file: log_file)
      self.leptonica_thin_lib_dir = leptonica_thin_lib_dir
      self.leptonica_headers_dir = leptonica_headers_dir
    end

    TESSERACT_HEADERS = %w{
      api/apitypes.h api/baseapi.h
      ccmain/pageiterator.h ccmain/mutableiterator.h ccmain/ltrresultiterator.h
      ccmain/resultiterator.h ccmain/thresholder.h ccstruct/publictypes.h
      ccutil/errcode.h ccutil/genericvector.h ccutil/helpers.h
      ccutil/host.h ccutil/ndminx.h ccutil/ocrclass.h
      ccutil/platform.h ccutil/tesscallback.h ccutil/unichar.h
    }

    def archive_name
      "#{self.package_name}.tar.gz"
    end

    def package_name
      "#{self.name}-#{self.package_version}"
    end

    def package_version
      "3.03"
    end

    def archive_url
      'https://drive.google.com/uc?id=0B7l10Bj_LprhSGN2bTYwemVRREU&export=download'
    end

    def get_configure_options
      ["--enable-shared=no"]
    end

    def do_autogen?
      true
    end

    def target_headers
      TESSERACT_HEADERS.map { |x| File.join(self.package_dir, x) }
    end

    def target_libs
      Find.find(self.package_dir).select do |path|
        File.basename(path) =~ /^lib.+\.a$/ #&& !path.include?('arm')
      end
    end

    def target_merged_lib
      'libtesseract_all.a'
    end

    def extra_libs_dir(target, arch)
      File.join(self.leptonica_thin_lib_dir, "#{target}-#{arch}")
    end

    # Attempting to use the tesseract "LIBLEPT_HEADERSDIR"
    # was causing the tesseract build fail, as it was setting the
    # -I flag to $LIBLEPT_HEADERSDIR/leptonica, which is incorrect
    # (the sources reference lept headers relative to $LIBLEPT_HEADERSDIR)
    # It seems that just explicitly including the leptonica headers
    # via the -I flag does the trick.
    def extra_headers_dir
      self.leptonica_headers_dir
    end

  end
end
