#!/bin/bash 

WORK_DIR=`pwd`/work
FROM_DIR=`pwd`/openalpr-xcode/openalpr

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

rsync --itemize-changes --exclude=.git  --exclude=.DS_Store $@ $FROM_DIR $OPENALPR_SRC_DIR
