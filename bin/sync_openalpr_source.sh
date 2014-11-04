#!/bin/bash -x


WORK_DIR=`pwd`/work
GLOBAL_OUTDIR="$WORK_DIR/dependencies"
INCLUDE_DIR=$GLOBAL_OUTDIR/include/openalpr
SHARE_DIR=$GLOBAL_OUTDIR/share/openalpr

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

# copy sources for openalpr xcode project
rsync -av $@ $OPENALPR_SRC_DIR/src/ \
  --exclude=daemon.cpp \
  --exclude=cmake_modules/  \
  --exclude=build/ \
  --exclude=misc_utilities/ \
  --exclude=tests/ \
  --include='*.h' \
  --include='*.c' \
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

# copy headers for consuming xcode project

echo "Copying headers to $INCLUDE_DIR"

mkdir $INCLUDE_DIR

rsync -av $@ $OPENALPR_SRC_DIR/src/ \
  --exclude=cmake_modules/  \
  --exclude=build/ \
  --exclude=misc_utilities/ \
  --exclude=tests/ \
  --include='*.h' \
  --include='*/' \
  --exclude='*' \
  $INCLUDE_DIR/

echo "Copying runtime data to $SHARE_DIR"

mkdir -p $SHARE_DIR

rsync -av $@ $OPENALPR_SRC_DIR/runtime_data \
  $SHARE_DIR
