#!/bin/bash

# Set a fixed value
PLUGIN_DOWNLOAD_PATH="/tmp/upload"
TMP_CHECK_DIR="/tmp/amlogic"
START_LOG="${TMP_CHECK_DIR}/amlogic_check_plugin.log"
LOG_FILE="${TMP_CHECK_DIR}/amlogic.log"
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
[[ -d ${PLUGIN_DOWNLOAD_PATH} ]] || mkdir -p ${PLUGIN_DOWNLOAD_PATH}
[[ -d ${TMP_CHECK_DIR} ]] || mkdir -p ${TMP_CHECK_DIR}

# Log function
tolog() {
    echo -e "${1}" >$START_LOG
    echo -e "${LOGTIME} ${1}" >>$LOG_FILE
    [[ -z "${2}" ]] || exit 1
}

    # 01. Query local version information
    tolog "01. Query current version information."
    CURRENT_PLUGIN_V="$(opkg list-installed | grep 'luci-app-amlogic' | awk '{print $3}')"
    tolog "01.01 current version: ${CURRENT_PLUGIN_V}"
    sleep 3

    # 02. Check the version on the server
    tolog "02. Query server version information."
    SERVER_PLUGIN_VERSION=$(curl -i -s "https://api.github.com/repos/ophub/luci-app-amlogic/releases" | grep "tag_name" | head -n 1 | grep -oE "[0-9]{1,3}.[0-9]{1,3}-[0-9]+")
    [ -n "${SERVER_PLUGIN_VERSION}" ] || tolog "02.01 Failed to get the version on the server." "1"
    tolog "02.02 current version: ${CURRENT_PLUGIN_V}, Latest version: ${SERVER_PLUGIN_VERSION}"
    sleep 3

    if [[ "${CURRENT_PLUGIN_V}" == "${SERVER_PLUGIN_VERSION}" ]]; then
        tolog "02.03 Already the latest version, no need to update." "1"
        sleep 5
        tolog ""
    else
        tolog "02.04 Automatically download the latest plugin."

        SERVER_PLUGIN_URL="https://github.com/ophub/luci-app-amlogic/releases/download"
        SERVER_PLUGIN_FILE_IPK="luci-app-amlogic_${SERVER_PLUGIN_VERSION}_all.ipk.gz"
        SERVER_PLUGIN_FILE_I18N="luci-i18n-amlogic-zh-cn_${SERVER_PLUGIN_VERSION}_all.ipk.gz"
        SERVER_PLUGIN_FILE_LIBFS="luci-lib-fs_1.0-1_all.ipk.gz"

        # Delete other residual ipk files
        rm -f ${TMP_CHECK_DIR}/*.ipk.gz && sync
        rm -f ${TMP_CHECK_DIR}/*.ipk && sync
        rm -f ${PLUGIN_DOWNLOAD_PATH}/*.ipk && sync

        # Download plugin ipk file
        wget -c "${SERVER_PLUGIN_URL}/${SERVER_PLUGIN_VERSION}/${SERVER_PLUGIN_FILE_IPK}" -O "${TMP_CHECK_DIR}/${SERVER_PLUGIN_FILE_IPK}" >/dev/null 2>&1 && sync
        if [[ "$?" -eq "0" && -s "${TMP_CHECK_DIR}/${SERVER_PLUGIN_FILE_IPK}" ]]; then
            tolog "02.05 ${SERVER_PLUGIN_FILE_IPK} complete."
        else
            tolog "02.06 The plugin file failed to download." "1"
        fi
        sleep 3

        # Download plugin i18n file
        wget -c "${SERVER_PLUGIN_URL}/${SERVER_PLUGIN_VERSION}/${SERVER_PLUGIN_FILE_I18N}" -O "${TMP_CHECK_DIR}/${SERVER_PLUGIN_FILE_I18N}" >/dev/null 2>&1 && sync
        if [[ "$?" -eq "0" && -s "${TMP_CHECK_DIR}/${SERVER_PLUGIN_FILE_I18N}" ]]; then
            tolog "02.07 ${SERVER_PLUGIN_FILE_I18N} complete."
        else
            tolog "02.08 The plugin i18n failed to download." "1"
        fi
        sleep 3

        # Download plugin lib-fs file
        wget -c "${SERVER_PLUGIN_URL}/${SERVER_PLUGIN_VERSION}/${SERVER_PLUGIN_FILE_LIBFS}" -O "${TMP_CHECK_DIR}/${SERVER_PLUGIN_FILE_LIBFS}" >/dev/null 2>&1 && sync
        if [[ "$?" -eq "0" && -s "${TMP_CHECK_DIR}/${SERVER_PLUGIN_FILE_LIBFS}" ]]; then
            tolog "02.09 ${SERVER_PLUGIN_FILE_LIBFS} complete."
        else
            tolog "02.10 The plugin i18n failed to download." "1"
        fi
        sleep 3
    fi

    # 03. Move to the ${PLUGIN_DOWNLOAD_PATH} directory to prepare for the update plugin
    gzip -df ${TMP_CHECK_DIR}/*.gz && sync
    mv -f ${TMP_CHECK_DIR}/*.ipk ${PLUGIN_DOWNLOAD_PATH} >/dev/null 2>&1 && sync
    tolog "03. The plug is ready, you can update."
    sleep 3

    #echo '<a href=upload>Update</a>' >$START_LOG
    tolog '<input type="button" class="cbi-button cbi-button-reload" value="Update" onclick="return amlogic_plugin(this)"/>'

    exit 0

