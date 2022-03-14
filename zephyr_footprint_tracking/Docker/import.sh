#!/bin/bash

FOOTPRINT_REPO_PATH="${FOOTPRINT_REPO_PATH:-/data/footprint_data}"
FOOTPRINT_REPO_URL="${FOOTPRINT_REPO_URL:-https://github.com/robwoolley/footprint_tracking}"

ZEPHYR_REPO_PATH="${ZEPHYR_REPO_PATH:-/data/zephyr}"
ZEPHYR_REPO_URL="${ZEPHYR_REPO_URL:-https://github.com/zephyrproject-rtos/zephyr.git}"

FOOTPRINT_DIR="${FOOTPRINT_REPO_PATH}/footprint_data"
INFLUX_DB="${INFLUX_DB:-influxdb://${INFLUXDB_SERVICE_HOST}:${INFLUXDB_SERVICE_PORT}/footprint_tracking}"

function checkGitRepo() {
    local REPO_NAME="$1"
    local REPO_PATH="$2"
    local REPO_URL="$3"

    # Check if the repository directory exists
    if [ ! -d "${2}" ]; then
        echo "WARN: ${1} (${2}) could not be found." >&2
        return 1
    fi

    if [ ! -d "${2}/.git" ]; then
        echo "WARN: ${1} (${2}/.git) could not be found." >&2
        return 2
    fi

    GIT_ORIGIN_URL=$(git -C ${2} config --get remote.origin.url)
    if [ "${3}" != ${GIT_ORIGIN_URL} ]; then
        echo "WARN: ${1} git repo origin URL does not match." >&2
        return 3
    fi

    return 0
}

function updateGitRepo() {
    local REPO_NAME="$1"
    local REPO_PATH="$2"
    local REPO_URL="$3"

    checkGitRepo "${REPO_NAME}" "${REPO_PATH}" "${REPO_URL}"
    if [ $? -eq 0 ]; then
        git -C "${REPO_PATH}" pull --rebase
    else
        git clone "${REPO_URL}" "${REPO_PATH}"
        if [ $? -ne 0 ]; then
            echo "ERROR: Could not could clone ${REPO_URL}" >&2
            return 1
        fi
    fi
    return 0
}

updateGitRepo "zephyr repo" "${ZEPHYR_REPO_PATH}" "${ZEPHYR_REPO_URL}"
if [ $? -ne 0 ]; then
    exit 1
fi

updateGitRepo "footprint_tracking repo" "${FOOTPRINT_REPO_PATH}" "${FOOTPRINT_REPO_URL}"
if [ $? -ne 0 ]; then
    exit 1
fi

if [ -x /app/upload_data.py ]; then
    echo /app/upload_data.py \
        --zephyr-base ${ZEPHYR_REPO_PATH} \
        --data ${FOOTPRINT_DIR} \
        --database-url ${INFLUX_DB}

    /app/upload_data.py \
        --zephyr-base ${ZEPHYR_REPO_PATH} \
        --data ${FOOTPRINT_DIR} \
        --database-url ${INFLUX_DB}
else
    echo "ERROR: ${ZEPHYR_REPO_PATH}/scripts/footprint/upload_data.py not found"
    exit 1
fi