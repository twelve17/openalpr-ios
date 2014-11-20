#!/bin/bash

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
  --exclude=upstart/ \
  --exclude=daemon/ \
  --exclude=misc_utilities/ \
  --exclude=support/windows/ \
  --exclude=tests/ \
  --include='*.h' \
  --include='*.c' \
  --include='*.cpp' \
  --include='*/' \
  --exclude='*' \
  $TARGET_DIR/

# copy headers for consuming xcode project

echo "Copying stub version.h file."

cp etc/version.h $TARGET_DIR/openalpr/

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

#-----------------------------------------------------------------------------
# Unused for now.
#-----------------------------------------------------------------------------
function syncWithLinks() { 
  local dirs=`find . -maxdepth 1 -type d -not -path './daemon' -not -path './cmake_modules' -not -path './build' -not -path './misc_utilities' -not -path './openalpr' -not -path './tests/*'`

  for dir in $dirs; do
    echo "DIR: $file"
    local target_sub_dir="$OPENALPR_SRC_DIR/src/$dir"
    local link_path="$TARGET_DIR/$dir"
    echo "$target_sub_dir -> $link_path"
    ln -s $target_sub_dir $link_path
  done

  local items=`find . -not -path '*.py'  -not -path ./daemon.cpp -not -path './daemon/*' -not -path './cmake_modules/*' -not -path './build/*' -not -path './misc_utilities/*' -not -path './openalpr/support/windows/*' -not -path './tests/*' \( -iname '*.h' -o -iname '*.cpp' -o -iname '*.hpp' -o -iname '*.c' \)`

  for file in $items; do
    echo "FILE: $file"
    local target_file="$OPENALPR_SRC_DIR/src/$file"
    local link_path="$TARGET_DIR/$file"
    local link_dir=`dirname $link_path`
    if [ ! -a "$link_dir" ]; then 
      mkdir -p "$link_dir"
    fi
    echo "$link_path -> $target_file"
    ln -s $target_file $link_path
  done
}
