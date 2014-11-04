#!/bin/bash -x

TARGET_DIR=`pwd`/openalpr-xcode/openalpr

if [ -z "$OPENALPR_SRC_DIR" ]; then 
  OPENALPR_SRC_DIR=$1 
fi

shift 

if [ -z "$OPENALPR_SRC_DIR" ]; then 
  echo "You must either set OPENALPR_SRC_DIR or pass it as the first argument to this script."
  exit 1 
fi

if [ ! -d "$OPENALPR_SRC_DIR" ]; then 
  echo "OpenALPR source dir does not exist or is not accessible: $OPENALPR_SRC_DIR"
  exit 1 
fi

if [ ! -d "$TARGET_DIR" ]; then 
  mkdir $TARGET_DIR
fi

rsync -av $@ $OPENALPR_SRC_DIR/src/ \
  --exclude=daemon.cpp \
  --exclude=cmake_modules/  \
  --exclude=build/ \
  --exclude=misc_utilities/ \
  --exclude=tests/ \
  --include='*.h' \
  --include='*.cpp' \
  --include='*/' \
  --exclude='*' \
  $TARGET_DIR/
#  --exclude=tclap/ \
#  --include='openalpr/*' \
#  --exclude=build \
#  --exclude=tests \
#  --exclude=CMakeLists.txt \
#  --exclude=plate_push.py \
