#!/bin/bash

#if [ $# != 4 ]; then
#    echo "Usage: encode.sh keepFile targetDir targetExt outputDir encodeOpt encodedLogFile"
#    exit 0
#fi

keepfile=${1:-1}
targetdir=${2:-`pwd`}
targetext=${3:-ISO}
outputdir=${4:-`pwd`}
encodedlog=${5:-`pwd`/encoded.log}
mheight=${6:-1280}
mbitrate=${7:-2000}
encodeopt=${8:-"-e nvenc_h264 -r 29.97 --pfr -E faac -B 160 -6 dpl2 -R Auto -D 0.0 -f mp4 --crop 0:0:0:0 --loose-anamorphic -m --decomb -x cabac=0:ref=2:me=umh:bframes=0:weightp=0:subme=6:8x8dct=0:trellis=0 -O --all-audio --all-subtitles"}
destext=${9:-"mp4"}
mtime=${10:-"+0"}

count=1

while read -r file; do

 if [ -f `dirname "${encodedlog}"`"/encode_pause" ]; then
  echo "Encode has been paused. Please delete confdir's encode_pause if it will start"
  exit 0
 fi
 
 if [ -f "${file}" ]; then
  : 
 else
  echo "file not found:${file}"
  continue
 fi

 filedir=`dirname "${file}"`

 if [ -f "${filedir}/encode-in-progress" ]; then
  echo "${filedir} is encoding by other process. next"
  continue
 else
  touch "${filedir}/encode-in-progress"
 fi

 checksum=`md5sum -b "${file}" | cut -d ' ' -f 1`

 `grep -q "${checksum}" ${encodedlog}`
 if [ 0 = $? ]; then
  echo "file has encoded before:${file}"
  rm -f "${filedir}/encode-in-progress"
  continue
 fi
 
 max_titles=`lsdvd -q "${file}" | grep -c "^Title:"`
 title_count=0
 
 file_withoutext=`basename "${file%.*}"`
 
 for titleid in $(seq 1 ${max_titles}); do
 
  destfile=${outputdir}/${file_withoutext}"-"${titleid}"."${destext}
  if [ -s "${destfile}" ]; then
   destfile=${outputdir}/${file_withoutext}"-"${titleid}"-"`date +%Y%m%d%H%M%S`"."${destext}
  fi
  
  echo HandBrakeCLI -i "${file}" -t ${titleid} -b ${mbitrate} -X ${mheight} ${encodeopt} -o "${destfile}"
  HandBrakeCLI -i "${file}" -t ${titleid} -b ${mbitrate} -X ${mheight} ${encodeopt} -o "${destfile}"

  title_count=$((title_count+1))

 done

 if [ ${max_titles} != ${title_count} ]; then
  echo "encode uncompleted. please delete fragment file manually."
  rm -f "${filedir}/encode-in-progress"
  continue
 fi
 
 sync

 checksum_dest=`md5sum -b "${destfile}" | cut -d ' ' -f 1` 
 echo ${checksum}" "${file} >> ${encodedlog}
 echo ${checksum_dest}" "${destfile} >> ${encodedlog}

 echo "encode result"
 echo `ls -l "${file}"`
 echo `ls -l "${destfile}"`

 if [ 0 = ${keepfile} ]; then
  echo "delete original file:${file}"
  rm -f "${file}"
 fi

 if [ ! -s "${destfile}" ]; then
  echo "file is empty. deleted."
  rm -f "${destfile}"
 fi

 count=$((count+1))

 if [ $count -gt 10 ]; then
  rm -f "${filedir}/encode-in-progress"
  exit 0
 fi
 
 rm -f "${filedir}/encode-in-progress"
 
done <<< "$(find ${targetdir} -type f -mtime "$mtime" -regextype posix-egrep -regex "^.*?($targetext)$")"
