#!/usr/bin/env sh

file_name="${1}"
last_line=$(wc -l < "${file_name}")
current_line=0

echo "{"
while read -r line
do
  current_line=$(($current_line + 1))
  if [ "${current_line}" -ne "${last_line}" ]; then
  [ -z "$line" ] && continue
    echo "${line}" | awk -F '=' '{ print " \""$1"\" : \""$2"\","}' | grep -iv '\"#'
  else
    echo "${line}" | awk -F '=' '{ print " \""$1"\" : \""$2"\""}' | grep -iv '\"#'
  fi
done < "${file_name}"
echo "}"
