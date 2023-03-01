#!/bin/bash

file=${1:-1}
ENCODE_OPT=${ENCODE_OPT_DEFAULT:-"-c:v h264_nvenc -movflags +faststart -map_metadata 0 -profile:v high -level:v 4.0 -b_strategy 2 -bf 2 -flags cgop -coder ac -pix_fmt yuv420p -crf 32 -bufsize 16M -c:a mp3 -ac 1 -ar 22050 -b:a 96k"}
KEEP_FILE=${KEEP_FILE_DEFAULT:-"1"}
TARGET_EXT=${TARGET_EXT_DEFAULT:-"mp4|avi|AVI|flv|FLV|mpg|MPG|mpd|MPD"}
MAX_HEIGHT=${MAX_HEIGHT_DEFAULT:-"720"}
MAX_BITRATE=${MAX_BITRATE_DEFAULT:-"1200000"}
DEST_EXT=${DEST_EXT_DEFAULT:-"mp4"}
MTIME=${MTIME_DEFAULT:-"+3"}
TARGET_DIR=${TARGET_DIR_DEFAULT:-"/data/mov"}
OUTPUT_DIR=${OUTPUT_DIR_DEFAULT:-"/data/mp4"}

if [ -f "${file}" ]; then
    :
else
    echo "file not found:${file}"
    exit 0
fi

filedir=`dirname "${file}"`
checksum=`md5sum -b "${file}" | cut -d ' ' -f 1`
file_withoutext=`basename "${file%.*}"`

destfile=${OUTPUT_DIR}/${file_withoutext}"."${DEST_EXT}
if [ -s "${destfile}" ]; then
    destfile=${OUTPUT_DIR}/${file_withoutext}"-"`date +%Y%m%d%H%M%S`"."${DEST_EXT}
fi

bitrate=`ffprobe -show_entries format=bit_rate -v quiet -of csv="p=0" -i "${file}"`
height_all=`ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=nw=1:nk=1 -i "${file}"`
height=(${height_all// / })

maxheight=`test ${height} -gt ${MAX_HEIGHT} && echo ${MAX_HEIGHT} || echo ${height}`
maxbitrate=`test ${bitrate} -gt ${MAX_BITRATE} && echo ${MAX_BITRATE} || echo ${bitrate}`

echo ${file}
echo ${height} to ${maxheight}
echo ${bitrate} to ${maxbitrate}
echo ffmpeg -i "${file}" "${ENCODE_OPT}" -maxrate ${maxbitrate} -vf scale=-1:${maxheight} "${destfile}"

#  ffmpeg -i "${file}" ${ENCODE_OPT} -maxrate ${maxbitrate} -vf scale=-1:${maxheight} "${destfile}"

#  duration_base=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${file}"`
#  duration_dest=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${destfile}"`

#  duration_base_sec=(${duration_base//./ })
#  duration_dest_sec=(${duration_dest//./ })

#  if [ "${duration_base_sec}" != "${duration_dest_sec}" ]; then
#   echo "encode uncompleted. delete fragment file:${destfile}"
#   rm -f "${destfile}"
#   continue
#  fi

#  echo "encode result"
#  echo `ls -l "${file}"`
#  echo `ls -l "${destfile}"`

#  if [ 0 = ${KEEP_FILE} ]; then
#   echo "delete original file:${file}"
#   rm "${file}"
#  fi

#  if [ ! -s "${destfile}" ]; then
#   echo "file is empty. deleted."
#   rm -f "${destfile}"
#  fi

