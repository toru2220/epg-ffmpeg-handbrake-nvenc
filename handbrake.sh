#!/bin/bash

ENCODE_OPT=${ENCODE_OPT:-"-e nvenc_h264 -r 29.97 --pfr -E faac -B 160 -6 dpl2 -R Auto -D 0.0 -f mp4 --crop 0:0:0:0 --loose-anamorphic -m --decomb -x cabac=0:ref=2:me=umh:bframes=0:weightp=0:subme=6:8x8dct=0:trellis=0 -O --all-audio --all-subtitles"}
KEEP_FILE=${KEEP_FILE:-"1"}
TARGET_EXT=${TARGET_EXT:-"ISO|iso"}
MAX_HEIGHT=${MAX_HEIGHT:-"720"}
MAX_BITRATE=${MAX_BITRATE:-"3000"}
DEST_EXT=${DEST_EXT:-"mp4"}
MTIME=${MTIME:-"+3"}
TARGET_DIR=${TARGET_DIR:-"/data/dlna"}
OUTPUT_DIR=${OUTPUT_DIR:-"/data/dlna"}

count=1

while read -r file; do

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

  echo "encode result"
  echo `ls -lh "${file}"`
  echo `ls -lh "${destfile}"`
 done

 if [ ${max_titles} != ${title_count} ]; then
  echo "encode uncompleted. please delete fragment file manually."
  exit 0
 fi

 if [ 0 = ${KEEP_FILE} ]; then
  echo "delete original file:${file}"
  rm -f "${file}"
 fi

 if [ ! -s "${destfile}" ]; then
  echo "file is empty. deleted."
  rm -f "${destfile}"
 fi

 count=$((count+1))

 if [ $count -gt 3 ]; then
  echo "encode finished!!!!"
  exit 0
 fi

 continue

done <<< "$(find ${TARGET_DIR} -type f -mtime "$MTIME" -regextype posix-egrep -regex "^.*?($TARGET_EXT)$")"

