#!/bin/bash

#if [ $# != 4 ]; then
#    echo "Usage: encode.sh keepFile targetDir targetExt outputDir encodeOpt encodedLogFile"
#    exit 0
#fi

file=${1:-1}
ENCODE_OPT=${ENCODE_OPT_DEFAULT:-"-e nvenc_h264 -r 29.97 --pfr -E faac -B 160 -6 dpl2 -R Auto -D 0.0 -f mp4 --crop 0:0:0:0 --loose-anamorphic -m --decomb -x cabac=0:ref=2:me=umh:bframes=0:weightp=0:subme=6:8x8dct=0:trellis=0 -O --all-audio --all-subtitles"}
KEEP_FILE=${KEEP_FILE_DEFAULT:-"1"}
TARGET_EXT=${TARGET_EXT_DEFAULT:-"ISO|iso"}
MAX_HEIGHT=${MAX_HEIGHT_DEFAULT:-"1280"}
MAX_BITRATE=${MAX_BITRATE_DEFAULT:-"2000"}
DEST_EXT=${DEST_EXT_DEFAULT:-"mp4"}
MTIME=${MTIME_DEFAULT:-"+3"}
TARGET_DIR=${TARGET_DIR_DEFAULT:-"/data/dlna"}
OUTPUT_DIR=${OUTPUT_DIR_DEFAULT:-"/data/dlna"}

 if [ -f "${file}" ]; then
  : 
 else
  echo "file not found:${file}"
  continue
 fi

 filedir=`dirname "${file}"`
 checksum=`md5sum -b "${file}" | cut -d ' ' -f 1`

 max_titles=`lsdvd -q "${file}" | grep -c "^Title:"`
 title_count=0
 
 file_withoutext=`basename "${file%.*}"`
 
 for titleid in $(seq 1 ${max_titles}); do
 
  destfile=${OUTPUT_DIR}/${file_withoutext}"-"${titleid}"."${DEST_EXT}
  if [ -s "${destfile}" ]; then
   destfile=${OUTPUT_DIR}/${file_withoutext}"-"${titleid}"-"`date +%Y%m%d%H%M%S`"."${DEST_EXT}
  fi
  
  echo HandBrakeCLI -i "${file}" -t ${titleid} -b ${MAX_BITRATE} -X ${MAX_HEIGHT} ${ENCODE_OPT} -o "${destfile}"
  HandBrakeCLI -i "${file}" -t ${titleid} -b ${MAX_BITRATE} -X ${MAX_HEIGHT} ${ENCODE_OPT} -o "${destfile}"

  title_count=$((title_count+1))

 done

 if [ ${max_titles} != ${title_count} ]; then
  echo "encode uncompleted. please delete fragment file manually."
  exit 0
 fi
 
 echo "encode result"
 echo `ls -l "${file}"`
 echo `ls -l "${destfile}"`

 if [ 0 = ${KEEP_FILE} ]; then
  echo "delete original file:${file}"
  rm -f "${file}"
 fi

 if [ ! -s "${destfile}" ]; then
  echo "file is empty. deleted."
  rm -f "${destfile}"
 fi
