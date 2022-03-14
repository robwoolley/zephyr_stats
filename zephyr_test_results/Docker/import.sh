#!/bin/bash

RESULTS_REPO_PATH="${RESULTS_REPO_PATH:-/data/test_results}"
RESULTS_REPO_URL="${RESULTS_REPO_URL:-https://github.com/zephyrproject-rtos/test_results}"

ZEPHYR_REPO_PATH="${ZEPHYR_REPO_PATH:-/data/zephyr}"
ZEPHYR_REPO_URL="${ZEPHYR_REPO_URL:-https://github.com/zephyrproject-rtos/zephyr.git}"

RESULTS_DIR="${RESULTS_REPO_PATH}/results"
INFLUX_DB="${INFLUX_DB:-influxdb://${INFLUXDB_SERVICE_HOST}:${INFLUXDB_SERVICE_PORT}/zephyr_test_results}"

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

updateGitRepo "test_results repo" "${RESULTS_REPO_PATH}" "${RESULTS_REPO_URL}"
if [ $? -ne 0 ]; then
    exit 1
fi

for f in $(ls -1 ${RESULTS_DIR}); do
    for ff in $(ls -1 ${RESULTS_DIR}/${f}); do
        platform=$(basename ${ff} .xml)
        echo "${f} (${platform})"
        d=$(git -C ${ZEPHYR_REPO_PATH} log --format=%ct --date=local ${f}^..${f})
        ./check.py -d ${INFLUX_DB} -p ${platform} -c ${f}
		if [ "$?" == "1" ]; then
			echo "Importing ${platform}"
            junit2influx ${RESULTS_DIR}/${f}/${ff} --timestamp "${d}" --tag platform=${platform} --tag version=${f} --influxdb-url ${INFLUX_DB}
		else
			echo "Not importing existing platform"
		fi
        echo ${d}
        sleep 2
    done
done