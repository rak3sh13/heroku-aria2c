#!/bin/bash

# 限制最低上传大小，仅 BT 多文件下载时有效，用于过滤无用文件。低于此大小的文件将被删除，不会上传。
MIN_SIZE=10m
# 排除文件类型，仅 BT 多文件下载时有效，用于过滤无用文件。排除的文件将被删除，不会上传。
EXCLUDE_FILE='html,url,lnk,txt,jpg,png,htm'
# RCLONE 异常退出重试次数
RETRY_NUM=3
#============================================================
filePath=$3                                   # Aria2传递给脚本的文件路径。BT下载有多个文件时该值为文件夹内第一个文件，如/root/Download/a/b/1.mp4
RELATIVE_PATH=${filePath#./downloads/}   # 路径转换，去掉开头的下载路径。
TOP_PATH=./downloads/${RELATIVE_PATH%%/*} # 路径转换，BT下载文件夹时为顶层文件夹路径，普通单文件下载时与文件路径相同。
RED_FONT_PREFIX="\033[31m"
LIGHT_GREEN_FONT_PREFIX="\033[1;32m"
YELLOW_FONT_PREFIX="\033[1;33m"
LIGHT_PURPLE_FONT_PREFIX="\033[1;35m"
FONT_COLOR_SUFFIX="\033[0m"
INFO="[${LIGHT_GREEN_FONT_PREFIX}INFO${FONT_COLOR_SUFFIX}]"
ERROR="[${RED_FONT_PREFIX}ERROR${FONT_COLOR_SUFFIX}]"
WARRING="[${YELLOW_FONT_PREFIX}WARRING${FONT_COLOR_SUFFIX}]"

TASK_INFO() {
    echo -e "
-------------------------- [${YELLOW_FONT_PREFIX}TASK INFO${FONT_COLOR_SUFFIX}] --------------------------
${LIGHT_PURPLE_FONT_PREFIX}Download path:${FONT_COLOR_SUFFIX} ./downloads
${LIGHT_PURPLE_FONT_PREFIX}File path:${FONT_COLOR_SUFFIX} ${filePath}
${LIGHT_PURPLE_FONT_PREFIX}Upload path:${FONT_COLOR_SUFFIX} ${UPLOAD_PATH}
${LIGHT_PURPLE_FONT_PREFIX}Remote path:${FONT_COLOR_SUFFIX} ${REMOTE_PATH}
-------------------------- [${YELLOW_FONT_PREFIX}TASK INFO${FONT_COLOR_SUFFIX}] --------------------------
"
}

CLEAN_UP() {
    [[ -n ${MIN_SIZE} || -n ${INCLUDE_FILE} || -n ${EXCLUDE_FILE} ]] && echo -e "${INFO} Clean up excluded files ..."
    [[ -n ${MIN_SIZE} ]] && rclone delete -v --config="rclone.conf" "${UPLOAD_PATH}" --max-size ${MIN_SIZE}
    [[ -n ${INCLUDE_FILE} ]] && rclone delete -v --config="rclone.conf" "${UPLOAD_PATH}" --exclude "*.{${INCLUDE_FILE}}"
    [[ -n ${EXCLUDE_FILE} ]] && rclone delete -v --config="rclone.conf" "${UPLOAD_PATH}" --include "*.{${EXCLUDE_FILE}}"
}



UPLOAD() {
    echo -e "$(date +"%m/%d %H:%M:%S") ${INFO} Start upload..."
    TASK_INFO
    rclone copy -v --config="rclone.conf" "${UPLOAD_PATH}" "${REMOTE_PATH}"
}

if [ -e "${filePath}.aria2" ]; then
    DOT_ARIA2_FILE="${filePath}.aria2"
elif [ -e "${TOP_PATH}.aria2" ]; then
    DOT_ARIA2_FILE="${TOP_PATH}.aria2"
fi

if [ "${TOP_PATH}" = "${filePath}" ] && [ $2 -eq 1 ]; then # 普通单文件下载，移动文件到设定的网盘文件夹。
    UPLOAD_PATH="${filePath}"
    REMOTE_PATH="DRIVE:$RCLONE_DESTINATION"
    UPLOAD
    exit 0
elif [ "${TOP_PATH}" != "${filePath}" ] && [ $2 -gt 1 ]; then # BT下载（文件夹内文件数大于1），移动整个文件夹到设定的网盘文件夹。
    UPLOAD_PATH="${TOP_PATH}"
    REMOTE_PATH="DRIVE:$RCLONE_DESTINATION/${RELATIVE_PATH%%/*}"
    CLEAN_UP
    UPLOAD
    exit 0
fi

echo -e "${ERROR} Unknown error."
TASK_INFO
